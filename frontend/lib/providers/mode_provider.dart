import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/mode_rail.dart';
import 'mock_data.dart';

final modeProvider = StateProvider<AppMode>((ref) => AppMode.active);

final selectedJobProvider = StateProvider<JobSummary?>((ref) => null);

final workflowProvider = StateProvider<WorkflowSummary>((ref) => mockWorkflow);
