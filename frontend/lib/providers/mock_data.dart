import '../models/stage_data.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';
import '../models/server_def.dart';

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
  final List<WorkflowConnection> connections;
  final List<ServerDef> servers;

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
    this.connections = const [],
    this.servers = const [],
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
      connections: const [],
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
    List<WorkflowConnection>? connections,
    List<ServerDef>? servers,
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
      connections: connections ?? this.connections,
      servers: servers ?? this.servers,
      remoteContent: remoteContent ?? this.remoteContent,
      parseError: parseError ?? this.parseError,
    );
  }
}

final Map<String, List<StageExecution>> mockStageExecutions = {
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
