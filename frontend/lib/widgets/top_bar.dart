import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../providers/api_provider.dart';
import '../providers/drawer_provider.dart';
import '../providers/flow_tabs_provider.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart' show WorkflowSummary;
import '../providers/carta_provider.dart';
import '../utils/workflow_to_yaml.dart';
import '../utils/yaml_to_workflow.dart';
import '../services/jobs_api.dart';
import '../models/job_state.dart';
import 'icons.dart';
import 'app_button.dart';
import 'status_tag.dart';
import 'mode_rail.dart';
import 'topbar/flow_tab_strip.dart';

class TopBar extends ConsumerWidget {
  TopBar({super.key});

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

class _BuildBar extends ConsumerWidget {
  _BuildBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wf = ref.watch(workflowProvider);
    final workflows = ref.watch(workflowsProvider);
    final yamlOpen = ref.watch(yamlDrawerOpenProvider);
    final dirty = ref.watch(workflowDirtyProvider);
    final remoteAsync = ref.watch(remoteWorkflowsProvider);
    final isEmpty = wf.id == emptyWorkflowId;
    final isSubflowTab =
        ref.watch(activeTabKindProvider) == FlowTabKind.subflow;

    // Reconciles flow tabs with the remote list + persisted flow_order, and
    // binds the first tab on initial load.
    ref.watch(flowTabSyncProvider);

    // Loading state: backend fetch in progress, no real workflow yet.
    if (isEmpty && remoteAsync.isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'loading workflows…',
            style: TextStyle(color: AppColors.fg2, fontSize: 12),
          ),
        ],
      );
    }

    // Error state: backend unreachable.
    if (remoteAsync.hasError && workflows.isEmpty) {
      return Row(
        children: [
          CartaIcon(
            icon: CartaIconData.x,
            size: 14,
            color: AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'backend unreachable: ${remoteAsync.error}',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            icon: CartaIconData.copy,
            label: 'retry',
            onTap: () { ref.invalidate(remoteWorkflowDtosProvider); },
          ),
        ],
      );
    }

    // Empty state: no workflows yet.
    if (isEmpty && workflows.isEmpty) {
      return Row(
        children: [
          AppButton(
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            icon: CartaIconData.plus,
            label: 'create your first workflow',
            onTap: () => createUntitledFlow(ref),
          ),
        ],
      );
    }

    if (isEmpty) {
      // Workflows exist but none selected — show picker prompt.
      return Row(
        children: [
          AppButton(
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            label: 'pick a workflow',
            onTap: () {
              final tabs = ref.read(flowTabsProvider);
              if (tabs.isNotEmpty) {
                switchToTab(ref, tabs.first);
              } else if (workflows.isNotEmpty) {
                ref.read(workflowProvider.notifier).state = workflows.first;
              }
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(child: FlowTabStrip()),
        if (dirty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'saving…',
              style: TextStyle(color: AppColors.fg2, fontSize: 11),
            ),
          ),
        AppButton(
          variant: yamlOpen ? AppButtonVariant.secondary : AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          icon: CartaIconData.file,
          label: 'YAML',
          onTap: () {
            ref.read(yamlDrawerOpenProvider.notifier).state = !yamlOpen;
          },
        ),
        const SizedBox(width: 8),
        // Unified drawer (settings + logs) toggle.
        AppButton(
          variant: ref.watch(drawerOpenProvider)
              ? AppButtonVariant.secondary
              : AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          icon: CartaIconData.panelRight,
          label: 'panel',
          onTap: () {
            final open = ref.read(drawerOpenProvider);
            ref.read(drawerOpenProvider.notifier).state = !open;
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
        // Subflows aren't deployable on their own — no launch on subflow tabs.
        if (!isSubflowTab)
          AppButton(
            variant: AppButtonVariant.trail,
            size: AppButtonSize.sm,
            icon: CartaIconData.play,
            label: 'launch',
            onTap: () async {
            try {
              final yaml = workflowToYaml(wf);
              // Gate: server-side validation first — a bad flow must not be
              // persisted or launched. Blocks with a readable error list.
              final errors = await ref
                  .read(cartaApiProvider)
                  .validateWorkflow(content: yaml);
              if (errors.isNotEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'invalid workflow:\n${errors.take(3).join('\n')}',
                      ),
                    ),
                  );
                }
                return;
              }
              await ref.read(workflowsApiProvider).replace(wf.name, yaml);
              final jobsApi = ref.read(jobsApiProvider);
              final job = await jobsApi.create(wf.name);
              ref.invalidate(jobsProvider);
              // Snapshot the launched workflow as the job's independent
              // document — Active-mode edits never touch the workflow.
              ref.read(jobDocumentsProvider.notifier).update((docs) {
                final m = Map<String, WorkflowSummary>.from(docs);
                m[job.id] = wf;
                return m;
              });
              ref.read(selectedJobProvider.notifier).state = job;
              ref.read(modeProvider.notifier).state = AppMode.active;
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('launch failed: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

class _HistoryListBar extends ConsumerWidget {
  _HistoryListBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsProvider);
    final count = jobsAsync.maybeWhen(data: (list) => list.length, orElse: () => 0);

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
              '$count runs \u00b7 last 24h',
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
          icon: CartaIconData.refresh,
          label: 'refresh',
          onTap: () => ref.invalidate(jobsProvider),
        ),
      ],
    );
  }
}

class _JobBar extends StatelessWidget {
  final JobDto? job;
  final AppMode mode;
  final bool yamlOpen;
  final VoidCallback onToggleYaml;
  final VoidCallback onClearJob;

  _JobBar({
    required this.job,
    required this.mode,
    required this.yamlOpen,
    required this.onToggleYaml,
    required this.onClearJob,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == AppMode.active) {
      // Active bar: job dropdown on the left; YAML + stop/reload on the
      // right; running-status chip on a second row under the controls.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _JobSelect(job: job),
              const Spacer(),
              AppButton(
                variant: yamlOpen
                    ? AppButtonVariant.secondary
                    : AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                icon: CartaIconData.file,
                label: 'YAML',
                onTap: onToggleYaml,
              ),
              if (job != null) ...[
                const SizedBox(width: 6),
                _JobControls(job: job!),
              ],
            ],
          ),
          if (job != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                StatusTag(status: job!.jobState),
              ],
            ),
          ],
        ],
      );
    }

    // History mode.
    if (job == null) {
      return Row(
        children: [
          Text(
            'select a past job  or browse the table',
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

class _JobRow1 extends ConsumerWidget {
  final JobDto job;
  final AppMode mode;
  final bool yamlOpen;
  final VoidCallback onToggleYaml;
  final VoidCallback onClearJob;

  _JobRow1({
    required this.job,
    required this.mode,
    required this.yamlOpen,
    required this.onToggleYaml,
    required this.onClearJob,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: CartaIcon(
                    icon: CartaIconData.chevRight,
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
            job.flowName,
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
        StatusTag(status: job.jobState),
        const Spacer(),
      ],
    );
  }
}

class _JobRow2 extends StatelessWidget {
  final JobDto job;

  _JobRow2({required this.job});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Row(
        children: [
          Text(
            job.flowName,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Text(
            '\u00b7',
            style: TextStyle(color: AppColors.border2),
          ),
          const SizedBox(width: 8),
          Text(
            '${job.nodeCount} nodes',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\u00b7',
            style: TextStyle(color: AppColors.border2),
          ),
          const SizedBox(width: 8),
          Text(
            job.startedAt,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg2,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobControls extends ConsumerWidget {
  final JobDto job;

  _JobControls({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          if (job.jobState == JobState.running)
            _CtrlBtn(
              onTap: () => _cancelJob(context, ref, job.id),
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
          if (job.jobState == JobState.running)
            _CtrlBtn(
              onTap: () => _reloadJob(context, ref, job),
              label: 'reload',
              icon: CartaIcon(
                icon: CartaIconData.refresh,
                size: 11,
                color: AppColors.fg0,
              ),
            )
          else
            _CtrlBtn(
              onTap: () {
                ref.invalidate(jobsProvider);
                ref.read(autoRefreshJobsProvider.notifier).state++;
              },
              icon: CartaIcon(
                icon: CartaIconData.refresh,
                size: 11,
                color: AppColors.fg0,
              ),
            ),
        ],
      ),
    );
  }

  /// Kill the job, re-sync it to the current stored workflow, and relaunch.
  /// The new job gets a fresh snapshot parsed from the YAML Carta redeploys;
  /// the old job's snapshot (with any Active-mode edits) is discarded.
  void _reloadJob(BuildContext context, WidgetRef ref, JobDto job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Reload job?', style: TextStyle(color: AppColors.fg0)),
        content: Text(
          'Stops this job and relaunches it from the current workflow. Unsaved job edits will be lost.',
          style: TextStyle(color: AppColors.fg2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('keep running'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(jobsApiProvider);
                await api.cancel(job.id);
                final newJob = await api.create(job.flowName);
                // Fresh snapshot from the YAML the new job deployed with.
                ref.read(jobDocumentsProvider.notifier).update((docs) {
                  final m = Map<String, WorkflowSummary>.from(docs)..remove(job.id);
                  final content = newJob.content;
                  if (content != null) {
                    try {
                      m[newJob.id] = yamlToWorkflow(newJob.flowName, content);
                    } catch (_) {}
                  }
                  return m;
                });
                ref.invalidate(jobsProvider);
                ref.read(selectedJobProvider.notifier).state = newJob;
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('reload failed: $e')),
                  );
                }
              }
            },
            child: Text('reload', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _cancelJob(BuildContext context, WidgetRef ref, String jobId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Cancel job?', style: TextStyle(color: AppColors.fg0)),
        content: Text('This will undeploy the flow and mark the job as cancelled.',
            style: TextStyle(color: AppColors.fg2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('keep running'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(jobsApiProvider);
                final cancelled = await api.cancel(jobId);
                ref.read(selectedJobProvider.notifier).state = cancelled;
                ref.invalidate(jobsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('stop failed: $e')),
                  );
                }
              }
            },
            child: Text('stop', style: TextStyle(color: AppColors.danger)),
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

  _CtrlBtn({
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

// ──────────────────────────────────────────────────────────────────────────
// Job selector dropdown (Active mode) — lists running jobs only.
// ──────────────────────────────────────────────────────────────────────────

class _JobSelect extends ConsumerStatefulWidget {
  final JobDto? job;

  _JobSelect({required this.job});

  @override
  ConsumerState<_JobSelect> createState() => _JobSelectState();
}

class _JobSelectState extends ConsumerState<_JobSelect> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _overlay?.remove();
    _overlay = null;
  }

  void _toggle(List<JobDto> running) {
    if (running.isEmpty) return;
    if (_open) {
      _close();
      return;
    }
    setState(() => _open = true);
    _overlay = _createOverlay(running);
    Overlay.of(context).insert(_overlay!);
  }

  void _pick(JobDto job) {
    ensureJobDocument(ref, job);
    ref.read(selectedJobProvider.notifier).state = job;
    _close();
  }

  OverlayEntry _createOverlay(List<JobDto> running) {
    return OverlayEntry(
      builder: (context) {
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
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        child: Text(
                          'RUNNING JOBS \u00b7 ${running.length}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.08,
                            color: AppColors.fg3,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.border1),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(4),
                          itemCount: running.length,
                          itemBuilder: (context, i) => _JobMenuRow(
                            job: running[i],
                            active: running[i].id == widget.job?.id,
                            onPick: () => _pick(running[i]),
                          ),
                        ),
                      ),
                    ],
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);
    final running = jobsAsync.maybeWhen(
      data: (list) =>
          list.where((j) => j.jobState == JobState.running).toList(),
      orElse: () => const <JobDto>[],
    );
    final enabled = running.isNotEmpty;
    final label = widget.job?.id ?? (enabled ? 'select job' : 'no running jobs');

    return CompositedTransformTarget(
      link: _layerLink,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          width: 288,
          decoration: BoxDecoration(
            color: AppColors.bg1,
            border: Border.all(
              color: _open ? AppColors.accent : AppColors.border2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTap: enabled ? () => _toggle(running) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.job != null
                            ? AppColors.fg0
                            : AppColors.fg2,
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
      ),
    );
  }
}

class _JobMenuRow extends StatefulWidget {
  final JobDto job;
  final bool active;
  final VoidCallback onPick;

  _JobMenuRow({
    required this.job,
    required this.active,
    required this.onPick,
  });

  @override
  State<_JobMenuRow> createState() => _JobMenuRowState();
}

class _JobMenuRowState extends State<_JobMenuRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPick,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.bg3 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.job.id,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.active ? AppColors.accent : AppColors.fg0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.job.flowName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.fg2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
