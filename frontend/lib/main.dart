import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'theme/theme_controller.dart';
import 'providers/settings_provider.dart';
import 'models/workflow_node.dart';
import 'providers/api_provider.dart';
import 'providers/mode_provider.dart';
import 'services/jobs_api.dart';
import 'providers/mock_data.dart' show WorkflowSummary;
import 'providers/server_defs_provider.dart';
import 'utils/workflow_to_yaml.dart';
import 'widgets/mode_rail.dart';
import 'widgets/top_bar.dart';
import 'widgets/jobs_sidebar.dart';
import 'widgets/canvas/graph_canvas.dart';
import 'widgets/empty_workflow_hero.dart';
import 'widgets/runs_table.dart';
import 'widgets/yaml_drawer.dart';
import 'widgets/node_drawer/node_drawer.dart';

import 'widgets/settings/settings_modal.dart';

final _nodeDrawerKeys = <String, GlobalObjectKey>{};

GlobalObjectKey _nodeDrawerKey(String nodeId, NodeDrawerView view) {
  final keyString = '${nodeId}_${view.name}';
  return _nodeDrawerKeys.putIfAbsent(
    keyString,
    () => GlobalObjectKey(keyString),
  );
}

const _yamlDrawerKey = GlobalObjectKey('yaml_drawer');

void main() {
  runApp(ProviderScope(child: TrailheadApp()));
}

// TrailheadApp watches settingsProvider so theme/accent changes force a full
// root rebuild. Do NOT make TrailheadShell const in MaterialApp.home — const
// widgets skip rebuilds even when ancestors rebuild, breaking theme propagation.
class TrailheadApp extends ConsumerWidget {
  TrailheadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider);
    return ProviderScope(
      child: ListenableBuilder(
        listenable: ThemeController(),
        builder: (context, child) => MaterialApp(
          title: 'Trailhead',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.bg0,
          ),
          home: TrailheadShell(),
        ),
      ),
    );
  }
}

class TrailheadShell extends ConsumerStatefulWidget {
  TrailheadShell({super.key});

  @override
  ConsumerState<TrailheadShell> createState() => _TrailheadShellState();
}

class _TrailheadShellState extends ConsumerState<TrailheadShell> {
  Timer? _autosaveTimer;
  String? _lastSavedYaml;

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutosave(WorkflowSummary wf) {
    if (wf.id == emptyWorkflowId) return;
    if (wf.parseError != null) return;
    // Compare serialized YAML so ANY field change (prompt, model, kind,
    // outputs, cases, etc.) triggers a save — not just position/label.
    final yaml = workflowToYaml(wf);
    if (_lastSavedYaml == yaml) return;
    _autosaveTimer?.cancel();
    ref.read(workflowDirtyProvider.notifier).state = true;
    _autosaveTimer = Timer(const Duration(milliseconds: 800), _flushAutosave);
  }

  Future<void> _flushAutosave() async {
    final wf = ref.read(workflowProvider);
    if (wf.id == emptyWorkflowId || wf.parseError != null) {
      ref.read(workflowDirtyProvider.notifier).state = false;
      return;
    }
    final yaml = workflowToYaml(wf);
    try {
      final api = ref.read(workflowsApiProvider);
      await api.replace(wf.name, yaml);
      _lastSavedYaml = yaml;
      // Update remote list so dropdown reflects new mtime if it changes.
      ref.invalidate(remoteWorkflowsProvider);
        await ref.read(remoteWorkflowsProvider.future);
    } catch (e) {
      debugPrint('autosave failed: $e');
    } finally {
      if (mounted) ref.read(workflowDirtyProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final job = ref.watch(selectedJobProvider);
    final showSidebar = mode != AppMode.build;
    final yamlOpen = mode == AppMode.build && ref.watch(yamlDrawerOpenProvider);
    final nodeOpen = ref.watch(nodeDrawerOpenProvider);
    final selectedNodeId = ref.watch(selectedNodeIdProvider);
    final workflow = ref.watch(workflowProvider);
    final settingsOpen = ref.watch(settingsModalOpenProvider);
    final jobsAsync = ref.watch(jobsProvider);
    final runningCount = jobsAsync.maybeWhen(
      data: (list) => list.where((j) => j.status == 'running').length,
      orElse: () => 0,
    );
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final isEmptyWorkflow = workflow.id == emptyWorkflowId;

    // Autosave: debounce-write workflow state changes to backend.
    ref.listen<WorkflowSummary>(workflowProvider, (prev, next) {
      if (prev?.id != next.id) {
        // Workflow switched: sync server definitions.
        ref.read(serverDefsProvider.notifier).state = next.servers;
      }
      if (prev == null || prev.id != next.id) {
        // Workflow switched — reset autosave tracker.
        _lastSavedYaml = null;
        // Still schedule a save in case the new workflow is dirty.
        _scheduleAutosave(next);
        return;
      }
      _scheduleAutosave(next);
    });

    final selectedNode = selectedNodeId != null
        ? workflow.nodes.cast<WorkflowNode?>().firstWhere(
            (n) => n!.id == selectedNodeId,
            orElse: () => null,
          )
        : null;

    final drawerView = (mode == AppMode.active || mode == AppMode.history) && job != null
        ? NodeDrawerView.job
        : NodeDrawerView.builder;

    Widget workflowRegion({Widget? bottomPanel}) {
      return Row(
        children: [
          ModeRail(activeCount: runningCount),
          if (showSidebar) _buildSidebar(mode),
          Expanded(
            child: Column(
              children: [
                TopBar(),
                Expanded(
                  child: isEmptyWorkflow
                      ? EmptyWorkflowHero()
                      : mode == AppMode.history && job == null
                          ? RunsTable()
                          : GraphCanvas(),
                ),
                if (bottomPanel != null) Expanded(child: bottomPanel),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildDrawerPanel() {
      if (!yamlOpen && !nodeOpen) return const SizedBox.shrink();

      final showNodeDrawer = nodeOpen && selectedNode != null && mode != AppMode.history;

      if (isPortrait) {
        return Row(
          children: [
            if (yamlOpen)
              Expanded(
                child: YamlDrawer(
                  key: _yamlDrawerKey,
                  workflow: workflow,
                  onClose: () => ref
                      .read(yamlDrawerOpenProvider.notifier)
                      .state = false,
                  isPortrait: true,
                ),
              ),
            if (showNodeDrawer)
              Expanded(
                child: NodeDrawer(
                  key: _nodeDrawerKey(selectedNode.id, drawerView),
                  node: selectedNode,
                  view: drawerView,
                  onClose: () {
                    ref.read(nodeDrawerOpenProvider.notifier).state = false;
                    ref.read(selectedNodeIdProvider.notifier).state = null;
                  },
                  isPortrait: true,
                ),
              ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (yamlOpen)
            YamlDrawer(
              key: _yamlDrawerKey,
              workflow: workflow,
              onClose: () => ref
                  .read(yamlDrawerOpenProvider.notifier)
                  .state = false,
            ),
          if (showNodeDrawer)
            NodeDrawer(
              key: _nodeDrawerKey(selectedNode.id, drawerView),
              node: selectedNode,
              view: drawerView,
              onClose: () {
                ref.read(nodeDrawerOpenProvider.notifier).state = false;
                ref.read(selectedNodeIdProvider.notifier).state = null;
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
                child: isPortrait && (yamlOpen || nodeOpen)
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
          if (settingsOpen) SettingsModalOverlay(),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppMode mode) {
    switch (mode) {
      case AppMode.build:
        return const SizedBox.shrink();
      case AppMode.active:
        return JobsSidebar(
          kind: JobsSidebarKind.active,
          activeId: ref.watch(selectedJobProvider)?.id,
          onPick: (id) {
            final jobsAsync = ref.read(jobsProvider);
            jobsAsync.whenData((list) {
              final job = list.cast<JobDto?>().firstWhere(
                (j) => j!.id == id,
                orElse: () => null,
              );
              if (job != null) {
                ref.read(selectedJobProvider.notifier).state = job;
              }
            });
          },
        );
      case AppMode.history:
        return JobsSidebar(
          kind: JobsSidebarKind.history,
          activeId: ref.watch(selectedJobProvider)?.id,
          onPick: (id) {
            final jobsAsync = ref.read(jobsProvider);
            jobsAsync.whenData((list) {
              final job = list.cast<JobDto?>().firstWhere(
                (j) => j!.id == id,
                orElse: () => null,
              );
              if (job != null) {
                ref.read(selectedJobProvider.notifier).state = job;
              }
            });
          },
        );
    }
  }
}
