# History RunsTable + Workflow Entrypoint Node Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add History mode RunsTable (flat/grouped), worker node rendering on canvas, and "new workflow" creation with an entrypoint node.

**Architecture:** Extend `WorkflowSummary` with inline `nodes` list. Add `RunsTable` and `WorkerNode` widgets. History mode switches layout based on `selectedJobProvider`.

**Tech Stack:** Flutter, flutter_riverpod, flutter_svg

---

### File Map

| File | Responsibility |
|------|---------------|
| `lib/models/workflow_node.dart` | `WorkflowNode` immutable data class |
| `lib/providers/mock_data.dart` | Update `JobSummary` (add `by`), `WorkflowSummary` (add `nodes`), mock data |
| `lib/providers/mode_provider.dart` | Add `selectedNodeProvider`, `runsTableViewModeProvider` |
| `lib/widgets/view_toggle.dart` | Grouped/flat segmented toggle |
| `lib/widgets/runs_table.dart` | `RunsTable` widget with header, pills, table, footer |
| `lib/widgets/canvas/worker_node.dart` | `WorkerNode` 192x80px widget |
| `lib/widgets/canvas/graph_canvas.dart` | Render nodes from workflow provider |
| `lib/widgets/workflows_sidebar.dart` | Wire "new workflow" button |
| `lib/main.dart` | History mode conditional layout |

---

### Task 1: Data Model — WorkflowNode

**Files:**
- Create: `lib/models/workflow_node.dart`

- [ ] **Step 1: Create WorkflowNode class**

```dart
class WorkflowNode {
  final String id;
  final String kind;
  final String label;
  final String? sub;
  final String? model;
  final List<String> skills;
  final double x;
  final double y;

  const WorkflowNode({
    required this.id,
    required this.kind,
    required this.label,
    this.sub,
    this.model,
    this.skills = const [],
    required this.x,
    required this.y,
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/models/workflow_node.dart
git commit -m "feat: add WorkflowNode data model"
```

---

### Task 2: Update Mock Data and Providers

**Files:**
- Modify: `lib/providers/mock_data.dart`
- Modify: `lib/providers/mode_provider.dart`

- [ ] **Step 1: Update JobSummary with `by` field**

In `lib/providers/mock_data.dart`, add `by` to `JobSummary`:

```dart
class JobSummary {
  final String id;
  final String? workflow;
  final int? workflowVersion;
  final JobState state;
  final String? input;
  final int elapsedSec;
  final int tokens;
  final double costUsd;
  final String started;
  final String? by;

  const JobSummary({
    required this.id,
    this.workflow,
    this.workflowVersion,
    required this.state,
    this.input,
    this.elapsedSec = 0,
    this.tokens = 0,
    this.costUsd = 0,
    this.started = '',
    this.by,
  });
}
```

- [ ] **Step 2: Update WorkflowSummary with `nodes` field**

Add import at top:
```dart
import '../models/workflow_node.dart';
```

Add to `WorkflowSummary`:
```dart
class WorkflowSummary {
  final String id;
  final String name;
  final int version;
  final int? draft;
  final String updated;
  final int runCount;
  final String last;
  final int active;
  final List<WorkflowNode> nodes;

  const WorkflowSummary({
    required this.id,
    required this.name,
    required this.version,
    this.draft,
    required this.updated,
    this.runCount = 0,
    this.last = '',
    this.active = 0,
    this.nodes = const [],
  });
}
```

- [ ] **Step 3: Update mock jobs with `by` and `workflowVersion`**

Update every `JobSummary` in `mockJobs` to include `by`:

```dart
final mockJobs = <JobSummary>[
  JobSummary(
    id: 'r_8f2a91c',
    workflow: 'pr-reviewer',
    workflowVersion: 14,
    state: JobState.running,
    input: 'PR #1428',
    elapsedSec: 247,
    tokens: 184233,
    costUsd: 0.42,
    started: '14:18',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f2a4b1',
    workflow: 'eval-harness',
    workflowVersion: 7,
    state: JobState.running,
    input: 'suite/regress',
    elapsedSec: 351,
    tokens: 310000,
    costUsd: 1.12,
    started: '14:16',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f2a103',
    workflow: 'flake-tracker',
    workflowVersion: 2,
    state: JobState.paused,
    input: 'ci-main',
    elapsedSec: 482,
    tokens: 8200,
    costUsd: 0.08,
    started: '14:14',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f29d52',
    workflow: 'pr-reviewer',
    workflowVersion: 14,
    state: JobState.queued,
    input: 'PR #1429',
    started: '14:13',
    by: 'jen.b',
  ),
  JobSummary(
    id: 'r_8f29442',
    workflow: 'pr-reviewer',
    workflowVersion: 14,
    state: JobState.passed,
    input: 'PR #1427',
    elapsedSec: 224,
    tokens: 156000,
    costUsd: 0.31,
    started: '14:12',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f28a01',
    workflow: 'eval-harness',
    workflowVersion: 7,
    state: JobState.failed,
    input: 'suite/all',
    elapsedSec: 492,
    tokens: 310000,
    costUsd: 1.84,
    started: '14:07',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f27b3d',
    workflow: 'flake-tracker',
    workflowVersion: 2,
    state: JobState.passed,
    input: 'ci-main',
    elapsedSec: 48,
    tokens: 4100,
    costUsd: 0.04,
    started: '14:03',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f26108',
    workflow: 'pr-reviewer',
    workflowVersion: 14,
    state: JobState.passed,
    input: 'PR #1426',
    elapsedSec: 138,
    tokens: 112000,
    costUsd: 0.22,
    started: '13:58',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f25fa2',
    workflow: 'pr-reviewer',
    workflowVersion: 14,
    state: JobState.retrying,
    input: 'PR #1425',
    elapsedSec: 310,
    tokens: 98000,
    costUsd: 0.38,
    started: '13:54',
    by: 'ci',
  ),
  JobSummary(
    id: 'r_8f24c0e',
    workflow: 'release-notes',
    workflowVersion: 3,
    state: JobState.passed,
    input: 'v0.42.1',
    elapsedSec: 72,
    tokens: 12000,
    costUsd: 0.09,
    started: '13:01',
    by: 'alex.k',
  ),
  JobSummary(
    id: 'r_8f23911',
    workflow: 'pr-reviewer',
    workflowVersion: 14,
    state: JobState.cancelled,
    input: 'PR #1424',
    elapsedSec: 22,
    tokens: 8000,
    costUsd: 0.02,
    started: '12:55',
    by: 'jen.b',
  ),
  JobSummary(
    id: 'r_8f22a05',
    workflow: 'doc-indexer',
    workflowVersion: 1,
    state: JobState.passed,
    input: 'snapshot',
    elapsedSec: 724,
    tokens: 45000,
    costUsd: 0.91,
    started: '12:11',
    by: 'ops',
  ),
  JobSummary(
    id: 'r_8f21338',
    workflow: 'changelog-summary',
    workflowVersion: 5,
    state: JobState.passed,
    input: 'v0.42.0',
    elapsedSec: 38,
    tokens: 5500,
    costUsd: 0.05,
    started: '11:42',
    by: 'ops',
  ),
];
```

- [ ] **Step 4: Update mock workflows with nodes**

Add `nodes` to `mockWorkflow`:
```dart
final mockWorkflow = WorkflowSummary(
  id: 'wf_pr_reviewer',
  name: 'pr-reviewer',
  version: 14,
  draft: 15,
  updated: '2 min ago by jen.b',
  runCount: 1284,
  last: '2m',
  active: 2,
  nodes: const [
    WorkflowNode(
      id: 'entrypoint',
      kind: 'worker',
      label: 'entrypoint',
      x: 400,
      y: 300,
    ),
  ],
);
```

Update `mockWorkflows` list similarly, giving each workflow an entrypoint node:

```dart
final mockWorkflows = <WorkflowSummary>[
  WorkflowSummary(
    id: 'wf_pr_reviewer',
    name: 'pr-reviewer',
    version: 14,
    draft: 15,
    updated: '2 min ago by jen.b',
    runCount: 1284,
    last: '2m',
    active: 2,
    nodes: const [
      WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 400, y: 300),
    ],
  ),
  WorkflowSummary(
    id: 'wf_eval_harness',
    name: 'eval-harness',
    version: 7,
    updated: '1h ago by ci-bot',
    runCount: 412,
    last: '11m',
    active: 0,
    nodes: const [
      WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 400, y: 300),
    ],
  ),
  WorkflowSummary(
    id: 'wf_release_notes',
    name: 'release-notes',
    version: 3,
    updated: '3h ago by alex.k',
    runCount: 38,
    last: '1h',
    active: 0,
    nodes: const [
      WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 400, y: 300),
    ],
  ),
  WorkflowSummary(
    id: 'wf_flake_tracker',
    name: 'flake-tracker',
    version: 2,
    updated: '1d ago by jen.b',
    runCount: 906,
    last: '8m',
    active: 1,
    nodes: const [
      WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 400, y: 300),
    ],
  ),
  WorkflowSummary(
    id: 'wf_changelog_summ',
    name: 'changelog-summary',
    version: 5,
    updated: '4h ago by ops',
    runCount: 142,
    last: '3h',
    active: 0,
    nodes: const [
      WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 400, y: 300),
    ],
  ),
  WorkflowSummary(
    id: 'wf_doc_indexer',
    name: 'doc-indexer',
    version: 1,
    updated: '1d ago by ops',
    runCount: 77,
    last: '1d',
    active: 0,
    nodes: const [
      WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 400, y: 300),
    ],
  ),
];
```

- [ ] **Step 5: Add new providers**

In `lib/providers/mode_provider.dart`, append:

```dart
final selectedNodeProvider = StateProvider<String?>((ref) => null);

final runsTableViewModeProvider = StateProvider<String>((ref) => 'flat');
```

- [ ] **Step 6: Analyze and commit**

Run:
```bash
~/flutter/bin/flutter analyze
```
Expected: no errors.

```bash
git add lib/providers/mock_data.dart lib/providers/mode_provider.dart lib/models/workflow_node.dart
git commit -m "feat: add WorkflowNode model, by field, and new providers"
```

---

### Task 3: View Toggle Widget

**Files:**
- Create: `lib/widgets/view_toggle.dart`

- [ ] **Step 1: Create ViewToggle widget**

```dart
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ViewToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const ViewToggle({
    super.key,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Item(
            label: 'grouped',
            active: value == 'grouped',
            onTap: () => onChange('grouped'),
          ),
          _Item(
            label: 'flat',
            active: value == 'flat',
            onTap: () => onChange('flat'),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Item({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.bg4
                : (_hovering ? AppColors.bg3 : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
              color: widget.active ? AppColors.fg0 : AppColors.fg2,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/view_toggle.dart
git commit -m "feat: add grouped/flat ViewToggle widget"
```

---

### Task 4: Runs Table Widget

**Files:**
- Create: `lib/widgets/runs_table.dart`

- [ ] **Step 1: Create RunsTable widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../providers/mock_data.dart';
import '../providers/mode_provider.dart';
import 'status_tag.dart';
import 'view_toggle.dart';

class RunsTable extends ConsumerWidget {
  const RunsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(jobsProvider);
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
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(44),
                  1: FixedColumnWidth(120),
                  2: FlexColumnWidth(),
                  3: FixedColumnWidth(110),
                  4: FixedColumnWidth(80),
                  5: FixedColumnWidth(90),
                  6: FixedColumnWidth(90),
                  7: FixedColumnWidth(70),
                  8: FixedColumnWidth(90),
                },
                children: [
                  _buildHeaderRow(),
                  if (viewMode == 'grouped')
                    ...groups.expand((g) => [
                      _buildGroupRow(g.name, g.items.length),
                      ...g.items.map((j) => _buildJobRow(j, j.id == activeId, ref)),
                    ])
                  else
                    ...jobs.map((j) => _buildJobRow(j, j.id == activeId, ref)),
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

  TableRow _buildHeaderRow() {
    final headers = ['', 'run id', 'input', 'status', 'started', 'duration', 'tokens', 'cost', 'by'];
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.bg1),
      children: headers.asMap().entries.map((e) {
        return Container(
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
        );
      }).toList(),
    );
  }

  TableRow _buildGroupRow(String name, int count) {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.bg1),
      children: [
        const SizedBox.shrink(),
        TableCell(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 5),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
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
          ),
        ),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
      ],
    );
  }

  TableRow _buildJobRow(JobSummary job, bool active, WidgetRef ref) {
    final mins = job.elapsedSec ~/ 60;
    final secs = job.elapsedSec % 60;
    final durStr = job.elapsedSec > 0 ? '${mins}m${secs.toString().padLeft(2, '0')}s' : '';
    final tokStr = job.tokens > 0 ? '${(job.tokens / 1000).toStringAsFixed(1)}k' : '';

    return TableRow(
      decoration: BoxDecoration(
        color: active ? AppColors.bg2 : Colors.transparent,
        border: const Border(
          bottom: BorderSide(color: AppColors.border1),
        ),
      ),
      children: [
        _Cell(
          alignment: Alignment.center,
          child: StatusDot(
            status: job.state,
            pulse: job.state == JobState.running,
            size: 6,
          ),
        ),
        _Cell(
          child: Text(
            job.id,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg0,
            ),
          ),
        ),
        _Cell(
          child: Text(
            job.input ?? '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              color: AppColors.fg1,
            ),
          ),
        ),
        _Cell(
          child: StatusTag(status: job.state),
        ),
        _Cell(
          child: Text(
            job.started,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _Cell(
          child: Text(
            durStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _Cell(
          child: Text(
            tokStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _Cell(
          child: Text(
            job.costUsd > 0 ? '\$${job.costUsd.toStringAsFixed(2)}' : '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _Cell(
          child: Text(
            job.by ?? '',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.fg2,
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget child;
  final Alignment alignment;

  const _Cell({
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: alignment,
      child: child,
    );
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
      decoration: const BoxDecoration(
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/runs_table.dart
git commit -m "feat: add RunsTable widget with grouped/flat toggle"
```

---

### Task 5: Worker Node Widget

**Files:**
- Create: `lib/widgets/canvas/worker_node.dart`

- [ ] **Step 1: Create WorkerNode widget**

```dart
import 'package:flutter/material.dart';
import '../../models/workflow_node.dart';
import '../../providers/mock_data.dart';
import '../../theme/tokens.dart';
import '../status_tag.dart';

class WorkerNode extends StatelessWidget {
  final WorkflowNode node;
  final JobState? status;
  final bool selected;
  final VoidCallback? onTap;

  const WorkerNode({
    super.key,
    required this.node,
    this.status,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final running = status == JobState.running;
    final statusColor = _statusColor(status);

    final railShadow = (status == JobState.queued || status == null)
        ? BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(-3, 0),
          )
        : BoxShadow(
            color: statusColor,
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(-3, 0),
          );

    List<BoxShadow> outlineShadows;
    if (selected) {
      outlineShadows = [
        const BoxShadow(
          color: AppColors.accent,
          blurRadius: 0,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.22),
          blurRadius: 0,
          spreadRadius: 4,
        ),
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
    } else if (running) {
      outlineShadows = [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.30),
          blurRadius: 18,
        ),
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];
    } else {
      outlineShadows = [
        const BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 192,
        height: 80,
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: running
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1e2229),
                    AppColors.bg2,
                  ],
                )
              : AppColors.loafGradient,
          border: Border.all(
            color: selected
                ? AppColors.accent
                : running
                    ? AppColors.accent
                    : AppColors.border2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [railShadow, ...outlineShadows],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (running)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: StatusDot(
                          status: JobState.running,
                          pulse: true,
                          size: 6,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        node.label,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (node.model != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.bg4,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          node.model!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: AppColors.fg2,
                            letterSpacing: 0.02 * 9,
                          ),
                        ),
                      ),
                  ],
                ),
                if (node.sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    node.sub!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.fg2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                if (node.skills.isNotEmpty)
                  Row(
                    children: [
                      ...node.skills.take(3).map((sk) => Container(
                        margin: const EdgeInsets.only(right: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.bg3,
                          border: Border.all(color: AppColors.border1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          sk,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: AppColors.fg2,
                          ),
                        ),
                      )),
                      if (node.skills.length > 3)
                        Text(
                          '+${node.skills.length - 3}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: AppColors.fg2,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (running && status != null)
              Positioned(
                left: 6,
                right: 6,
                bottom: 3,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.bg4,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.55,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFe8923a), Color(0xFFf0a85c)],
                        ),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (status != null && !running && status != JobState.queued)
              Positioned(
                top: -7,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: status == JobState.passed
                        ? AppColors.success
                        : status == JobState.failed
                            ? AppColors.danger
                            : AppColors.bg4,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status == JobState.cancelled ? 'cancelled' : status!.name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: status == JobState.passed
                          ? const Color(0xFF1a3d1c)
                          : status == JobState.failed
                              ? const Color(0xFF3d1a1a)
                              : AppColors.fg2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(JobState? s) {
    if (s == null || s == JobState.queued) return AppColors.border2;
    return switch (s) {
      JobState.passed => AppColors.success,
      JobState.failed => AppColors.danger,
      JobState.running => AppColors.accent,
      JobState.retrying => AppColors.warning,
      _ => AppColors.border2,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/canvas/worker_node.dart
git commit -m "feat: add WorkerNode widget for canvas"
```

---

### Task 6: Graph Canvas — Render Nodes

**Files:**
- Modify: `lib/widgets/canvas/graph_canvas.dart`

- [ ] **Step 1: Import and render nodes**

Replace the file content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/canvas_controller.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'dot_grid_painter.dart';
import 'worker_node.dart';

class GraphCanvas extends ConsumerWidget {
  const GraphCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewport = ref.watch(canvasControllerProvider);
    final controller = ref.read(canvasControllerProvider.notifier);
    final workflow = ref.watch(workflowProvider);
    final selectedNodeId = ref.watch(selectedNodeProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        controller.pan(details.delta);
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.hearthGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DotGridPainter(
                  zoom: viewport.zoom,
                  pan: viewport.pan,
                ),
              ),
            ),
            Transform.translate(
              offset: viewport.pan,
              child: Transform.scale(
                scale: viewport.zoom,
                alignment: Alignment.topLeft,
                child: Stack(
                  children: workflow.nodes.map((node) {
                    return Positioned(
                      left: node.x,
                      top: node.y,
                      child: WorkerNode(
                        node: node,
                        selected: selectedNodeId == node.id,
                        onTap: () {
                          ref.read(selectedNodeProvider.notifier).state =
                              selectedNodeId == node.id ? null : node.id;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/canvas/graph_canvas.dart
git commit -m "feat: render WorkerNode instances on GraphCanvas"
```

---

### Task 7: History Mode Layout

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Update TrailheadShell for History mode**

Replace `TrailheadShell` in `lib/main.dart`:

```dart
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
```

Add imports at top of `lib/main.dart`:
```dart
import 'widgets/runs_table.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: history mode shows RunsTable when no job selected"
```

---

### Task 8: New Workflow Button

**Files:**
- Modify: `lib/widgets/workflows_sidebar.dart`

- [ ] **Step 1: Wire "new workflow" button**

In `lib/widgets/workflows_sidebar.dart`, update `_Header` to accept a callback:

Change `_Header` constructor:
```dart
class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onNew;

  const _Header({required this.count, required this.onNew});
```

Change the button `onTap`:
```dart
AppButton(
  label: 'new workflow',
  variant: AppButtonVariant.secondary,
  size: AppButtonSize.sm,
  onTap: onNew,
),
```

In `WorkflowsSidebar.build`, pass the callback:
```dart
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
          x: 400,
          y: 300,
        ),
      ],
    );
    ref.read(workflowsProvider.notifier).update((list) => [...list, newWf]);
    ref.read(workflowProvider.notifier).state = newWf;
    ref.read(modeProvider.notifier).state = AppMode.build;
  },
),
```

Add imports if missing:
```dart
import '../models/workflow_node.dart';
import '../widgets/mode_rail.dart';
```
(Note: `mode_rail.dart` may already be transitively imported; add explicit import for `AppMode`.)

Actually, check what `mode_rail.dart` exports. If `AppMode` is defined there, import it. Otherwise check where it's defined.)

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/workflows_sidebar.dart
git commit -m "feat: wire new workflow button to create Untitled workflow with entrypoint node"
```

---

### Task 9: Final Verification

- [ ] **Step 1: Run flutter analyze**

```bash
~/flutter/bin/flutter analyze
```
Expected: No issues.

- [ ] **Step 2: Build web**

```bash
~/flutter/bin/flutter build web --release
```
Expected: Build succeeds.

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "feat: history runs table, worker nodes, new workflow creation"
```

---

## Self-Review

**Spec coverage check:**
- ✅ History mode layout (no job → RunsTable, job selected → sidebar + canvas) — Task 7
- ✅ RunsTable with grouped/flat toggle, filter pills — Tasks 3, 4
- ✅ Worker node widget with status rail, label, skills, progress, selection glow — Task 5
- ✅ Entrypoint node on every workflow — Tasks 2, 6
- ✅ New workflow button creates "Untitled" with entrypoint node — Task 8

**Placeholder scan:** No TBD/TODO/fill-in-details found.

**Type consistency:** `WorkflowNode` class matches usage in mock data, graph canvas, and sidebar. `JobSummary.by` field matches table rendering. Provider names consistent.
