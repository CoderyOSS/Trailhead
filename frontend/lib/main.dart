import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'theme/theme_controller.dart';
import 'models/workflow_document.dart';
import 'models/workflow_node.dart';
import 'providers/canvas_controller.dart';
import 'providers/mode_provider.dart';
import 'providers/selection_notifier.dart';
import 'widgets/mode_rail.dart';
import 'widgets/top_bar.dart';
import 'widgets/workflows_sidebar.dart';
import 'widgets/jobs_sidebar.dart';
import 'widgets/canvas/graph_canvas.dart';
import 'widgets/runs_table.dart';
import 'widgets/yaml_drawer.dart';
import 'widgets/stage_drawer/stage_drawer.dart';

import 'widgets/settings/settings_modal.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(const TrailheadApp());
}

class TrailheadApp extends StatelessWidget {
  const TrailheadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ListenableBuilder(
        listenable: ThemeController(),
        builder: (context, child) => MaterialApp(
          title: 'Trailhead',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.bg0,
          ),
          home: const TrailheadShell(),
        ),
      ),
    );
  }
}

class TrailheadShell extends ConsumerWidget {
  const TrailheadShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final job = ref.watch(selectedJobProvider);
    final showSidebar = mode != AppMode.history || job != null;
    final yamlOpen = mode == AppMode.build && ref.watch(yamlDrawerOpenProvider);
    final stageOpen = ref.watch(stageDrawerOpenProvider);
    final stageId = ref.watch(selectedStageIdProvider);
    final workflow = ref.watch(workflowProvider);
    final settingsOpen = ref.watch(settingsModalOpenProvider);
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    final stageNode = stageId != null
        ? workflow.nodes.cast<WorkflowNode?>().firstWhere(
            (n) => n!.id == stageId,
            orElse: () => null,
          )
        : null;

    final drawerView = (mode == AppMode.active || mode == AppMode.history) && job != null
        ? StageDrawerView.job
        : StageDrawerView.builder;

    Widget workflowRegion({Widget? bottomPanel}) {
      return Row(
        children: [
          ModeRail(activeCount: 3),
          if (showSidebar) _buildSidebar(mode, ref),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: mode == AppMode.history && job == null
                      ? const RunsTable()
                      : const GraphCanvas(),
                ),
                if (bottomPanel != null) Expanded(child: bottomPanel),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildDrawerPanel() {
      if (!yamlOpen && !stageOpen) return const SizedBox.shrink();

      if (isPortrait) {
        // Portrait: side-by-side in bottom panel
        return Row(
          children: [
            if (yamlOpen)
              Expanded(
                child: YamlDrawer(
                  workflow: workflow,
                  onClose: () => ref
                      .read(yamlDrawerOpenProvider.notifier)
                      .state = false,
                  isPortrait: true,
                ),
              ),
            if (stageOpen && stageNode != null)
              Expanded(
                child: StageDrawer(
                  stage: stageNode,
                  view: drawerView,
                  onClose: () {
                    ref.read(stageDrawerOpenProvider.notifier).state = false;
                    ref.read(selectedStageIdProvider.notifier).state = null;
                  },
                  isPortrait: true,
                ),
              ),
          ],
        );
      }

      // Landscape: neighboring columns on the right
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (yamlOpen)
            YamlDrawer(
              workflow: workflow,
              onClose: () => ref
                  .read(yamlDrawerOpenProvider.notifier)
                  .state = false,
            ),
          if (stageOpen && stageNode != null)
            StageDrawer(
              stage: stageNode,
              view: drawerView,
              onClose: () {
                ref.read(stageDrawerOpenProvider.notifier).state = false;
                ref.read(selectedStageIdProvider.notifier).state = null;
              },
            ),
        ],
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isPortrait && (yamlOpen || stageOpen)
                    ? workflowRegion(bottomPanel: buildDrawerPanel())
                    : Row(
                        children: [
                          Expanded(child: workflowRegion()),
                          buildDrawerPanel(),
                        ],
                      ),
              ),
              Container(height: 1, color: AppColors.border1),
            ],
          ),
          if (settingsOpen)
            const SettingsModalOverlay(),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppMode mode, WidgetRef ref) {
    switch (mode) {
      case AppMode.build:
        return WorkflowsSidebar(
          activeId: ref.watch(workflowProvider).id,
          onPick: (id) {
            // Save current document before switching.
            final currentWf = ref.read(workflowProvider);
            final currentVp = ref.read(canvasControllerProvider);
            ref.read(documentsProvider.notifier).update((docs) {
              final m = Map<String, WorkflowDocument>.from(docs);
              m[currentWf.id] = WorkflowDocument(workflow: currentWf, viewport: currentVp);
              return m;
            });
            // Load selected document.
            final doc = ref.read(documentsProvider)[id] ?? WorkflowDocument(
              workflow: ref.read(workflowsProvider).firstWhere((w) => w.id == id),
            );
            ref.read(workflowProvider.notifier).state = doc.workflow;
            ref.read(canvasControllerProvider.notifier).setViewport(doc.viewport);
            ref.read(selectionProvider.notifier).clear();
            ref.read(hoveredNodeProvider.notifier).state = null;
            ref.read(draggingNodeIdProvider.notifier).state = null;
            ref.read(dragOffsetProvider.notifier).state = Offset.zero;
            ref.read(selectedStageIdProvider.notifier).state = null;
            ref.read(stageDrawerOpenProvider.notifier).state = false;
          },
        );
      case AppMode.active:
        return JobsSidebar(
          kind: JobsSidebarKind.active,
          activeId: ref.watch(selectedJobProvider)?.id,
          onPick: (id) {
            final job = ref.read(jobsProvider).firstWhere(
              (j) => j.id == id,
            );
            ref.read(selectedJobProvider.notifier).state = job;
          },
        );
      case AppMode.history:
        return JobsSidebar(
          kind: JobsSidebarKind.history,
          activeId: ref.watch(selectedJobProvider)?.id,
          onPick: (id) {
            final job = ref.read(jobsProvider).firstWhere(
              (j) => j.id == id,
            );
            ref.read(selectedJobProvider.notifier).state = job;
          },
        );
    }
  }
}
