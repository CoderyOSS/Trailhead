import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/carta_api.dart';
import '../services/jobs_api.dart';
import '../widgets/mode_rail.dart';
import 'api_provider.dart';
import 'mode_provider.dart';

/// Carta runtime API client. Targets the same-origin Bun proxy at
/// `carta.rancidgrandmas.online`, which forwards `/api/v1/workflows/*`
/// runtime routes to Carta.
final cartaApiProvider = Provider<CartaApi>((ref) {
  return CartaApi('');
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
  await ref.read(cartaApiProvider).injectCode(workflowName, nodeId, code, isExpr: isExpr);
  final status = await ref.read(cartaApiProvider).status(workflowName);
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
  return ref.read(cartaApiProvider).fetchNodes();
});

/// Validation problems for the active workflow, from
/// POST /api/v1/workflows/validate. Empty = valid (or not yet checked).
/// Updated by the shell after autosave and on workflow switch.
final validationErrorsProvider = StateProvider<List<String>>((ref) => const []);

/// Cancel [jobId] via [JobsApi], then clear [selectedJobProvider] and
/// refresh [jobsProvider]. Clearing the selection (rather than holding the
/// cancelled [JobDto]) lets the Active-mode empty-state hero render — a
/// cancelled job is no longer the "active" canvas. The job remains in the
/// refreshed [jobsProvider] list and is re-selectable from the runs table.
Future<void> cancelJob(WidgetRef ref, String jobId) async {
  await ref.read(jobsApiProvider).cancel(jobId);
  ref.read(selectedJobProvider.notifier).state = null;
  ref.invalidate(jobsProvider);
}
