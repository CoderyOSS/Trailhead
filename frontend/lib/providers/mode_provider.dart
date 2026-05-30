import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/mode_rail.dart';
import 'mock_data.dart';

final modeProvider = StateProvider<AppMode>((ref) => AppMode.active);

final selectedJobProvider = StateProvider<JobSummary?>((ref) => null);

final workflowProvider = StateProvider<WorkflowSummary>((ref) => mockWorkflow);

final workflowsProvider = StateProvider<List<WorkflowSummary>>(
  (ref) => mockWorkflows,
);

final jobsProvider = StateProvider<List<JobSummary>>(
  (ref) => mockJobs,
);

final sidebarViewModeProvider = StateProvider<String>((ref) => 'grouped');

final selectedNodeProvider = StateProvider<String?>((ref) => null);

final runsTableViewModeProvider = StateProvider<String>((ref) => 'flat');
