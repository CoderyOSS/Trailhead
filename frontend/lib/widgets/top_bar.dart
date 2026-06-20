import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../models/workflow_document.dart';
import '../models/workflow_node.dart';
import '../providers/canvas_controller.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart';
import '../providers/selection_notifier.dart';
import 'icons.dart';
import 'app_button.dart';
import 'status_tag.dart';
import 'mode_rail.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    final job = ref.watch(selectedJobProvider);
    final yamlOpen = ref.watch(yamlDrawerOpenProvider);
    final isJobView =
        (mode == AppMode.active && job != null) ||
        (mode == AppMode.history && job != null);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: isJobView
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.bg1.withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(color: AppColors.border1, width: 1),
            ),
          ),
          child: Align(
        alignment: Alignment.centerLeft,
        child: Builder(
          builder: (context) {
            switch (mode) {
              case AppMode.build:
                return _BuildBar();
              case AppMode.active:
                return _JobBar(
                  job: job,
                  mode: mode,
                  yamlOpen: yamlOpen,
                  onToggleYaml: () => ref
                      .read(yamlDrawerOpenProvider.notifier)
                      .state = !yamlOpen,
                  onClearJob: () =>
                      ref.read(selectedJobProvider.notifier).state = null,
                );
              case AppMode.history:
                if (job == null) {
                  return _HistoryListBar();
                }
                return _JobBar(
                  job: job,
                  mode: mode,
                  yamlOpen: yamlOpen,
                  onToggleYaml: () => ref
                      .read(yamlDrawerOpenProvider.notifier)
                      .state = !yamlOpen,
                  onClearJob: () =>
                      ref.read(selectedJobProvider.notifier).state = null,
                );
            }
          },
        ),
      ),
      ),
      ),
    );
  }
}



// ──────────────────────────────────────────────────────────────────────────
// Workflow selector dropdown — replaces the old left sidebar.
// ──────────────────────────────────────────────────────────────────────────

class _WorkflowSelect extends ConsumerStatefulWidget {
  final WorkflowSummary workflow;
  final List<WorkflowSummary> workflows;
  final String? activeWfId;
  final ValueChanged<String> onPick;
  final String Function() onNew;

  const _WorkflowSelect({
    required this.workflow,
    required this.workflows,
    required this.activeWfId,
    required this.onPick,
    required this.onNew,
  });

  @override
  ConsumerState<_WorkflowSelect> createState() => _WorkflowSelectState();
}

class _WorkflowSelectState extends ConsumerState<_WorkflowSelect> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;
  bool _isEditing = false;
  final _editFocusNode = FocusNode();
  late final TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.workflow.name);
  }

  @override
  void didUpdateWidget(covariant _WorkflowSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workflow.name != widget.workflow.name) {
      _editCtrl.text = widget.workflow.name;
    }
  }

  void _toggle() => _open ? _close() : _openDropdown();

  void _openDropdown() {
    if (_isEditing) return;
    setState(() => _open = true);
    _overlay = _createOverlay();
    Overlay.of(context).insert(_overlay!);
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _overlay?.remove();
    _overlay = null;
  }

  void _pick(String id) {
    widget.onPick(id);
    _close();
  }

  void _enterEditMode() {
    if (_open) _close();
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _commitRename(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && trimmed != widget.workflow.name) {
      final id = widget.workflow.id;
      ref.read(workflowsProvider.notifier).update((list) {
        return list.map((w) => w.id == id ? w.copyWith(name: trimmed) : w).toList();
      });
      final current = ref.read(workflowProvider);
      if (current.id == id) {
        ref.read(workflowProvider.notifier).state = current.copyWith(name: trimmed);
      }
    }
    setState(() => _isEditing = false);
  }

  void _startNew() {
    final id = widget.onNew();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterEditMode();
    });
  }

  void _delete(String id) {
    ref.read(workflowsProvider.notifier).update((list) {
      return list.where((w) => w.id != id).toList();
    });
    final current = ref.read(workflowProvider);
    if (current.id == id) {
      final remaining = ref.read(workflowsProvider);
      if (remaining.isNotEmpty) {
        widget.onPick(remaining.first.id);
      }
    }
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 288,
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'switch workflow \u00b7 ${widget.workflows.length}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.08,
                                color: AppColors.fg3,
                              ),
                            ),
                          ),
                          AppButton(
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.sm,
                            icon: TrailheadIconData.plus,
                            label: 'new',
                            onTap: _startNew,
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: AppColors.border1),
                    // List
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: widget.workflows.length,
                        itemBuilder: (context, i) {
                          final wf = widget.workflows[i];
                          return _WorkflowMenuRow(
                            workflow: wf,
                            active: wf.id == widget.activeWfId,
                            onPick: () => _pick(wf.id),
                            onDelete: () => _delete(wf.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    _editFocusNode.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wf = widget.workflow;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 288,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          border: Border.all(
            color: _open ? AppColors.accent : AppColors.border2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _toggle,
                child: _isEditing
                    ? TextField(
                        controller: _editCtrl,
                        focusNode: _editFocusNode,
                        autofocus: true,
                        onSubmitted: _commitRename,
                        onTapOutside: (_) => _commitRename(_editCtrl.text),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg0,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        wf.name,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
            GestureDetector(
              onTap: _enterEditMode,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.transparent,
                ),
                child: Center(
                  child: TrailheadIcon(
                    icon: TrailheadIconData.pencil,
                    size: 12,
                    color: AppColors.fg2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _toggle,
              child: AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.fg2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowMenuRow extends StatefulWidget {
  final WorkflowSummary workflow;
  final bool active;
  final VoidCallback onPick;
  final VoidCallback onDelete;

  const _WorkflowMenuRow({
    required this.workflow,
    required this.active,
    required this.onPick,
    required this.onDelete,
  });

  @override
  State<_WorkflowMenuRow> createState() => _WorkflowMenuRowState();
}

class _WorkflowMenuRowState extends State<_WorkflowMenuRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final wf = widget.workflow;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.bg3
                : _hovering
                    ? AppColors.bg2
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wf.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
                        color: widget.active ? AppColors.fg0 : AppColors.fg1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${wf.runCount.toString()} runs \u00b7 last ${wf.last}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        color: AppColors.fg3,
                      ),
                    ),
                  ],
                ),
              ),
              if (wf.active > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusDot(
                      status: JobState.running,
                      pulse: true,
                      size: 5,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${wf.active}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              if (_hovering)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      border: Border.all(color: AppColors.border1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: TrailheadIcon(
                        icon: TrailheadIconData.trash,
                        size: 12,
                        color: AppColors.fg2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildBar extends ConsumerWidget {
  const _BuildBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wf = ref.watch(workflowProvider);
    final workflows = ref.watch(workflowsProvider);
    final yamlOpen = ref.watch(yamlDrawerOpenProvider);

    return Row(
      children: [
        _WorkflowSelect(
          workflow: wf,
          workflows: workflows,
          activeWfId: wf.id,
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
          onNew: () {
            final id = 'wf_untitled_${DateTime.now().millisecondsSinceEpoch}';
            final newWf = WorkflowSummary(
              id: id,
              name: 'Untitled',
              version: 1,
              updated: 'just now',
              nodes: const [
                WorkflowNode(
                  id: 'entrypoint',
                  kind: 'worker',
                  label: 'entrypoint',
                  x: 0,
                  y: -16,
                ),
              ],
            );
            ref.read(workflowsProvider.notifier).update((list) => [...list, newWf]);
            ref.read(documentsProvider.notifier).update((docs) {
              final m = Map<String, WorkflowDocument>.from(docs);
              m[id] = WorkflowDocument(workflow: newWf, viewport: const CanvasViewport());
              return m;
            });
            ref.read(workflowProvider.notifier).state = newWf;
            ref.read(canvasControllerProvider.notifier).reset();
            ref.read(selectionProvider.notifier).clear();
            ref.read(hoveredNodeProvider.notifier).state = null;
            ref.read(draggingNodeIdProvider.notifier).state = null;
            ref.read(dragOffsetProvider.notifier).state = Offset.zero;
            ref.read(selectedStageIdProvider.notifier).state = null;
            ref.read(stageDrawerOpenProvider.notifier).state = false;
            return id;
          },
        ),
        const Spacer(),
        AppButton(
          variant: yamlOpen ? AppButtonVariant.secondary : AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          icon: TrailheadIconData.file,
          label: 'YAML',
          onTap: () {
            ref.read(yamlDrawerOpenProvider.notifier).state = !yamlOpen;
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 22,
          color: AppColors.border1,
          margin: const EdgeInsets.symmetric(horizontal: 2),
        ),
        const SizedBox(width: 8),
        AppButton(
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
          label: 'save draft',
          onTap: () {},
        ),
        const SizedBox(width: 8),
        AppButton(
          variant: AppButtonVariant.trail,
          size: AppButtonSize.sm,
          icon: TrailheadIconData.play,
          label: 'launch',
          onTap: () {},
        ),
      ],
    );
  }
}

class _HistoryListBar extends StatelessWidget {
  const _HistoryListBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Past jobs',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.fg0,
                height: 1.15,
              ),
            ),
            Text(
              '$historyCount runs \u00b7 last 24h',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.fg2,
                height: 1.15,
              ),
            ),
          ],
        ),
        const Spacer(),
        AppButton(
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          icon: TrailheadIconData.refresh,
          label: 'refresh',
          onTap: () {},
        ),
      ],
    );
  }
}

class _JobBar extends StatelessWidget {
  final JobSummary? job;
  final AppMode mode;
  final bool yamlOpen;
  final VoidCallback onToggleYaml;
  final VoidCallback onClearJob;

  const _JobBar({
    required this.job,
    required this.mode,
    required this.yamlOpen,
    required this.onToggleYaml,
    required this.onClearJob,
  });

  @override
  Widget build(BuildContext context) {
    if (job == null) {
      return Row(
        children: [
          Text(
            mode == AppMode.active
                ? 'select a running job from the sidebar'
                : 'select a past job \u2014 or browse the table',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg2,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JobRow1(
          job: job!,
          mode: mode,
          yamlOpen: yamlOpen,
          onToggleYaml: onToggleYaml,
          onClearJob: onClearJob,
        ),
        const SizedBox(height: 2),
        _JobRow2(job: job!),
      ],
    );
  }
}

class _JobRow1 extends StatelessWidget {
  final JobSummary job;
  final AppMode mode;
  final bool yamlOpen;
  final VoidCallback onToggleYaml;
  final VoidCallback onClearJob;

  const _JobRow1({
    required this.job,
    required this.mode,
    required this.yamlOpen,
    required this.onToggleYaml,
    required this.onClearJob,
  });

  @override
  Widget build(BuildContext context) {
    final tagState = job.state == JobState.paused
        ? JobState.cancelled
        : job.state;

    return Row(
      children: [
        GestureDetector(
          onTap: onClearJob,
          child: Tooltip(
            message: 'back to list',
            child: SizedBox(
              width: 18,
              height: 18,
              child: Center(
                child: Transform.rotate(
                  angle: 3.14159,
                  child: TrailheadIcon(
                    icon: TrailheadIconData.chevRight,
                    size: 14,
                    color: AppColors.fg2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          job.id,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.fg0,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.border1),
          ),
          child: Text(
            '${job.workflow ?? "unknown"} \u00b7 v${job.workflowVersion ?? 0}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: AppColors.fg2,
              height: 1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        StatusTag(status: tagState),
        const Spacer(),
        if (mode == AppMode.active) ...[
          AppButton(
            variant: yamlOpen
                ? AppButtonVariant.secondary
                : AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            icon: TrailheadIconData.file,
            label: 'YAML',
            onTap: onToggleYaml,
          ),
          const SizedBox(width: 6),
          _JobControls(state: job.state),
        ] else ...[
          AppButton(
            variant: yamlOpen
                ? AppButtonVariant.secondary
                : AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            icon: TrailheadIconData.file,
            label: 'YAML',
            onTap: onToggleYaml,
          ),
          const SizedBox(width: 6),
          AppButton(
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
            icon: TrailheadIconData.refresh,
            label: 'rerun',
            onTap: () {},
          ),
        ],
      ],
    );
  }
}

class _JobRow2 extends StatelessWidget {
  final JobSummary job;

  const _JobRow2({required this.job});

  @override
  Widget build(BuildContext context) {
    final mins = job.elapsedSec ~/ 60;
    final secs = job.elapsedSec % 60;

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Row(
        children: [
          Text(
            'input',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              job.input ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.fg2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TrailheadIcon(
            icon: TrailheadIconData.clock,
            size: 10,
            color: AppColors.fg3,
          ),
          const SizedBox(width: 4),
          Text(
            '${mins}m${secs.toString().padLeft(2, '0')}s',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\u00b7',
            style: TextStyle(color: AppColors.border2),
          ),
          const SizedBox(width: 8),
          Text(
            '${(job.tokens / 1000).toStringAsFixed(1)}k tok',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\u00b7',
            style: TextStyle(color: AppColors.border2),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${job.costUsd.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobControls extends StatelessWidget {
  final JobState state;

  const _JobControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final running = state == JobState.running;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CtrlBtn(
            primary: !running,
            onTap: () {},
            label: running ? 'pause' : (state == JobState.paused ? 'resume' : 'start'),
            icon: running
                ? _PauseIcon()
                : TrailheadIcon(
                    icon: TrailheadIconData.play,
                    size: 11,
                    color: AppColors.accentInk,
                  ),
          ),
          _CtrlBtn(
            onTap: () {},
            label: 'stop',
            icon: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.fg0,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _CtrlBtn(
            onTap: () {},
            icon: TrailheadIcon(
              icon: TrailheadIconData.refresh,
              size: 11,
              color: AppColors.fg0,
            ),
          ),
          _CtrlBtn(
            onTap: () {},
            icon: TrailheadIcon(
              icon: TrailheadIconData.bookmark,
              size: 11,
              color: AppColors.fg0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatefulWidget {
  final VoidCallback onTap;
  final String? label;
  final Widget icon;
  final bool primary;

  const _CtrlBtn({
    required this.onTap,
    this.label,
    required this.icon,
    this.primary = false,
  });

  @override
  State<_CtrlBtn> createState() => _CtrlBtnState();
}

class _CtrlBtnState extends State<_CtrlBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary
        ? AppColors.accent
        : (_hovering ? AppColors.bg4 : Colors.transparent);
    final fg = widget.primary ? AppColors.accentInk : AppColors.fg0;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: fg, size: 11),
                child: widget.icon,
              ),
              if (widget.label != null) ...[
                const SizedBox(width: 5),
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: fg,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseIcon extends StatelessWidget {
  const _PauseIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 11,
          decoration: BoxDecoration(
            color: AppColors.accentInk,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 3,
          height: 11,
          decoration: BoxDecoration(
            color: AppColors.accentInk,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
