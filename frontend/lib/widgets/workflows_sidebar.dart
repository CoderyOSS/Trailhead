import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../models/workflow_document.dart';
import '../providers/canvas_controller.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart';
import '../models/workflow_node.dart';
import 'app_button.dart';
import 'status_tag.dart';
import 'mode_rail.dart';
import 'icons.dart';

class WorkflowsSidebar extends ConsumerWidget {
  final String? activeId;
  final ValueChanged<String> onPick;

  const WorkflowsSidebar({
    super.key,
    this.activeId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflows = ref.watch(workflowsProvider);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(
          right: BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            count: workflows.length,
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
              ref.read(modeProvider.notifier).state = AppMode.build;
            },
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: workflows.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    child: Text(
                      'ALL',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.08,
                        color: AppColors.fg3,
                      ),
                    ),
                  );
                }
                final wf = workflows[i - 1];
                return _WorkflowRow(
                  workflow: wf,
                  active: wf.id == activeId,
                  onTap: () => onPick(wf.id),
                  onDelete: () {
                    final updated = ref.read(workflowsProvider).where((w) => w.id != wf.id).toList();
                    ref.read(workflowsProvider.notifier).state = updated;
                    if (wf.id == activeId && updated.isNotEmpty) {
                      ref.read(workflowProvider.notifier).state = updated.first;
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _commaFormat(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onNew;

  const _Header({required this.count, required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workflows',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.fg0,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'edit plans \u00b7 $count total',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: AppColors.fg2,
            ),
          ),
          const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'new workflow',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onTap: onNew,
              ),
            ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  final double progress;

  const _DeleteBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.only(right: 16),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.85 + clamped * 0.15,
            child: TrailheadIcon(
              icon: TrailheadIconData.trash,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Opacity(
            opacity: clamped,
            child: const Text(
              'delete',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowRow extends StatefulWidget {
  final WorkflowSummary workflow;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _WorkflowRow({
    required this.workflow,
    required this.active,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_WorkflowRow> createState() => _WorkflowRowState();
}

class _WorkflowRowState extends State<_WorkflowRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final wf = widget.workflow;
    final isActive = widget.active;

    Color bg;
    if (isActive) {
      bg = AppColors.bg3;
    } else if (_hovering) {
      bg = AppColors.bg2;
    } else {
      bg = Colors.transparent;
    }

    return Dismissible(
      key: ValueKey(wf.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      background: const _DeleteBackground(progress: 1.0),
      onDismissed: (_) => widget.onDelete?.call(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wf.name,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive ? AppColors.fg0 : AppColors.fg1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${_commaFormat(wf.runCount)} runs \u00b7 last ${wf.last}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
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
                          ],
                        ),
                    ],
                  ),
                ),
                if (isActive)
                  Positioned(
                    left: -6,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
