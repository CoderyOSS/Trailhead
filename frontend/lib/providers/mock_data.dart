import '../models/stage_data.dart';
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

  /// Raw YAML from backend when this workflow was loaded remotely.
  /// Null for freshly-created (unsaved) workflows.
  final String? remoteContent;

  /// Non-null when the backend YAML could not be parsed into the canvas model.
  /// UI shows an "incompatible format" badge and restricts to delete-only.
  final String? parseError;

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
    this.remoteContent,
    this.parseError,
  });

  /// Placeholder for workflows whose YAML could not be parsed into the canvas
  /// model. The user can still delete them via the API.
  factory WorkflowSummary.incompatible({
    required String name,
    required String parseError,
    String? remoteContent,
  }) {
    return WorkflowSummary(
      id: 'wf_${name.replaceAll(RegExp(r'[^a-z0-9_-]'), '_').toLowerCase()}',
      name: name,
      version: 0,
      updated: '',
      nodes: const [],
      edges: const [],
      remoteContent: remoteContent,
      parseError: parseError,
    );
  }

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
    String? remoteContent,
    String? parseError,
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
      remoteContent: remoteContent ?? this.remoteContent,
      parseError: parseError ?? this.parseError,
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

final Map<String, List<StageExecution>> mockStageExecutions = {
  'entrypoint': [
    StageExecution(
      id: 'ex_1',
      label: 'entrypoint',
      status: 'passed',
      startedAt: '14:18:02',
      durMs: 4200,
      tokens: 1842,
      renderedPrompt: 'You are a helpful code reviewer. Review the following pull request and identify potential issues.\n\nPR title: "Fix authentication bypass"\nPR description: "This PR fixes the auth bypass issue reported in #1427"\n\nFocus on: correctness, performance, security, and style.',
      result: {
        'summary': 'Found 3 issues: potential null pointer, missing input validation, and hardcoded secret.',
        'issues': [
          {'severity': 'high', 'line': 42, 'message': 'Null pointer when user is not authenticated'},
          {'severity': 'medium', 'line': 78, 'message': 'Input not sanitized before SQL query'},
          {'severity': 'low', 'line': 156, 'message': 'Hardcoded API key'},
        ],
      },
    ),
  ],
  'commenter': [
    StageExecution(
      id: 'ex_2',
      label: 'comment-files · 1/8',
      status: 'running',
      startedAt: '14:18:07',
      durMs: 0,
      tokens: 12400,
      progress: 0.62,
      streaming: 'Looking at auth_service.ts... Found issue on line 42. The `getUser` method can return null but the caller does not check.',
      tools: [
        ToolCall(name: 'readFile', args: 'auth_service.ts', ok: true, ms: 340),
        ToolCall(name: 'readFile', args: 'user_model.ts', ok: true, ms: 210),
        ToolCall(name: 'grep', args: 'getUser', running: true),
      ],
    ),
    StageExecution(
      id: 'ex_3',
      label: 'comment-files · 2/8',
      status: 'queued',
      startedAt: null,
      durMs: 0,
      tokens: 0,
      waitsFor: ['comment-files · 1/8'],
    ),
  ],
  'scorer': [
    StageExecution(
      id: 'ex_4',
      label: 'priority-routing',
      status: 'passed',
      startedAt: '14:18:06',
      durMs: 120,
      tokens: 45,
    ),
  ],
  'high-worker': [
    StageExecution(
      id: 'ex_5',
      label: 'urgent-review',
      status: 'failed',
      startedAt: '14:18:08',
      durMs: 3200,
      tokens: 5600,
      renderedPrompt: 'This is a HIGH priority review. The entrypoint found critical issues.\n\nPlease provide a detailed response with actionable fixes.\n\nContext: Found 3 issues: potential null pointer, missing input validation, and hardcoded secret.',
      error: (
        code: 'RATE_LIMIT',
        message: 'Anthropic API rate limit exceeded. Retry after 60s.',
      ),
    ),
    StageExecution(
      id: 'ex_6',
      label: 'urgent-review (retry 1)',
      status: 'running',
      startedAt: '14:18:12',
      durMs: 0,
      tokens: 0,
      progress: 0.35,
      streaming: 'Analyzing the null pointer issue...',
    ),
  ],
  'med-worker': [
    StageExecution(
      id: 'ex_7',
      label: 'normal-review',
      status: 'skipped',
      startedAt: null,
      durMs: 0,
      tokens: 0,
      skipReason: 'Branch condition not met — score 0.85 routed to high priority instead.',
    ),
  ],
  'low-worker': [
    StageExecution(
      id: 'ex_8',
      label: 'deferred-review',
      status: 'skipped',
      startedAt: null,
      durMs: 0,
      tokens: 0,
      skipReason: 'Branch condition not met — score 0.85 routed to high priority instead.',
    ),
  ],
};
