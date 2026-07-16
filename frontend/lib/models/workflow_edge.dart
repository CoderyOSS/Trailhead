/// A connection between two nodes in a workflow graph.
///
/// The connection type (pipe vs message) is DERIVED from the target node's
/// classification (`WorkflowNode.isActor`) — never stored on the connection.
/// See `lib/utils/connection_validator.dart` for type inference + validation.
///
/// [sourcePort] is retained for future multi-port `case` expression support
/// (design spec §10 — deferred). It is not currently emitted to YAML.
class WorkflowConnection {
  final String id;
  final String from;
  final String to;
  final int? sourcePort;

  const WorkflowConnection({
    required this.id,
    required this.from,
    required this.to,
    this.sourcePort,
  });

  WorkflowConnection copyWith({
    String? id,
    String? from,
    String? to,
    int? sourcePort,
  }) {
    return WorkflowConnection(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      sourcePort: sourcePort ?? this.sourcePort,
    );
  }
}
