import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart';
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
    final isJobView =
        (mode == AppMode.active && job != null) ||
        (mode == AppMode.history && job != null);

    return Container(
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
                return const _BuildBar();
              case AppMode.active:
                return _JobBar(
                  job: job,
                  mode: mode,
                  onClearJob: () =>
                      ref.read(selectedJobProvider.notifier).state = null,
                );
              case AppMode.history:
                if (job == null) {
                  return const _HistoryListBar();
                }
                return _JobBar(
                  job: job,
                  mode: mode,
                  onClearJob: () =>
                      ref.read(selectedJobProvider.notifier).state = null,
                );
            }
          },
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final AppMode mode;

  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final meta = switch (mode) {
      AppMode.build => (
        label: 'BUILD',
        color: AppColors.fg0,
        bg: AppColors.bg3,
      ),
      AppMode.active => (
        label: 'ACTIVE',
        color: AppColors.accent,
        bg: AppColors.accent.withValues(alpha: 0.15),
      ),
      AppMode.history => (
        label: 'HISTORY',
        color: AppColors.fg2,
        bg: AppColors.bg3,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: meta.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: meta.color.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.10 * 9.5,
          color: meta.color,
          height: 1,
        ),
      ),
    );
  }
}

class _WorkflowGlyph extends StatelessWidget {
  const _WorkflowGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8b6914), Color(0xFF5a3e0a)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'wf',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFfbf3e6),
          height: 1,
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

    return Row(
      children: [
        const _ModeBadge(mode: AppMode.build),
        const SizedBox(width: 12),
        const _WorkflowGlyph(),
        const SizedBox(width: 9),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wf.name,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fg0,
                    height: 1.15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 6),
                Text(
                  'v${wf.version}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.fg2,
                    height: 1.15,
                  ),
                ),
                if (wf.draft != null && wf.draft != wf.version) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'draft v${wf.draft}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        color: AppColors.warning,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              wf.updated,
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
          icon: TrailheadIconData.copy,
          label: 'duplicate',
          onTap: () {},
        ),
        const SizedBox(width: 8),
        AppButton(
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
          icon: TrailheadIconData.file,
          label: 'YAML',
          onTap: () {},
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
        const _ModeBadge(mode: AppMode.history),
        const SizedBox(width: 12),
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
  final VoidCallback onClearJob;

  const _JobBar({
    required this.job,
    required this.mode,
    required this.onClearJob,
  });

  @override
  Widget build(BuildContext context) {
    if (job == null) {
      return Row(
        children: [
          _ModeBadge(mode: mode),
          const SizedBox(width: 12),
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
  final VoidCallback onClearJob;

  const _JobRow1({
    required this.job,
    required this.mode,
    required this.onClearJob,
  });

  @override
  Widget build(BuildContext context) {
    final tagState = job.state == JobState.paused
        ? JobState.cancelled
        : job.state;

    return Row(
      children: [
        _ModeBadge(mode: mode),
        const SizedBox(width: 10),
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
        if (mode == AppMode.active)
          _JobControls(state: job.state)
        else ...[
          AppButton(
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            icon: TrailheadIconData.file,
            label: 'YAML',
            onTap: () {},
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
                ? const _PauseIcon()
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
