import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_document.dart';
import '../widgets/mode_rail.dart';
import 'canvas_controller.dart';
import 'mock_data.dart';

final modeProvider = StateProvider<AppMode>((ref) => AppMode.build);

final selectedJobProvider = StateProvider<JobSummary?>((ref) => null);

final workflowProvider = StateProvider<WorkflowSummary>((ref) => mockWorkflow);

final workflowsProvider = StateProvider<List<WorkflowSummary>>(
  (ref) => mockWorkflows,
);

final jobsProvider = StateProvider<List<JobSummary>>(
  (ref) => mockJobs,
);

final sidebarViewModeProvider = StateProvider<String>((ref) => 'grouped');

final hoveredNodeProvider = StateProvider<String?>((ref) => null);

final draggingNodeIdProvider = StateProvider<String?>((ref) => null);

final dragOffsetProvider = StateProvider<Offset>((ref) => Offset.zero);

final spaceHeldProvider = StateProvider<bool>((ref) => false);

final runsTableViewModeProvider = StateProvider<String>((ref) => 'flat');

final yamlDrawerOpenProvider = StateProvider<bool>((ref) => false);

final stageDrawerOpenProvider = StateProvider<bool>((ref) => false);

final selectedStageIdProvider = StateProvider<String?>((ref) => null);

final documentsProvider = StateProvider<Map<String, WorkflowDocument>>((ref) {
  return {
    for (final wf in mockWorkflows)
      wf.id: WorkflowDocument(workflow: wf, viewport: const CanvasViewport()),
  };
});
