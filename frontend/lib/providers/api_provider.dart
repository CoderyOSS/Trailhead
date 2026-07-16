import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workflows_api.dart';

/// Workflows API client. Uses relative `/api/v1` paths — the frontend is
/// served from the same Bun proxy as the API in production, so no
/// absolute URL or config is needed. The dev preview (Bun) proxies
/// `/api/*` to the backend via `serve.js`.
final workflowsApiProvider = Provider<WorkflowsApi>((ref) {
  return WorkflowsApi('/api/v1');
});
