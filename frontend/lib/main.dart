import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/tokens.dart';
import 'theme/theme_controller.dart';
import 'providers/settings_provider.dart';
import 'models/workflow_node.dart';
import 'providers/api_provider.dart';
import 'providers/mode_provider.dart';
import 'providers/thrt_provider.dart';
import 'widgets/validation_banner.dart';
import 'providers/mock_data.dart' show WorkflowSummary;
import 'providers/server_defs_provider.dart';
import 'utils/workflow_to_yaml.dart';
import 'widgets/mode_rail.dart';
import 'widgets/top_bar.dart';
import 'widgets/canvas/graph_canvas.dart';
import 'widgets/empty_workflow_hero.dart';
import 'widgets/runs_table.dart';
import 'widgets/yaml_drawer.dart';
import 'widgets/node_drawer/node_drawer.dart';
import 'widgets/drawer_panel.dart';

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
    _validate(wf, yaml);
  }

  /// Run THRT validation for the workflow and update the banner provider.
  /// Fire-and-forget: network failures keep the previous error state.
  Future<void> _validate(WorkflowSummary wf, [String? yaml]) async {
    if (wf.id == emptyWorkflowId || wf.parseError != null) {
      ref.read(validationErrorsProvider.notifier).state = const [];
      return;
    }
    try {
      final errors = await ref
          .read(thrtApiProvider)
          .validateWorkflow(content: yaml ?? workflowToYaml(wf));
      if (mounted) {
        ref.read(validationErrorsProvider.notifier).state = errors;
      }
    } catch (e) {
      debugPrint('validation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final job = ref.watch(selectedJobProvider);
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
        _validate(next);
        return;
      }
      _scheduleAutosave(next);
    });

    final selectedNode = selectedNodeId != null
        ? ref
            .watch(canvasWorkflowProvider)
            .nodes
            .cast<WorkflowNode?>()
            .firstWhere(
              (n) => n!.id == selectedNodeId,
              orElse: () => null,
            )
        : null;

    final drawerView = mode == AppMode.active ||
            (mode == AppMode.history && job != null)
        ? NodeDrawerView.job
        : NodeDrawerView.builder;

    Widget _buildCanvasContent() {
      return Stack(
        children: [
          Positioned.fill(
            child: isEmptyWorkflow
                ? EmptyWorkflowHero()
                : mode == AppMode.history && job == null
                    ? RunsTable()
                    : GraphCanvas(),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(child: ValidationBanner()),
          ),
        ],
      );
    }

    Widget workflowRegion({Widget? bottomPanel}) {
      return Row(
        children: [
          ModeRail(activeCount: runningCount),
          Expanded(
              child: Column(
              children: [
                TopBar(),
                Expanded(child: _buildCanvasContent()),
                if (bottomPanel != null) Expanded(child: bottomPanel),
              ],
            ),
          ),
        ],
      );
    }

    Widget buildDrawerPanel() {
      // Active mode: drawer is forced open (2-column logs | node layout).
      final activeForced = mode == AppMode.active;
      if (!yamlOpen && !nodeOpen && !activeForced) {
        return const SizedBox.shrink();
      }

      final showNodeDrawer = activeForced ||
          (nodeOpen && selectedNode != null && mode != AppMode.history);

      void closeDrawer() {
        ref.read(nodeDrawerOpenProvider.notifier).state = false;
        ref.read(selectedNodeIdProvider.notifier).state = null;
      }

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
                child: DrawerPanel(
                  key: _nodeDrawerKey(selectedNode?.id ?? 'none', drawerView),
                  node: selectedNode,
                  view: drawerView,
                  onClose: closeDrawer,
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
            DrawerPanel(
              key: _nodeDrawerKey(selectedNode?.id ?? 'none', drawerView),
              node: selectedNode,
              view: drawerView,
              onClose: closeDrawer,
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
                child: isPortrait &&
                        (yamlOpen || nodeOpen || mode == AppMode.active)
                     ? workflowRegion(bottomPanel: buildDrawerPanel())
                     : Row(
                         children: [
                           ModeRail(activeCount: runningCount),
                           Expanded(
                             child: Column(
                               children: [
                                 TopBar(),
                                 Expanded(
                                   child: Row(
                                     children: [
                                       Expanded(child: _buildCanvasContent()),
                                       buildDrawerPanel(),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           ),
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
}
