import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart';
import 'status_tag.dart';
import 'icons.dart';

enum JobsSidebarKind { active, history }

const _activeStatuses = <JobState>{
  JobState.running,
  JobState.paused,
  JobState.queued,
  JobState.retrying,
};

const _historyStatuses = <JobState>{
  JobState.passed,
  JobState.failed,
  JobState.cancelled,
};

class JobsSidebar extends ConsumerWidget {
  final JobsSidebarKind kind;
  final String? activeId;
  final ValueChanged<String> onPick;

  JobsSidebar({
    super.key,
    required this.kind,
    this.activeId,
    required this.onPick,
  });

  bool _isRelevant(JobState s) {
    return kind == JobsSidebarKind.active
        ? _activeStatuses.contains(s)
        : _historyStatuses.contains(s);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allJobs = ref.watch(jobsProvider);
    final jobs = allJobs.where((j) => _isRelevant(j.state)).toList();
    final viewMode = ref.watch(sidebarViewModeProvider);

    return Container(
      width: 260,
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
            kind: kind,
            count: jobs.length,
            viewMode: viewMode,
            onViewModeChanged: (v) =>
                ref.read(sidebarViewModeProvider.notifier).state = v,
          ),
          Expanded(
            child: jobs.isEmpty
                ? _EmptyState(kind: kind)
                : viewMode == 'grouped'
                    ? _GroupedView(
                        jobs: jobs,
                        kind: kind,
                        activeId: activeId,
                        onPick: onPick,
                        onDelete: (id) {
                          ref.read(jobsProvider.notifier).update((list) =>
                              list.where((j) => j.id != id).toList());
                          if (id == activeId) {
                            ref.read(selectedJobProvider.notifier).state = null;
                          }
                        },
                      )
                    : _FlatView(
                        jobs: jobs,
                        activeId: activeId,
                        onPick: onPick,
                        onDelete: (id) {
                          ref.read(jobsProvider.notifier).update((list) =>
                              list.where((j) => j.id != id).toList());
                          if (id == activeId) {
                            ref.read(selectedJobProvider.notifier).state = null;
                          }
                        },
                      ),
          ),
          _Footer(kind: kind, count: jobs.length),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final JobsSidebarKind kind;
  final int count;
  final String viewMode;
  final ValueChanged<String> onViewModeChanged;

  _Header({
    required this.kind,
    required this.count,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = kind == JobsSidebarKind.active ? 'Active jobs' : 'History';
    final subtitle = kind == JobsSidebarKind.active
        ? '$count running \u00b7 paused \u00b7 queued'
        : '$count completed \u00b7 last 24h';

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
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.fg0,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: AppColors.fg2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ViewToggle(
                value: viewMode,
                onChanged: onViewModeChanged,
              ),
              if (kind == JobsSidebarKind.history) ...[
                const SizedBox(width: 6),
                _FilterButton(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  _ViewToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('grouped', TrailheadIconData.workflow, value == 'grouped'),
          _toggleBtn('flat', TrailheadIconData.file, value == 'flat'),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, TrailheadIconData icon, bool active) {
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.bg4 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TrailheadIcon(
              icon: icon,
              size: 10,
              color: active ? AppColors.accent : AppColors.fg2,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                color: active ? AppColors.fg0 : AppColors.fg2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TrailheadIcon(
            icon: TrailheadIconData.settings,
            size: 10,
            color: AppColors.fg2,
          ),
          const SizedBox(width: 4),
          Text(
            'filter',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: AppColors.fg2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final JobsSidebarKind kind;

  _EmptyState({required this.kind});

  @override
  Widget build(BuildContext context) {
    final msg = kind == JobsSidebarKind.active
        ? 'no active jobs \u2014 start one from the Build view'
        : 'no past jobs yet';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.fg3,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  final double progress;

  _DeleteBackground({required this.progress});

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

class _Footer extends StatelessWidget {
  final JobsSidebarKind kind;
  final int count;

  _Footer({required this.kind, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'showing $count',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: AppColors.fg3,
            ),
          ),
          if (kind == JobsSidebarKind.active)
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
                  'live',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.fg3,
                  ),
                ),
              ],
            )
          else
            Text(
              'no search yet',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.fg3,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Grouped view ─────────────────────────────────────────────────────────

class _GroupedView extends StatelessWidget {
  final List<JobSummary> jobs;
  final JobsSidebarKind kind;
  final String? activeId;
  final ValueChanged<String> onPick;
  final ValueChanged<String>? onDelete;

  _GroupedView({
    required this.jobs,
    required this.kind,
    required this.activeId,
    required this.onPick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<JobSummary>>{};
    for (final j in jobs) {
      final key = j.workflow ?? 'unknown';
      groups.putIfAbsent(key, () => []).add(j);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final entry = groups.entries.elementAt(gi);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(name: entry.key, count: entry.value.length),
            ...entry.value.map(
              (j) => _JobRowGrouped(
                job: j,
                active: j.id == activeId,
                onTap: () => onPick(j.id),
                onDelete: onDelete != null ? () => onDelete!(j.id) : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String name;
  final int count;

  _GroupHeader({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 8, 6, 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          TrailheadIcon(
            icon: TrailheadIconData.chevRight,
            size: 9,
            color: AppColors.fg3,
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.fg0,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: AppColors.fg3,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobRowGrouped extends StatefulWidget {
  final JobSummary job;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  _JobRowGrouped({
    required this.job,
    required this.active,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_JobRowGrouped> createState() => _JobRowGroupedState();
}

class _JobRowGroupedState extends State<_JobRowGrouped> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
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
      key: ValueKey(j.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      background: _DeleteBackground(progress: 1.0),
      onDismissed: (_) => widget.onDelete?.call(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Container(
            margin: const EdgeInsets.fromLTRB(18, 1, 6, 1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      StatusDot(
                        status: j.state,
                        pulse: j.state == JobState.running,
                        size: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: j.input ?? j.id,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  color: isActive ? AppColors.fg0 : AppColors.fg1,
                                ),
                              ),
                              TextSpan(
                                text: ' ${j.id.substring(2, 9)}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.fg3,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        j.started,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.fg3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Positioned(
                    left: -18,
                    top: 6,
                    bottom: 6,
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

// ── Flat view ────────────────────────────────────────────────────────────

class _FlatView extends StatelessWidget {
  final List<JobSummary> jobs;
  final String? activeId;
  final ValueChanged<String> onPick;
  final ValueChanged<String>? onDelete;

  _FlatView({
    required this.jobs,
    required this.activeId,
    required this.onPick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: jobs.length,
      itemBuilder: (context, i) {
        final j = jobs[i];
        return _JobRowFlat(
          job: j,
          active: j.id == activeId,
          onTap: () => onPick(j.id),
          onDelete: onDelete != null ? () => onDelete!(j.id) : null,
        );
      },
    );
  }
}

class _JobRowFlat extends StatefulWidget {
  final JobSummary job;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  _JobRowFlat({
    required this.job,
    required this.active,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_JobRowFlat> createState() => _JobRowFlatState();
}

class _JobRowFlatState extends State<_JobRowFlat> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
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
      key: ValueKey(j.id),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      background: _DeleteBackground(progress: 1.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StatusDot(
                        status: j.state,
                        pulse: j.state == JobState.running,
                        size: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              j.input ?? j.id,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: isActive ? AppColors.fg0 : AppColors.fg1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                _WorkflowTag(name: j.workflow ?? ''),
                                const SizedBox(width: 5),
                                Text(
                                  j.id.substring(2, 9),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    color: AppColors.fg3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        j.started,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.fg3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Positioned(
                    left: -6,
                    top: 7,
                    bottom: 7,
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

class _WorkflowTag extends StatelessWidget {
  final String name;

  _WorkflowTag({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.fg3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              color: AppColors.fg2,
            ),
          ),
        ],
      ),
    );
  }
}
