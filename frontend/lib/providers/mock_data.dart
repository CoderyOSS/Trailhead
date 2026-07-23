import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';
import '../models/server_def.dart';

const _unset = Object();

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

  /// Absolute path of the Carta project this workflow deploys against.
  /// Null = current/default project on the runtime.
  final String? project;

  /// Raw YAML from backend when this workflow was loaded remotely.
  /// Null for freshly-created (unsaved) workflows.
  final String? remoteContent;

  /// Non-null when the backend YAML could not be parsed into the canvas model.
  /// UI shows an "incompatible format" badge and restricts to delete-only.
  final String? parseError;

  /// Subflow-only keys, carried through so subflow tab editing round-trips
  /// them (`params:`, `inputs:`, `outputs:` at document top level). Always
  /// empty for plain flows.
  final List<String> subflowParams;
  final Map<String, String> subflowInputs;
  final Map<String, String> subflowOutputs;

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
    this.project,
    this.remoteContent,
    this.parseError,
    this.subflowParams = const [],
    this.subflowInputs = const {},
    this.subflowOutputs = const {},
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
    Object? project = _unset,
    String? remoteContent,
    String? parseError,
    List<String>? subflowParams,
    Map<String, String>? subflowInputs,
    Map<String, String>? subflowOutputs,
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
      project: project == _unset ? this.project : project as String?,
      remoteContent: remoteContent ?? this.remoteContent,
      parseError: parseError ?? this.parseError,
      subflowParams: subflowParams ?? this.subflowParams,
      subflowInputs: subflowInputs ?? this.subflowInputs,
      subflowOutputs: subflowOutputs ?? this.subflowOutputs,
    );
  }
}

