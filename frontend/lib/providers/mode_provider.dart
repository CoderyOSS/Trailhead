import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_document.dart';
import '../models/workflow_node.dart';
import '../utils/yaml_to_workflow.dart';
import '../widgets/mode_rail.dart';
import '../services/jobs_api.dart';
import '../services/workflows_api.dart';
import 'api_provider.dart';
import 'mock_data.dart';

final modeProvider = StateProvider<AppMode>((ref) => AppMode.build);

final selectedJobProvider = StateProvider<JobDto?>((ref) => null);

final autoRefreshJobsProvider = StateProvider<int>((ref) => 0);

/// Raw workflow DTOs from the backend (name + content + content_hash).
/// Split from [remoteWorkflowsProvider] so consumers that need transport
/// metadata (e.g. the tab-sync rename detector) keep access to content_hash.
final remoteWorkflowDtosProvider =
    FutureProvider<List<WorkflowDto>>((ref) async {
  // Watch api so a config reload re-fetches.
  ref.watch(workflowsApiProvider);
  return ref.read(workflowsApiProvider).list();
});

/// All workflows loaded from backend, parsed into canvas models.
/// Each item is either a fully parsed WorkflowSummary or an "incompatible"
/// placeholder (parseError != null) that can only be deleted.
final remoteWorkflowsProvider =
    FutureProvider<List<WorkflowSummary>>((ref) async {
  final dtos = await ref.watch(remoteWorkflowDtosProvider.future);
  return dtos.map((d) {
    try {
      return yamlToWorkflow(d.name, d.content);
    } catch (e) {
      return WorkflowSummary.incompatible(
        name: d.name,
        parseError: e.toString(),
        remoteContent: d.content,
      );
    }
  }).toList();
});

/// Synchronous list view: empty while loading, populated on success.
/// For error handling, read [remoteWorkflowsProvider] directly.
final workflowsProvider = Provider<List<WorkflowSummary>>((ref) {
  return ref.watch(remoteWorkflowsProvider).maybeWhen(
        data: (list) => list,
        orElse: () => const [],
      );
});

/// Sentinel for "no workflow selected" state. The canvas renders an empty
/// graph (no nodes/edges) and the top bar shows a create-first-workflow CTA.
const emptyWorkflowId = '__empty__';

final _emptyWorkflow = WorkflowSummary(
  id: emptyWorkflowId,
  name: '',
  version: 0,
  updated: '',
);

/// Currently active workflow for canvas editing. Defaults to the empty
/// sentinel until remote workflows load and one is auto-selected.
final workflowProvider = StateProvider<WorkflowSummary>((ref) => _emptyWorkflow);

/// Jobs list — fetched from backend.
final jobsProvider = FutureProvider<List<JobDto>>((ref) async {
  ref.watch(autoRefreshJobsProvider);
  ref.watch(jobsApiProvider);
  final api = ref.read(jobsApiProvider);
  return api.list();
});

final hoveredNodeProvider = StateProvider<String?>((ref) => null);

final draggingNodeIdProvider = StateProvider<String?>((ref) => null);

final dragOffsetProvider = StateProvider<Offset>((ref) => Offset.zero);

final spaceHeldProvider = StateProvider<bool>((ref) => false);

final runsTableViewModeProvider = StateProvider<String>((ref) => 'flat');

final yamlDrawerOpenProvider = StateProvider<bool>((ref) => false);

final nodeDrawerOpenProvider = StateProvider<bool>((ref) => false);

final selectedNodeIdProvider = StateProvider<String?>((ref) => null);

final nodeDrawerTabProvider = StateProvider<Map<String, String>>((ref) => {});

/// Which log points are currently enabled for viewing in the LogDrawer.
/// Each entry is a `${nodeId}.${dir}` string. Subset of all
/// logging-enabled points on the flow.
final enabledLogPointsProvider = StateProvider<Set<String>>((ref) => const {});

/// Per-workflow canvas viewport snapshots. Lazily populated on switch.
final documentsProvider =
    StateProvider<Map<String, WorkflowDocument>>((ref) {
  return {};
});

/// True when the active workflow has unsaved canvas edits.
final workflowDirtyProvider = StateProvider<bool>((ref) => false);

/// Per-job independent workflow snapshots, keyed by job id.
///
/// A job launches from a copy of the workflow YAML (`JobDto.content`, stored
/// by THRT at create time). In Active mode the canvas and drawer bind to
/// this copy — edits here never touch [workflowProvider], so the stored
/// workflow and the autosave path stay untouched.
final jobDocumentsProvider =
    StateProvider<Map<String, WorkflowSummary>>((ref) => {});

/// The document the canvas renders: the selected job's snapshot in Active
/// mode, otherwise the live workflow.
final canvasWorkflowProvider = Provider<WorkflowSummary>((ref) {
  if (ref.watch(modeProvider) == AppMode.active) {
    final job = ref.watch(selectedJobProvider);
    if (job != null) {
      final doc = ref.watch(jobDocumentsProvider)[job.id];
      if (doc != null) return doc;
    }
  }
  return ref.watch(workflowProvider);
});

/// Routes a canvas-model mutation to the selected job's snapshot in Active
/// mode, or to the live workflow otherwise. Job-snapshot edits bypass the
/// autosave listener (which only watches [workflowProvider]).
void updateCanvasWorkflow(
  WidgetRef ref,
  WorkflowSummary Function(WorkflowSummary) update,
) {
  final mode = ref.read(modeProvider);
  final job = ref.read(selectedJobProvider);
  if (mode == AppMode.active && job != null) {
    ref.read(jobDocumentsProvider.notifier).update((docs) {
      final m = Map<String, WorkflowSummary>.from(docs);
      final cur = m[job.id];
      if (cur != null) m[job.id] = update(cur);
      return m;
    });
  } else {
    ref.read(workflowProvider.notifier).update(update);
  }
}

/// Convenience wrapper over [updateCanvasWorkflow] for the common case of
/// transforming a single node by id.
void updateCanvasNode(
  WidgetRef ref,
  String nodeId,
  WorkflowNode Function(WorkflowNode) update,
) {
  updateCanvasWorkflow(
    ref,
    (wf) => wf.copyWith(
      nodes: wf.nodes.map((n) => n.id == nodeId ? update(n) : n).toList(),
    ),
  );
}

/// Ensures a snapshot exists for [job] in [jobDocumentsProvider]. Parses
/// the YAML the job was launched with (`job.content`); falls back to the
/// currently loaded workflow of the same name when content is unavailable
/// (e.g. jobs created before content snapshots existed).
void ensureJobDocument(WidgetRef ref, JobDto job) {
  final docs = ref.read(jobDocumentsProvider);
  if (docs.containsKey(job.id)) return;

  WorkflowSummary? doc;
  final content = job.content;
  if (content != null) {
    try {
      doc = yamlToWorkflow(job.flowName, content);
    } catch (_) {
      doc = null;
    }
  }
  doc ??= ref
      .read(workflowsProvider)
      .cast<WorkflowSummary?>()
      .firstWhere((w) => w!.name == job.flowName, orElse: () => null);
  if (doc == null) return;

  ref.read(jobDocumentsProvider.notifier).update((docs) {
    final m = Map<String, WorkflowSummary>.from(docs);
    m[job.id] = doc!;
    return m;
  });
}
