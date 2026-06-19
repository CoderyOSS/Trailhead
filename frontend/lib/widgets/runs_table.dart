import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../providers/mock_data.dart';
import '../providers/mode_provider.dart';
import 'status_tag.dart';
import 'view_toggle.dart';

class RunsTable extends ConsumerWidget {
  const RunsTable({super.key});

  static const _historyStatuses = <JobState>{
    JobState.passed,
    JobState.failed,
    JobState.cancelled,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allJobs = ref.watch(jobsProvider);
    final jobs = allJobs.where((j) => _historyStatuses.contains(j.state)).toList();
    final viewMode = ref.watch(runsTableViewModeProvider);
    final activeId = ref.watch(selectedJobProvider)?.id;

    final groups = _groupByWorkflow(jobs);

    return Container(
      color: AppColors.bg0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            count: jobs.length,
            viewMode: viewMode,
            onViewMode: (v) => ref.read(runsTableViewModeProvider.notifier).state = v,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TableHeader(),
                  if (viewMode == 'grouped')
                    ...groups.expand((g) => [
                      _GroupRow(name: g.name, count: g.items.length),
                      ...g.items.map((j) => _JobRow(
                        job: j,
                        active: j.id == activeId,
                        onTap: () => ref.read(selectedJobProvider.notifier).state = j,
                      )),
                    ])
                  else
                    ...jobs.map((j) => _JobRow(
                      job: j,
                      active: j.id == activeId,
                      onTap: () => ref.read(selectedJobProvider.notifier).state = j,
                    )),
                ],
              ),
            ),
          ),
          _Footer(count: jobs.length),
        ],
      ),
    );
  }

  List<_Group> _groupByWorkflow(List<JobSummary> jobs) {
    final m = <String, List<JobSummary>>{};
    for (final j in jobs) {
      final w = j.workflow ?? 'unknown';
      m.putIfAbsent(w, () => []).add(j);
    }
    return m.entries.map((e) => _Group(name: e.key, items: e.value)).toList();
  }
}

class _Group {
  final String name;
  final List<JobSummary> items;

  _Group({required this.name, required this.items});
}

class _Header extends StatelessWidget {
  final int count;
  final String viewMode;
  final ValueChanged<String> onViewMode;

  const _Header({
    required this.count,
    required this.viewMode,
    required this.onViewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border1),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Past jobs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fg0,
                  letterSpacing: -0.01 * 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count runs \u00b7 last 24h',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.fg2,
                ),
              ),
            ],
          ),
          const Spacer(),
          _Pill(label: 'all', count: count, active: true),
          const SizedBox(width: 8),
          _Pill(label: 'passed', count: 4),
          const SizedBox(width: 8),
          _Pill(label: 'failed', count: 1),
          const SizedBox(width: 8),
          _Pill(label: 'cancelled', count: 1),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 18,
            color: AppColors.border1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          const SizedBox(width: 8),
          ViewToggle(
            value: viewMode,
            onChange: onViewMode,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final int count;
  final bool active;

  const _Pill({
    required this.label,
    required this.count,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.bg3 : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.border3 : AppColors.border1,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: active ? AppColors.fg0 : AppColors.fg2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const headers = ['', 'run id', 'input', 'status', 'started', 'duration', 'tokens', 'cost', 'by'];
    return Container(
      decoration: BoxDecoration(color: AppColors.bg1),
      child: Row(
        children: headers.asMap().entries.map((e) {
          final flex = _colFlex(e.key);
          return Expanded(
            flex: flex,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: e.key == 0 ? Alignment.center : Alignment.centerLeft,
              child: Text(
                e.value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 0.06 * 10,
                  color: AppColors.fg3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final String name;
  final int count;

  const _GroupRow({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(
          bottom: BorderSide(color: AppColors.border1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.fg3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
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
              fontSize: 11,
              color: AppColors.fg2,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobRow extends StatefulWidget {
  final JobSummary job;
  final bool active;
  final VoidCallback onTap;

  const _JobRow({
    required this.job,
    required this.active,
    required this.onTap,
  });

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final mins = job.elapsedSec ~/ 60;
    final secs = job.elapsedSec % 60;
    final durStr = job.elapsedSec > 0 ? '${mins}m${secs.toString().padLeft(2, '0')}s' : '';
    final tokStr = job.tokens > 0 ? '${(job.tokens / 1000).toStringAsFixed(1)}k' : '';

    Color bg;
    if (widget.active) {
      bg = AppColors.bg2;
    } else if (_hovering) {
      bg = AppColors.bg2;
    } else {
      bg = Colors.transparent;
    }

    final cells = <Widget>[
      _cell(
        0,
        Alignment.center,
        StatusDot(
          status: job.state,
          pulse: job.state == JobState.running,
          size: 6,
        ),
      ),
      _cell(
        1,
        Alignment.centerLeft,
        Text(
          job.id,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.fg0,
          ),
        ),
      ),
      _cell(
        2,
        Alignment.centerLeft,
        Text(
          job.input ?? '',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            color: AppColors.fg1,
          ),
        ),
      ),
      _cell(
        3,
        Alignment.centerLeft,
        StatusTag(status: job.state),
      ),
      _cell(
        4,
        Alignment.centerLeft,
        Text(
          job.started,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.fg1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      _cell(
        5,
        Alignment.centerLeft,
        Text(
          durStr,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.fg1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      _cell(
        6,
        Alignment.centerLeft,
        Text(
          tokStr,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.fg2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      _cell(
        7,
        Alignment.centerLeft,
        Text(
          job.costUsd > 0 ? '\$${job.costUsd.toStringAsFixed(2)}' : '',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.fg1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      _cell(
        8,
        Alignment.centerLeft,
        Text(
          job.by ?? '',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.fg2,
          ),
        ),
      ),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              bottom: BorderSide(color: AppColors.border1),
            ),
          ),
          child: Row(
            children: cells.asMap().entries.map((e) {
              return Expanded(
                flex: _colFlex(e.key),
                child: e.value,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _cell(int index, Alignment alignment, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: alignment,
      child: child,
    );
  }
}

int _colFlex(int index) {
  return switch (index) {
    0 => 1,
    1 => 3,
    2 => 4,
    3 => 3,
    4 => 2,
    5 => 2,
    6 => 2,
    7 => 2,
    8 => 2,
    _ => 1,
  };
}

class _Footer extends StatelessWidget {
  final int count;

  const _Footer({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      alignment: Alignment.center,
      child: Text(
        'showing $count of $count \u00b7 no search yet',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: AppColors.fg2,
        ),
      ),
    );
  }
}
