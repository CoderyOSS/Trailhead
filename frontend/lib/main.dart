import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'providers/mode_provider.dart';
import 'widgets/mode_rail.dart';
import 'widgets/top_bar.dart';
import 'widgets/workflows_sidebar.dart';
import 'widgets/jobs_sidebar.dart';
import 'widgets/canvas/graph_canvas.dart';
import 'widgets/runs_table.dart';

void main() {
  runApp(const TrailheadApp());
}

class TrailheadApp extends StatelessWidget {
  const TrailheadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Trailhead',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.bg0,
        ),
        home: const TrailheadShell(),
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

    return Scaffold(
      body: Row(
        children: [
          const ModeRail(activeCount: 3),
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
              ],
            ),
          ),
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
            final wf = ref.read(workflowsProvider).firstWhere(
              (w) => w.id == id,
              orElse: () => ref.read(workflowProvider),
            );
            ref.read(workflowProvider.notifier).state = wf;
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
