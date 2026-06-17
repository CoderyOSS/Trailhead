class WorkflowEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final String? label;
  final int? sourcePort;

  const WorkflowEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.label,
    this.sourcePort,
  });

  WorkflowEdge copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    String? label,
    int? sourcePort,
  }) {
    return WorkflowEdge(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      label: label ?? this.label,
      sourcePort: sourcePort ?? this.sourcePort,
    );
  }
}
