import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';

enum JobState { running, paused, passed, failed, cancelled, queued, retrying }

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
  final List<WorkflowEdge> edges;

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
    this.edges = const [],
  });

  WorkflowSummary copyWith({
    String? id,
    String? name,
    int? version,
    int? draft,
    String? updated,
    int? runCount,
    String? last,
    int? active,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
  }) {
    return WorkflowSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      draft: draft ?? this.draft,
      updated: updated ?? this.updated,
      runCount: runCount ?? this.runCount,
      last: last ?? this.last,
      active: active ?? this.active,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }
}

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
      x: 0,
      y: -16,
    ),
    WorkflowNode(
      id: 'commenter',
      kind: 'fan',
      label: 'comment-files',
      x: 220,
      y: -16,
    ),
    WorkflowNode(
      id: 'scorer',
      kind: 'branch',
      label: 'priority-routing',
      x: 440,
      y: -16,
      outputs: [
        BranchOutput(id: '0', label: 'high', expression: 'score > 0.8'),
        BranchOutput(id: '1', label: 'medium', expression: 'score > 0.5'),
        BranchOutput(id: '2', label: 'low', expression: 'score > 0.2'),
        BranchOutput(id: '3', label: 'default'),
      ],
    ),
    WorkflowNode(
      id: 'high-worker',
      kind: 'worker',
      label: 'urgent-review',
      x: 660,
      y: -60,
    ),
    WorkflowNode(
      id: 'med-worker',
      kind: 'worker',
      label: 'normal-review',
      x: 660,
      y: -16,
    ),
    WorkflowNode(
      id: 'low-worker',
      kind: 'worker',
      label: 'deferred-review',
      x: 660,
      y: 28,
    ),
  ],
  edges: const [
    WorkflowEdge(
      id: 'edge_1',
      sourceId: 'entrypoint',
      targetId: 'commenter',
    ),
    WorkflowEdge(
      id: 'edge_2',
      sourceId: 'commenter',
      targetId: 'scorer',
    ),
    WorkflowEdge(
      id: 'edge_3',
      sourceId: 'scorer',
      targetId: 'high-worker',
      sourcePort: 0,
    ),
    WorkflowEdge(
      id: 'edge_4',
      sourceId: 'scorer',
      targetId: 'med-worker',
      sourcePort: 1,
    ),
    WorkflowEdge(
      id: 'edge_5',
      sourceId: 'scorer',
      targetId: 'low-worker',
      sourcePort: 2,
    ),
  ],
);

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
        WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 0, y: -16),
      ],
      edges: const [],
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
        WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 0, y: -16),
      ],
      edges: const [],
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
        WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 0, y: -16),
      ],
      edges: const [],
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
        WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 0, y: -16),
      ],
      edges: const [],
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
        WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 0, y: -16),
      ],
      edges: const [],
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
        WorkflowNode(id: 'entrypoint', kind: 'worker', label: 'entrypoint', x: 0, y: -16),
      ],
      edges: const [],
  ),
];

final mockJob = JobSummary(
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
);

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

const historyCount = 13;
