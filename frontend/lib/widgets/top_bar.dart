import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _editingRowId;
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

  static String _sanitizeName(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '')
        .replaceAll(RegExp(r'-{2,}'), '-');
  }

  void _commitRename(String name) {
    final clean = _sanitizeName(name).replaceAll(RegExp(r'^-+|-+$'), '');
    if (clean.isEmpty) {
      setState(() => _errorText = "name can't be empty");
      return;
    }
    final siblings =
        widget.workflows.where((w) => w.id != widget.workflow.id).map((w) => w.name.toLowerCase());
    if (siblings.contains(clean.toLowerCase())) {
      setState(() => _errorText = 'name already in use');
      return;
    }
    if (clean != widget.workflow.name) {
      final id = widget.workflow.id;
      ref.read(workflowsProvider.notifier).update((list) {
        return list.map((w) => w.id == id ? w.copyWith(name: clean) : w).toList();
      });
      final current = ref.read(workflowProvider);
      if (current.id == id) {
        ref.read(workflowProvider.notifier).state = current.copyWith(name: clean);
      }
    }
    setState(() {
      _isEditing = false;
      _errorText = null;
    });
  }

  void _cancelRename() {
    _editCtrl.text = widget.workflow.name;
    setState(() {
      _isEditing = false;
      _errorText = null;
    });
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

  void _commitRowRename(String id, String name) {
    final clean = _sanitizeName(name).replaceAll(RegExp(r'^-+|-+$'), '');
    if (clean.isEmpty) return;
    final siblings = widget.workflows
        .where((w) => w.id != id)
        .map((w) => w.name.toLowerCase());
    if (siblings.contains(clean.toLowerCase())) return;
    ref.read(workflowsProvider.notifier).update((list) {
      return list.map((w) => w.id == id ? w.copyWith(name: clean) : w).toList();
    });
    final current = ref.read(workflowProvider);
    if (current.id == id) {
      ref.read(workflowProvider.notifier).state = current.copyWith(name: clean);
    }
    setState(() => _editingRowId = null);
  }

  void _cancelRowRename() {
    setState(() => _editingRowId = null);
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) {
        // Always show row actions on touch devices; hover-only on desktop.
        // Flutter web/desktop always reports hover capable, so default false.
        const touch = false; // TODO: detect coarse pointer for mobile builds
        return Stack(
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, -6 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
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
                                'SWITCH WORKFLOW \u00b7 ${widget.workflows.length}',
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
                            if (_editingRowId == wf.id) {
                              final siblings = widget.workflows
                                  .where((w) => w.id != wf.id)
                                  .map((w) => w.name.toLowerCase())
                                  .toList();
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                child: _InlineRename(
                                  initial: wf.name,
                                  siblings: siblings,
                                  big: false,
                                  onCommit: (name) => _commitRowRename(wf.id, name),
                                  onCancel: _cancelRowRename,
                                ),
                              );
                            }
                            return _WorkflowMenuRow(
                              workflow: wf,
                              active: wf.id == widget.activeWfId,
                              touch: touch,
                              onPick: () => _pick(wf.id),
                              onStartRename: () => setState(() => _editingRowId = wf.id),
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
            ),
          ],
        );
      },
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
    final siblingNames = widget.workflows
        .where((w) => w.id != wf.id)
        .map((w) => w.name.toLowerCase())
        .toList();

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 288,
        decoration: BoxDecoration(
          color: AppColors.bg1,
          border: Border.all(
            color: _open ? AppColors.accent : AppColors.border2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isEditing
            ? Padding(
                padding: const EdgeInsets.all(5),
                child: _InlineRename(
                  initial: wf.name,
                  siblings: siblingNames,
                  big: true,
                  onCommit: (name) => _commitRename(name),
                  onCancel: _cancelRename,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _toggle,
                      onDoubleTap: _enterEditMode,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
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
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _open ? 0.5 : 0,
                              duration: const Duration(milliseconds: 160),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: AppColors.fg2,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
                  GestureDetector(
                    onTap: _enterEditMode,
                    child: Container(
                      width: 38,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.border1),
                        ),
                      ),
                      child: Center(
                        child: TrailheadIcon(
                          icon: TrailheadIconData.pencil,
                          size: 13,
                          color: AppColors.fg2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InlineRename extends StatefulWidget {
  final String initial;
  final List<String> siblings;
  final bool big;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  const _InlineRename({
    required this.initial,
    required this.siblings,
    this.big = false,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<_InlineRename> createState() => _InlineRenameState();
}

class _InlineRenameState extends State<_InlineRename> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _ctrl.text.length,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _sanitize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _commit() {
    if (_committed) return;
    final clean = _sanitize(_ctrl.text);
    final empty = clean.isEmpty;
    final dupe = widget.siblings.any((n) => n.toLowerCase() == clean.toLowerCase());
    if (empty || dupe) return;
    _committed = true;
    widget.onCommit(clean);
  }

  void _cancel() {
    if (_committed) return;
    _committed = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final clean = _sanitize(_ctrl.text);
    final empty = clean.isEmpty;
    final dupe = widget.siblings.any((n) => n.toLowerCase() == clean.toLowerCase());
    final invalid = empty || dupe;
    final err = empty
        ? "name can't be empty"
        : dupe
            ? 'name already in use'
            : '';

    final fontSize = widget.big ? 13.0 : 11.5;
    final fontWeight = widget.big ? FontWeight.w600 : FontWeight.w500;
    final padding = widget.big
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.escape) {
                      _cancel();
                    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                      if (!invalid) _commit();
                    }
                  }
                },
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => invalid ? null : _commit(),
                  onTapOutside: (_) => invalid ? _cancel() : _commit(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: AppColors.fg0,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: padding,
                    filled: true,
                    fillColor: AppColors.bg0,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: invalid ? AppColors.danger : AppColors.accent,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: invalid ? AppColors.danger : AppColors.accent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: invalid ? AppColors.danger : AppColors.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            _RenameIconBtn(
              icon: TrailheadIconData.check,
              primary: true,
              disabled: invalid,
              onTap: invalid ? null : _commit,
            ),
            const SizedBox(width: 4),
            _RenameIconBtn(
              icon: TrailheadIconData.x,
              primary: false,
              onTap: _cancel,
            ),
          ],
        ),
        if (invalid && _ctrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              err,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9.5,
                color: AppColors.danger,
              ),
            ),
          ),
      ],
    );
  }
}

class _RenameIconBtn extends StatelessWidget {
  final TrailheadIconData icon;
  final bool primary;
  final bool disabled;
  final VoidCallback? onTap;

  const _RenameIconBtn({
    required this.icon,
    this.primary = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? (disabled ? AppColors.bg2 : AppColors.accent.withValues(alpha: 0.15))
        : AppColors.bg2;
    final fg = primary
        ? (disabled ? AppColors.fg3 : AppColors.accent)
        : AppColors.fg2;
    final borderColor = primary && !disabled
        ? AppColors.accent.withValues(alpha: 0.35)
        : AppColors.border1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: TrailheadIcon(
            icon: icon,
            size: 14,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _WorkflowMenuRow extends StatefulWidget {
  final WorkflowSummary workflow;
  final bool active;
  final bool touch;
  final VoidCallback onPick;
  final VoidCallback? onStartRename;
  final VoidCallback onDelete;

  const _WorkflowMenuRow({
    required this.workflow,
    required this.active,
    this.touch = false,
    required this.onPick,
    this.onStartRename,
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
    final showActions = widget.touch || _hovering;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onPick,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? AppColors.bg3
                        : _hovering
                            ? AppColors.bg2
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
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
                                fontWeight: widget.active
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: widget.active
                                    ? AppColors.fg0
                                    : AppColors.fg1,
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
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Row(
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
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: showActions ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 140),
              child: IgnorePointer(
                ignoring: !showActions,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onStartRename != null)
                      GestureDetector(
                        onTap: widget.onStartRename,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            border: Border.all(color: AppColors.border1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: TrailheadIcon(
                              icon: TrailheadIconData.pencil,
                              size: 13,
                              color: AppColors.fg2,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.bg3,
                          border: Border.all(color: AppColors.border1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: TrailheadIcon(
                            icon: TrailheadIconData.trash,
                            size: 13,
                            color: AppColors.fg2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
