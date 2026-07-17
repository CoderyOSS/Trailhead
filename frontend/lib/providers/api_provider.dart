import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workflows_api.dart';
import '../services/jobs_api.dart';

final workflowsApiProvider = Provider<WorkflowsApi>((ref) {
  return WorkflowsApi('/api/v1');
});

final jobsApiProvider = Provider<JobsApi>((ref) {
  return JobsApi('/api/v1');
});
