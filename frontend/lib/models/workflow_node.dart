class BranchOutput {
  final String id;
  final String label;
  final String? expression;

  const BranchOutput({
    required this.id,
    required this.label,
    this.expression,
  });

  BranchOutput copyWith({
    String? id,
    String? label,
    String? expression,
  }) {
    return BranchOutput(
      id: id ?? this.id,
      label: label ?? this.label,
      expression: expression ?? this.expression,
    );
  }
}

class WorkflowNode {
  final String id;
  final String kind;
  final String label;
  final String? sub;
  final String? model;
  final List<String> skills;
  final double x;
  final double y;
  final List<BranchOutput> outputs;
  final bool matchAll;

  static const List<BranchOutput> defaultBranchOutputs = [
    BranchOutput(id: '0', label: 'high'),
    BranchOutput(id: '1', label: 'medium'),
    BranchOutput(id: '2', label: 'low'),
    BranchOutput(id: '3', label: 'default'),
  ];

  const WorkflowNode({
    required this.id,
    required this.kind,
    required this.label,
    this.sub,
    this.model,
    this.skills = const [],
    required this.x,
    required this.y,
    this.outputs = const [],
    this.matchAll = false,
  });

  WorkflowNode copyWith({
    String? id,
    String? kind,
    String? label,
    String? sub,
    String? model,
    List<String>? skills,
    double? x,
    double? y,
    List<BranchOutput>? outputs,
    bool? matchAll,
  }) {
    return WorkflowNode(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      sub: sub ?? this.sub,
      model: model ?? this.model,
      skills: skills ?? this.skills,
      x: x ?? this.x,
      y: y ?? this.y,
      outputs: outputs ?? this.outputs,
      matchAll: matchAll ?? this.matchAll,
    );
  }
}
