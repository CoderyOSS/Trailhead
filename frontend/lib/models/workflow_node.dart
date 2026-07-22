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

  // Transform node expression (kind=='function' && expr!=null => transform, not routing)
  final String? expr;

  // Node type-specific config
  final int? intervalMs;
  final String? httpIngressServer;
  final String? httpIngressMethod;
  final String? httpIngressPath;
  final int? httpEgressStatus;
  final String? httpEgressContentType;
  final String? httpEgressBody;
  final String? httpRequestUrl;
  final String? httpRequestMethod;
  final String? httpEgressServer;

  // source.inject payload. Literal mode: Elixir literal source, backend
  // parses (THRT.ElixirTerm). Expr mode (payloadIsExpr): arbitrary Elixir
  // source, evaluated once at deploy time (THRT.Expr) — emits payload_expr.
  final String? payloadCode;
  final bool payloadIsExpr;
  final bool? once;

  // Per-node logging flags. `loggingEnabled` is build-time (codegen emits
  // hooks only when true). `logIn` / `logOut` are runtime-toggleable.
  final bool loggingEnabled;
  final bool logIn;
  final bool logOut;

  // Generic config map for node kinds without a dedicated field. Today this
  // holds the `subflow` node's `subflow:` name + declared params; future
  // pseudo-builtins can reuse it. Emitted as a single `config:` block in YAML.
  final Map<String, dynamic>? config;

  // `port.in` / `port.out` channel name (required server-side). Ports pair
  // across flows by matching channel via the runtime PortRegistry.
  final String? channel;

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
    this.expr,
    this.intervalMs,
    this.httpIngressServer,
    this.httpIngressMethod,
    this.httpIngressPath,
    this.httpEgressStatus,
    this.httpEgressContentType,
    this.httpEgressBody,
    this.httpRequestUrl,
    this.httpRequestMethod,
    this.httpEgressServer,
    this.payloadCode,
    this.payloadIsExpr = false,
    this.once,
    this.loggingEnabled = false,
    this.logIn = false,
    this.logOut = false,
    this.config,
    this.channel,
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
    String? expr,
    int? intervalMs,
    String? httpIngressServer,
    String? httpIngressMethod,
    String? httpIngressPath,
    int? httpEgressStatus,
    String? httpEgressContentType,
    String? httpEgressBody,
    String? httpRequestUrl,
    String? httpRequestMethod,
    String? httpEgressServer,
    String? payloadCode,
    bool? payloadIsExpr,
    bool? once,
    bool? loggingEnabled,
    bool? logIn,
    bool? logOut,
    Map<String, dynamic>? config,
    String? channel,
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
      expr: expr ?? this.expr,
      intervalMs: intervalMs ?? this.intervalMs,
      httpIngressServer: httpIngressServer ?? this.httpIngressServer,
      httpIngressMethod: httpIngressMethod ?? this.httpIngressMethod,
      httpIngressPath: httpIngressPath ?? this.httpIngressPath,
      httpEgressStatus: httpEgressStatus ?? this.httpEgressStatus,
      httpEgressContentType: httpEgressContentType ?? this.httpEgressContentType,
      httpEgressBody: httpEgressBody ?? this.httpEgressBody,
      httpRequestUrl: httpRequestUrl ?? this.httpRequestUrl,
      httpRequestMethod: httpRequestMethod ?? this.httpRequestMethod,
      httpEgressServer: httpEgressServer ?? this.httpEgressServer,
      payloadCode: payloadCode ?? this.payloadCode,
      payloadIsExpr: payloadIsExpr ?? this.payloadIsExpr,
      once: once ?? this.once,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
      logIn: logIn ?? this.logIn,
      logOut: logOut ?? this.logOut,
      config: config ?? this.config,
      channel: channel ?? this.channel,
    );
  }
}

/// Node kind classification shared with the THRT backend.
///
/// Mirrors `THRT.Node.actor?/1` (module introspection on `handle_message/3`).
/// Actor kinds wrap an Erlang process (mailbox + send/receive); function kinds
/// are pure transforms inlined into the caller's pipe chain.
///
/// Keep in sync with `ConnectionValidator.actorKinds` / `functionKinds`.
extension WorkflowNodeKind on WorkflowNode {
  static const Set<String> actorKinds = <String>{
    'genserver',
    'http.server.ingress',
    'http.client.request',
    'task',
    'source.inject',
    // Port nodes are actors (THRT.Nodes.Port.In/Out): mailbox send/receive
    // semantics, channel pairing resolved at runtime via PortRegistry.
    'port.in',
    'port.out',
    // `subflow` nodes deploy as actor-flattened graphs (THRT.Subflow.expand);
    // their in/out ports behave as actors on the canvas before deploy.
    'subflow',
  };

  static const Set<String> functionKinds = <String>{
    'function',
    'delay',
    'http.server.egress',
  };

  /// Actor kinds reported by the runtime (`GET /api/v1/nodes`), populated
  /// from `installedNodesProvider`. Non-builtin installed modules classify
  /// here so their edges get message (not pipe) semantics.
  static Set<String> installedActorKinds = <String>{};

  /// True when this node wraps an Erlang process (has a mailbox).
  /// A connection whose target `isActor` is a message (`send/2`).
  bool get isActor =>
      actorKinds.contains(kind) || installedActorKinds.contains(kind);

  /// True when this node is a pure function (`transform/3`).
  /// A connection whose target `isFunction` is a pipe (`|>`).
  bool get isFunction => functionKinds.contains(kind);

  /// Node kinds that originate messages (no incoming edges allowed).
  static const Set<String> noInputKinds = <String>{
    'source.inject',
    'http.server.ingress',
    // port.in's input is its channel (cross-flow), never an in-flow edge.
    'port.in',
  };

  /// Node kinds that terminate messages (no outgoing edges allowed).
  static const Set<String> noOutputKinds = <String>{
    'http.server.egress',
    // port.out's output is its channel (cross-flow), never an in-flow edge.
    'port.out',
  };

  /// True when this node accepts incoming connections (shows input dot/handle).
  bool get hasInput => !noInputKinds.contains(kind);

  /// True when this node produces outgoing connections (shows output dot/handle).
  bool get hasOutput => !noOutputKinds.contains(kind);
}

extension WorkflowNodeRect on WorkflowNode {
  bool get _isBranch => kind == 'function' && expr == null;

  double get width => _isBranch ? WorkflowNode.branchWidth : WorkflowNode.workerWidth;

  double get height => _isBranch
      ? (outputs.isNotEmpty
          ? WorkflowNode.branchPadY * 2 + outputs.length * WorkflowNode.branchRowHeight
          : WorkflowNode.branchPadY * 2 +
              WorkflowNode.defaultBranchOutputs.length * WorkflowNode.branchRowHeight)
      : WorkflowNode.workerHeight;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}
