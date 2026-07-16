import 'dart:ui' show Rect;
import 'stage_data.dart';

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

  // Stage drawer fields
  final String? prompt;
  final String? resultFormat;
  final Map<String, dynamic>? schema;
  final String? timeout;
  final int? retries;
  final int? parallelism;
  final String? connection;
  final List<String> configs;
  final List<SwitchCase> cases;
  final List<BranchCase> branches;
  final List<String> waitsFor;
  final String? joinMode;
  final String? over;
  final int? count;
  final int? concurrency;
  final String? collect;
  final StageBody? body;

  // Node type-specific config
  final int? intervalMs;
  final String? httpServer;
  final String? httpMethod;
  final String? httpPath;

  static const List<BranchOutput> defaultBranchOutputs = [
    BranchOutput(id: '0', label: 'high'),
    BranchOutput(id: '1', label: 'medium'),
    BranchOutput(id: '2', label: 'low'),
    BranchOutput(id: '3', label: 'default'),
  ];

  // Geometry constants
  static const double workerWidth = 168.0;
  static const double workerHeight = 36.0;
  static const double fanWidth = 168.0;
  static const double fanHeight = 36.0;
  static const double branchWidth = 130.0;
  static const double branchPadY = 9.0;
  static const double branchRowHeight = 27.0;

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
    this.prompt,
    this.resultFormat,
    this.schema,
    this.timeout,
    this.retries,
    this.parallelism,
    this.connection,
    this.configs = const [],
    this.cases = const [],
    this.branches = const [],
    this.waitsFor = const [],
    this.joinMode,
    this.over,
    this.count,
    this.concurrency,
    this.collect,
    this.body,
    this.intervalMs,
    this.httpServer,
    this.httpMethod,
    this.httpPath,
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
    String? prompt,
    String? resultFormat,
    Map<String, dynamic>? schema,
    String? timeout,
    int? retries,
    int? parallelism,
    String? connection,
    List<String>? configs,
    List<SwitchCase>? cases,
    List<BranchCase>? branches,
    List<String>? waitsFor,
    String? joinMode,
    String? over,
    int? count,
    int? concurrency,
    String? collect,
    StageBody? body,
    int? intervalMs,
    String? httpServer,
    String? httpMethod,
    String? httpPath,
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
      prompt: prompt ?? this.prompt,
      resultFormat: resultFormat ?? this.resultFormat,
      schema: schema ?? this.schema,
      timeout: timeout ?? this.timeout,
      retries: retries ?? this.retries,
      parallelism: parallelism ?? this.parallelism,
      connection: connection ?? this.connection,
      configs: configs ?? this.configs,
      cases: cases ?? this.cases,
      branches: branches ?? this.branches,
      waitsFor: waitsFor ?? this.waitsFor,
      joinMode: joinMode ?? this.joinMode,
      over: over ?? this.over,
      count: count ?? this.count,
      concurrency: concurrency ?? this.concurrency,
      collect: collect ?? this.collect,
      body: body ?? this.body,
      intervalMs: intervalMs ?? this.intervalMs,
      httpServer: httpServer ?? this.httpServer,
      httpMethod: httpMethod ?? this.httpMethod,
      httpPath: httpPath ?? this.httpPath,
    );
  }
}

extension WorkflowNodeRect on WorkflowNode {
  double get width => kind == 'function' ? WorkflowNode.branchWidth : WorkflowNode.workerWidth;

  double get height => kind == 'function'
      ? (outputs.isNotEmpty
          ? WorkflowNode.branchPadY * 2 + outputs.length * WorkflowNode.branchRowHeight
          : WorkflowNode.branchPadY * 2 +
              WorkflowNode.defaultBranchOutputs.length * WorkflowNode.branchRowHeight)
      : WorkflowNode.workerHeight;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}
