import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/thrt_api.dart';

/// THRT runtime API client. Targets the same-origin Bun proxy at
/// `trailhead.rancidgrandmas.online`, which forwards `/api/v1/workflows/*`
/// runtime routes to THRT.
final thrtApiProvider = Provider<ThrtApi>((ref) {
  return ThrtApi('');
});

/// Latest runtime status per workflow, keyed by name. Null = not yet fetched.
final flowStatusProvider =
    StateProvider<Map<String, FlowStatus>>((ref) => const {});

/// Active-mode in-memory inject buffer. Keyed `${workflowName}:${nodeId}`.
/// Initialized from the node's YAML `payload_code` on first open; runtime
/// edits here never write back to YAML.
final injectBufferProvider = StateProvider<Map<String, String>>((ref) => const {});
