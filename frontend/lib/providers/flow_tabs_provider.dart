import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workflow_document.dart';
import '../services/project_api.dart';
import '../services/subflows_api.dart';
import '../utils/workflow_to_yaml.dart';
import '../utils/yaml_to_workflow.dart';
import 'api_provider.dart';
import 'canvas_controller.dart';
import 'mode_provider.dart';
import 'mock_data.dart' show WorkflowSummary;
import 'project_provider.dart';
import 'selection_notifier.dart';
import 'subflows_provider.dart';

/// One TopBar tab: a project flow or a project subflow (distinct icon/color,
/// session-local order — the backend `flow_order` covers flows only).
enum FlowTabKind { flow, subflow }

class FlowTab {
  final FlowTabKind kind;
  final String name;

  const FlowTab(this.kind, this.name);

  /// Documents-cache key: subflows get an `sf_` prefix so a subflow never
  /// collides with a same-named flow's `wf_` id.
  String get docId {
    final sanitized =
        name.replaceAll(RegExp(r'[^a-z0-9_-]'), '_').toLowerCase();
    return kind == FlowTabKind.flow ? 'wf_$sanitized' : 'sf_$sanitized';
  }

  @override
  bool operator ==(Object other) =>
      other is FlowTab && other.kind == kind && other.name == name;

  @override
  int get hashCode => Object.hash(kind, name);
}

/// Ordered tab list. Flow tabs reconcile against the remote workflow list;
/// subflow tabs are opened explicitly (+ menu / subflow node drawer).
final flowTabsProvider = StateProvider<List<FlowTab>>((ref) => const []);

/// Kind of the tab the canvas is currently bound to. Drives autosave
/// routing (workflows vs subflows CRUD) and launch-button visibility.
final activeTabKindProvider =
    StateProvider<FlowTabKind>((ref) => FlowTabKind.flow);

/// `untitled` / `untitled-N` name generation, checked against [existing].
String untitledName(Iterable<String> existing) {
  final taken = existing.map((e) => e.toLowerCase()).toSet();
  var name = 'untitled';
  var i = 2;
  while (taken.contains(name)) {
    name = 'untitled-$i';
    i++;
  }
  return name;
}

/// Flow names in tab order (subflow tabs excluded) — the payload shape of
/// `PUT /api/v1/project/flow-order`.
List<String> flowOrderNames(List<FlowTab> tabs) => [
      for (final t in tabs)
        if (t.kind == FlowTabKind.flow) t.name,
    ];

/// Persist the flow-tab order (flow names only) to trailhead.yaml.
void persistFlowOrder(WidgetRef ref, List<FlowTab> tabs) {
  ref.read(projectApiProvider).putFlowOrder(flowOrderNames(tabs)).then((_) {
    ref.invalidate(projectInfoProvider);
  }).catchError((Object e) {
    debugPrint('flow-order persist failed: $e');
  });
}

final _emptySentinel =
    WorkflowSummary(id: emptyWorkflowId, name: '', version: 0, updated: '');

/// Last-seen backend `content_hash` per flow name — the rename detector's
/// memory. A vanished tab name only binds to an appeared flow when the hashes
/// match (byte-identical file move); an unrelated delete+create inside one
/// poll window falls through to remove+append instead of corrupting the
/// local binding.
final _flowContentHashesProvider =
    StateProvider<Map<String, String?>>((ref) => const {});

/// Reconciles flow tabs with the remote workflow list and the persisted
/// `flow_order`. Watched once from the build-mode top bar.
///
/// - Initial order: `flow_order` names first, unordered flows appended in
///   server-list order (stable).
/// - Flows added remotely (or just created via the strip) are appended.
/// - Flows removed remotely drop their tab; subflow tabs confirmed gone from
///   the server list drop theirs too (unparsable subflows keep their tab).
/// - A 1-removed-1-added set change at equal count is treated as a rename
///   only when the vanished and appeared entries share a content hash:
///   the tab keeps its position, the active doc and viewport cache follow.
final flowTabSyncProvider = FutureProvider<void>((ref) async {
  final flows = await ref.watch(remoteWorkflowsProvider.future);
  final dtos = await ref.watch(remoteWorkflowDtosProvider.future);
  final project = await ref
      .watch(projectInfoProvider.future)
      .then<ProjectInfo?>((p) => p, onError: (_) => null);
  final subflowNames = ref.watch(subflowsProvider).maybeWhen(
        data: (list) => list.map((s) => s.name).toSet(),
        orElse: () => null,
      );

  final previousHashes = ref.read(_flowContentHashesProvider);
  final currentHashes = {for (final d in dtos) d.name: d.contentHash};
  ref.read(_flowContentHashesProvider.notifier).state = currentHashes;

  final tabs = ref.read(flowTabsProvider);
  final flowNames = flows.map((w) => w.name).toSet();
  final tabFlowNames = [
    for (final t in tabs)
      if (t.kind == FlowTabKind.flow) t.name,
  ];

  var next = List<FlowTab>.from(tabs);
  final renamedFromTo = <String, String>{};

  // Rename detection: exactly one vanished + one appeared, count unchanged,
  // and the vanished entry's last-seen hash matches the appeared entry's
  // hash (an external `mv old.yaml new.yaml` preserves bytes; a teammate's
  // delete+create does not).
  final vanished = tabFlowNames.where((n) => !flowNames.contains(n)).toList();
  final appeared = flowNames.where((n) => !tabFlowNames.contains(n)).toList();
  var isRename = false;
  if (vanished.length == 1 &&
      appeared.length == 1 &&
      tabFlowNames.length == flowNames.length) {
    final oldHash = previousHashes[vanished.first];
    final newHash = currentHashes[appeared.first];
    isRename = oldHash != null && newHash != null && oldHash == newHash;
  }
  if (isRename) {
    final oldName = vanished.first;
    final newName = appeared.first;
    renamedFromTo[oldName] = newName;
    final idx = next.indexOf(FlowTab(FlowTabKind.flow, oldName));
    next[idx] = FlowTab(FlowTabKind.flow, newName);
  } else {
    next.removeWhere(
        (t) => t.kind == FlowTabKind.flow && !flowNames.contains(t.name));
    // Candidates: flow_order names first (existing only), then the rest in
    // server order. Names already tabbed keep their position — only genuinely
    // new flows append at the end.
    final present = {
      for (final t in next)
        if (t.kind == FlowTabKind.flow) t.name,
    };
    final candidates = <String>[
      ...?project?.flowOrder.where(flowNames.contains),
      ...flowNames,
    ];
    for (final name in candidates) {
      if (present.add(name)) {
        next.add(FlowTab(FlowTabKind.flow, name));
      }
    }
  }

  // Subflow reconcile: drop tabs confirmed gone from the server list. Runs
  // in both branches and only when the list loaded — a transient fetch error
  // must never nuke tabs, and an unparsable subflow keeps its tab (the
  // switch path binds an incompatible placeholder instead).
  if (subflowNames != null) {
    next.removeWhere((t) =>
        t.kind == FlowTabKind.subflow && !subflowNames.contains(t.name));
  }

  // Persist a rename-swap so the stale old name never lingers in
  // trailhead.yaml (the flow-order endpoint rejects unknown names).
  if (renamedFromTo.isNotEmpty) {
    ref
        .read(projectApiProvider)
        .putFlowOrder(flowOrderNames(next))
        .then((_) => ref.invalidate(projectInfoProvider))
        .catchError((Object e) {
      debugPrint('flow-order persist failed: $e');
    });
  }

  final changed = next.length != tabs.length ||
      !next.asMap().entries.every((e) => tabs[e.key] == e.value);
  if (changed) {
    ref.read(flowTabsProvider.notifier).state = next;
  }

  // Follow a rename with the active document + viewport cache.
  if (renamedFromTo.isNotEmpty) {
    final oldName = renamedFromTo.keys.first;
    final newName = renamedFromTo.values.first;
    final kind = ref.read(activeTabKindProvider);
    final current = ref.read(workflowProvider);
    if (kind == FlowTabKind.flow && current.name == oldName) {
      final updated = flows.firstWhere((w) => w.name == newName,
          orElse: () => current.copyWith(
              name: newName, id: FlowTab(FlowTabKind.flow, newName).docId));
      ref.read(workflowProvider.notifier).state = updated;
    }
    final oldDoc = FlowTab(FlowTabKind.flow, oldName).docId;
    final newDoc = FlowTab(FlowTabKind.flow, newName).docId;
    ref.read(documentsProvider.notifier).update((docs) {
      if (!docs.containsKey(oldDoc)) return docs;
      final m = Map<String, WorkflowDocument>.from(docs);
      m[newDoc] = m.remove(oldDoc)!;
      return m;
    });
  }

  // Selection repair: nothing selected (startup) or the active flow tab is
  // gone → bind the first remaining tab; no tabs → empty sentinel.
  final currentKind = ref.read(activeTabKindProvider);
  final currentWf = ref.read(workflowProvider);
  final selectionValid = currentWf.id != emptyWorkflowId &&
      next.any((t) => t.kind == currentKind && t.name == currentWf.name);
  if (!selectionValid) {
    // Reset first so the switch below never flushes a stale (deleted)
    // document back to the backend.
    if (currentWf.id != emptyWorkflowId) {
      ref.read(workflowProvider.notifier).state = _emptySentinel;
    }
    if (next.isNotEmpty) {
      final error = await _switchCore(ref.read, next.first);
      if (error != null) debugPrint('tab selection repair: $error');
    } else {
      ref.read(activeTabKindProvider.notifier).state = FlowTabKind.flow;
    }
  }
});

/// Switch the canvas to [tab]: flush+cache the current document, restore the
/// target's cached viewport, clear canvas interaction state. Mirrors the
/// switching rules the old workflow dropdown applied.
///
/// Surfaces a snackbar when the switch dead-ends (subflow fetch failure,
/// subflow confirmed deleted server-side, flow missing from the list).
Future<void> switchToTab(WidgetRef ref, FlowTab tab) async {
  final error = await _switchCore(ref.read, tab);
  if (error != null) {
    debugPrint(error);
    final context = ref.context;
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

/// Returns null on success, or an error message when the switch dead-ended.
Future<String?> _switchCore(
  T Function<T>(ProviderListenable<T>) read,
  FlowTab tab,
) async {
  final currentKind = read(activeTabKindProvider);
  final currentWf = read(workflowProvider);
  final alreadyThere = currentKind == tab.kind && currentWf.name == tab.name;
  if (alreadyThere && currentWf.id != emptyWorkflowId) return null;

  // Flush + cache the outgoing document.
  if (currentWf.id != emptyWorkflowId && currentWf.parseError == null) {
    final currentVp = read(canvasControllerProvider);
    read(documentsProvider.notifier).update((docs) {
      final m = Map<String, WorkflowDocument>.from(docs);
      m[currentWf.id] =
          WorkflowDocument(workflow: currentWf, viewport: currentVp);
      return m;
    });
    final yaml = workflowToYaml(currentWf);
    if (currentKind == FlowTabKind.subflow) {
      read(subflowsApiProvider).replace(currentWf.name, yaml);
    } else {
      read(workflowsApiProvider).replace(currentWf.name, yaml);
    }
  }

  // Resolve the target document: viewport cache first, then parse.
  final doc = read(documentsProvider)[tab.docId];
  WorkflowSummary? target = doc?.workflow;
  if (target == null) {
    if (tab.kind == FlowTabKind.flow) {
      target = read(workflowsProvider)
          .cast<WorkflowSummary?>()
          .firstWhere((w) => w!.name == tab.name, orElse: () => null);
      if (target == null) return 'flow "${tab.name}" is not available';
    } else {
      final SubflowDto? match;
      try {
        final subflows = await read(subflowsProvider.future);
        match = subflows
            .cast<SubflowDto?>()
            .firstWhere((s) => s!.name == tab.name, orElse: () => null);
      } catch (e) {
        return 'failed to load subflow "${tab.name}": $e';
      }
      if (match == null) {
        // Confirmed gone from the server list — drop the stale tab (and its
        // viewport cache) so the strip stops dead-ending on it.
        read(flowTabsProvider.notifier).update(
          (tabs) => tabs.where((t) => t != tab).toList(),
        );
        read(documentsProvider.notifier).update((docs) {
          if (!docs.containsKey(tab.docId)) return docs;
          final m = Map<String, WorkflowDocument>.from(docs)
            ..remove(tab.docId);
          return m;
        });
        return 'subflow "${tab.name}" no longer exists';
      }
      try {
        target =
            yamlToWorkflow(match.name, match.content).copyWith(id: tab.docId);
      } catch (e) {
        // Same incompatible-summary path flows use: bind a parseError
        // placeholder (delete-only, never flushed back — the flush above and
        // the autosave listener both skip parseError docs). Tab stays open.
        target = WorkflowSummary.incompatible(
          name: match.name,
          parseError: e.toString(),
          remoteContent: match.content,
        ).copyWith(id: tab.docId);
      }
    }
  }

  read(activeTabKindProvider.notifier).state = tab.kind;
  read(workflowProvider.notifier).state = target;
  if (doc != null) {
    read(canvasControllerProvider.notifier).setViewport(doc.viewport);
  }
  read(selectionProvider.notifier).clear();
  read(hoveredNodeProvider.notifier).state = null;
  read(draggingNodeIdProvider.notifier).state = null;
  read(dragOffsetProvider.notifier).state = Offset.zero;
  read(selectedNodeIdProvider.notifier).state = null;
  read(nodeDrawerOpenProvider.notifier).state = false;
  read(workflowDirtyProvider.notifier).state = false;
  return null;
}

/// Open [name] as a subflow tab (no-op when already open) and switch to it.
/// Shared by the strip's `+` menu and the subflow node drawer's edit button.
Future<void> openSubflowTab(WidgetRef ref, String name) async {
  final tabs = ref.read(flowTabsProvider);
  final tab = FlowTab(FlowTabKind.subflow, name);
  if (!tabs.contains(tab)) {
    ref.read(flowTabsProvider.notifier).state = [...tabs, tab];
  }
  await switchToTab(ref, tab);
}

/// Create an `untitled[-N]` flow, append its tab, persist the order, and
/// switch to it. Shared by the strip's `+` menu and the empty-state CTAs.
Future<void> createUntitledFlow(WidgetRef ref) async {
  final api = ref.read(workflowsApiProvider);
  final name = untitledName(ref.read(workflowsProvider).map((w) => w.name));
  final tab = FlowTab(FlowTabKind.flow, name);
  final placeholder = WorkflowSummary(
    id: tab.docId,
    name: name,
    version: 1,
    updated: 'just now',
    nodes: const [],
  );
  try {
    await api.create(name, workflowToYaml(placeholder));
    ref.invalidate(remoteWorkflowsProvider);
    await ref.read(remoteWorkflowsProvider.future);
  } catch (e) {
    debugPrint('create flow failed: $e');
    return;
  }
  final tabs = ref.read(flowTabsProvider);
  if (!tabs.contains(tab)) {
    final next = [...tabs, tab];
    ref.read(flowTabsProvider.notifier).state = next;
    persistFlowOrder(ref, next);
  }
  await switchToTab(ref, tab);
  ref.read(canvasControllerProvider.notifier).reset();
}

/// Create an `untitled[-N]` subflow, append its tab, and switch to it.
Future<void> createUntitledSubflow(WidgetRef ref) async {
  final api = ref.read(subflowsApiProvider);
  final subflows = await ref.read(subflowsProvider.future);
  final name = untitledName(subflows.map((s) => s.name));
  const body = 'params: []\nnodes: []\nconnections: []\n';
  try {
    await api.create(name, 'name: $name\n$body');
    ref.invalidate(subflowsProvider);
    await ref.read(subflowsProvider.future);
  } catch (e) {
    debugPrint('create subflow failed: $e');
    return;
  }
  await openSubflowTab(ref, name);
  ref.read(canvasControllerProvider.notifier).reset();
}
