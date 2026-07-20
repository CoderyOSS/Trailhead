import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/thrt_api.dart';
import '../widgets/mode_rail.dart';
import 'mode_provider.dart';

/// THRT runtime API client. Targets the same-origin Bun proxy at
/// `trailhead.rancidgrandmas.online`, which forwards `/api/v1/workflows/*`
/// runtime routes to THRT.
final thrtApiProvider = Provider<ThrtApi>((ref) {
  return ThrtApi('');
});

/// Latest runtime status per workflow, keyed by name. Null = not yet fetched.
final flowStatusProvider =
    StateProvider<Map<String, FlowStatus>>((ref) => const {});

/// POST [code] to the inject endpoint for [nodeId], then refresh the flow's
/// runtime status so counters/badges update everywhere. [isExpr] routes the
/// code through backend expression evaluation instead of literal parsing.
Future<void> triggerNodeInject(
  WidgetRef ref,
  String workflowName,
  String nodeId,
  String code, {
  bool isExpr = false,
}) async {
  await ref.read(thrtApiProvider).injectCode(workflowName, nodeId, code, isExpr: isExpr);
  final status = await ref.read(thrtApiProvider).status(workflowName);
  ref.read(flowStatusProvider.notifier).state =
      Map<String, FlowStatus>.from(ref.read(flowStatusProvider))
        ..[workflowName] = status;
}

/// Active-mode in-memory inject buffer. Keyed by [injectBufferKey].
/// Initialized from the node's `payload_code` on first open; runtime edits
/// here never write back to YAML.
final injectBufferProvider = StateProvider<Map<String, String>>((ref) => const {});

/// Buffer key for inject payloads: job-scoped in Active mode (per job
/// snapshot), workflow-scoped otherwise.
String injectBufferKey(WidgetRef ref, String nodeId) {
  final job = ref.read(selectedJobProvider);
  if (ref.read(modeProvider) == AppMode.active && job != null) {
    return 'job:${job.id}:$nodeId';
  }
  final wf = ref.read(workflowProvider);
  return '${wf.name}:$nodeId';
}

/// Node modules installed in the connected runtime. Drives the dynamic
/// "INSTALLED MODULES" category in the add-node picker and actor/function
/// edge classification for non-builtin kinds.
final installedNodesProvider = FutureProvider<List<InstalledNode>>((ref) async {
  return ref.read(thrtApiProvider).fetchNodes();
});

/// Project registry: current project dir, registered project dirs, and
/// global package names. Drives the workflow project picker.
final projectsProvider = FutureProvider<ThrtProjects>((ref) async {
  return ref.read(thrtApiProvider).fetchProjects();
});

/// Validation problems for the active workflow, from
/// POST /api/v1/workflows/validate. Empty = valid (or not yet checked).
/// Updated by the shell after autosave and on workflow switch.
final validationErrorsProvider = StateProvider<List<String>>((ref) => const []);
