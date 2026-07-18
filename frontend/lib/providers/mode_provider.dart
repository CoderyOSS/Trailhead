import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_document.dart';
import '../utils/yaml_to_workflow.dart';
import '../widgets/mode_rail.dart';
import '../services/jobs_api.dart';
import 'api_provider.dart';
import 'mock_data.dart';

final modeProvider = StateProvider<AppMode>((ref) => AppMode.build);

final selectedJobProvider = StateProvider<JobDto?>((ref) => null);

final autoRefreshJobsProvider = StateProvider<int>((ref) => 0);

/// All workflows loaded from backend, parsed into canvas models.
/// Each item is either a fully parsed WorkflowSummary or an "incompatible"
/// placeholder (parseError != null) that can only be deleted.
final remoteWorkflowsProvider =
    FutureProvider<List<WorkflowSummary>>((ref) async {
  // Watch api so a config reload re-fetches.
  ref.watch(workflowsApiProvider);
  final api = ref.read(workflowsApiProvider);
  final dtos = await api.list();
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

/// Auto-selects the first remote workflow on initial load.
final autoSelectFirstWorkflowProvider =
    FutureProvider<WorkflowSummary?>((ref) async {
  final list = await ref.watch(remoteWorkflowsProvider.future);
  final current = ref.read(workflowProvider);
  if (current.id != emptyWorkflowId) return current;
  if (list.isEmpty) return null;
  final first = list.first;
  ref.read(workflowProvider.notifier).state = first;
  return first;
});

/// Jobs list — fetched from backend.
final jobsProvider = FutureProvider<List<JobDto>>((ref) async {
  ref.watch(autoRefreshJobsProvider);
  ref.watch(jobsApiProvider);
  final api = ref.read(jobsApiProvider);
  return api.list();
});

final sidebarViewModeProvider = StateProvider<String>((ref) => 'grouped');

final hoveredNodeProvider = StateProvider<String?>((ref) => null);

final draggingNodeIdProvider = StateProvider<String?>((ref) => null);

final dragOffsetProvider = StateProvider<Offset>((ref) => Offset.zero);

final spaceHeldProvider = StateProvider<bool>((ref) => false);

final runsTableViewModeProvider = StateProvider<String>((ref) => 'flat');

final yamlDrawerOpenProvider = StateProvider<bool>((ref) => false);

final nodeDrawerOpenProvider = StateProvider<bool>((ref) => false);

final selectedNodeIdProvider = StateProvider<String?>((ref) => null);

final nodeDrawerTabProvider = StateProvider<Map<String, String>>((ref) => {});

/// Top-level drawer panel selection ('node' | 'log'). Only visible in active
/// mode — in build mode the panel defaults to 'node' and the toggle is hidden.
final drawerPanelProvider = StateProvider<String>((ref) => 'node');

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
