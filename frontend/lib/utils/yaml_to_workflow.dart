import '../models/stage_data.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';
import '../models/server_def.dart';
import '../providers/mock_data.dart';
import 'package:yaml/yaml.dart';

class WorkflowParseException implements Exception {
  final String message;
  WorkflowParseException(this.message);
  @override
  String toString() => 'WorkflowParseException: $message';
}

/// Parse stored YAML content into a [WorkflowSummary].
///
/// Inverse of [workflowToYaml]. Reads:
///   - name (required), version (default 1), draft (optional)
///   - nodes: array of {id, type, label, pos, ...kind-specific fields}
///     (also accepts legacy stages/name/kind keys)
///   - connections: array of {from, to}  (legacy `edges:` auto-migrates)
///
/// Throws [WorkflowParseException] on missing required fields or
/// incompatible schema (e.g. scheduler-style map stages).
WorkflowSummary yamlToWorkflow(String name, String yamlText) {
  final YamlMap doc;
  try {
    final parsed = loadYaml(yamlText);
    if (parsed is! YamlMap) {
      throw WorkflowParseException('document is not a YAML mapping');
    }
    doc = parsed;
  } catch (e) {
    throw WorkflowParseException('failed to parse YAML: $e');
  }

  final version = (doc['version'] as int?) ?? 1;
  final draft = doc['draft'] as int?;

  // Try nodes (THRT schema) first, fall back to stages (legacy frontend).
  var nodeList = doc['nodes'];
  if (nodeList is! YamlList) {
    nodeList = doc['stages'];
  }

  final nodes = <WorkflowNode>[];
  if (nodeList is YamlList) {
    for (var i = 0; i < nodeList.length; i++) {
      final item = nodeList[i];
      if (item is! YamlMap) {
        throw WorkflowParseException('node at index $i is not a mapping');
      }
      nodes.add(_parseNode(item, i));
    }
  } else if (nodeList is YamlMap) {
    throw WorkflowParseException(
      'nodes is a map — incompatible with frontend schema (array expected). '
      'This workflow uses the scheduler format and cannot be edited on the canvas.',
    );
  } else if (nodeList == null) {
    // Empty workflow with no nodes is allowed.
  } else {
    throw WorkflowParseException('unexpected nodes shape: ${nodeList.runtimeType}');
  }

  // Read `connections:` (canonical) first; fall back to legacy `edges:` key
  // so existing persisted workflows auto-migrate. Matches THRT backend.
  final connectionsNode = doc['connections'] ?? doc['edges'];
  final connections = <WorkflowConnection>[];
  if (connectionsNode is YamlList) {
    for (var i = 0; i < connectionsNode.length; i++) {
      final e = connectionsNode[i];
      if (e is! YamlMap) continue;
      connections.add(_parseConnection(e, i));
    }
  }

  // No entrypoint injection — workflows can start from any node.

  // Parse servers section
  final serverDefs = <ServerDef>[];
  final serversNode = doc['servers'];
  if (serversNode is YamlList) {
    for (final s in serversNode) {
      if (s is! YamlMap) continue;
      serverDefs.add(ServerDef(
        id: _toStr(s['id']) ?? 'default',
        port: (s['port'] as int?) ?? 8081,
        scheme: _toStr(s['scheme']) ?? 'http',
        tlsCert: _toStr(s['tls_cert']),
        tlsKey: _toStr(s['tls_key']),
        cors: s['cors'] is YamlMap
            ? CorsDef(
                origins: _toStringListFromYaml(s['cors']['origins']),
                methods: _toStringListFromYaml(s['cors']['methods']),
                headers: _toStringListFromYaml(s['cors']['headers']),
              )
            : null,
      ));
    }
  }

  return WorkflowSummary(
    id: 'wf_${name.replaceAll(RegExp(r'[^a-z0-9_-]'), '_').toLowerCase()}',
    name: name,
    version: version,
    draft: draft,
    updated: '',
    nodes: nodes,
    connections: connections,
    servers: serverDefs,
    project: _toStr(doc['project']),
    remoteContent: yamlText,
  );
}

WorkflowNode _parseNode(YamlMap stage, int index) {
  final id = _toStr(stage['id']) ?? _toStr(stage['name']);
  if (id == null || id.isEmpty) {
    throw WorkflowParseException('node at index $index missing "id" (or legacy "name")');
  }
  final kind = _toStr(stage['type']) ?? _toStr(stage['kind']) ?? 'genserver';
  if (kind == 'sink.log') {
    throw WorkflowParseException(
      'node "$id" has type "sink.log" which has been removed. '
      'Logging is now a per-node build-time flag (config.logging_enabled).',
    );
  }
  final label = _toStr(stage['label']) ?? id;
  final sub = stage['sub'] as String?;
  final model = stage['model'] as String?;
  final skills = _toStringList(stage['skills']);

  // Position with default fallback (vertical stack).
  final pos = stage['pos'];
  double x = 0;
  double y = -16.0 + index * 64;
  if (pos is YamlMap) {
    final px = pos['x'];
    final py = pos['y'];
    if (px is num) x = px.toDouble();
    if (py is num) y = py.toDouble();
  }

  // Common optional fields.
  final prompt = stage['prompt'] as String?;
  final resultFormat = stage['result_format'] as String?;
  final schema = stage['schema'] is YamlMap
      ? Map<String, dynamic>.from(stage['schema'] as YamlMap)
      : null;
  final timeout = stage['timeout']?.toString();
  final retries = (stage['retries'] as int?);
  final parallelism = (stage['parallelism'] as int?);
  final connection = stage['connection']?.toString();
  final configs = _toStringList(stage['configs']);

  // Node config sub-map (THRT node types)
  final config = stage['config'];
  String? expr;
  int? intervalMs;
  String? httpIngressServer;
  String? httpIngressMethod;
  String? httpIngressPath;
  int? httpEgressStatus;
  String? httpEgressContentType;
  String? httpEgressBody;
  String? httpRequestUrl;
  String? httpRequestMethod;
  String? httpEgressServer;
  String? payloadCode;
  var payloadIsExpr = false;
  bool? once;
  bool loggingEnabled = false;
  bool logIn = false;
  bool logOut = false;
  Map<String, dynamic>? genericConfig;
  String? channel;
  if (config is YamlMap) {
    expr = _toStr(config['expr']);
    if (kind == 'delay') {
      intervalMs = config['interval_ms'] as int?;
    }
    if (kind == 'http.server.ingress') {
      httpIngressServer = _toStr(config['server']);
      httpIngressMethod = _toStr(config['method']);
      httpIngressPath = _toStr(config['path']);
    }
    if (kind == 'http.server.egress') {
      httpEgressServer = _toStr(config['server']);
      httpEgressStatus = (config['status'] ?? 200) as int?;
      httpEgressContentType = _toStr(config['content_type']);
      httpEgressBody = _toStr(config['body']);
    }
    if (kind == 'http.client.request') {
      httpRequestUrl = _toStr(config['url']);
      httpRequestMethod = _toStr(config['method']);
    }
    if (kind == 'source.inject') {
      // payload_expr (evaluated at deploy) wins over payload_code (literal).
      final exprSrc = _toStr(config['payload_expr']);
      if (exprSrc != null) {
        payloadCode = exprSrc;
        payloadIsExpr = true;
      } else {
        payloadCode = _toStr(config['payload_code']);
      }
      once = config['once'] as bool?;
      intervalMs = config['interval_ms'] as int?;
    }
    if (kind == 'port.in' || kind == 'port.out') {
      channel = _toStr(config['channel']);
    }
    loggingEnabled = (config['logging_enabled'] as bool?) ?? false;
    logIn = (config['log_in'] as bool?) ?? false;
    logOut = (config['log_out'] as bool?) ?? false;

    // Subflow nodes store their whole config under `config:` — pull it
    // through generically so the drawer can re-read selected subflow + params.
    if (kind == 'subflow') {
      genericConfig = <String, dynamic>{};
      for (final k in (config.keys.cast<String>())) {
        genericConfig[k] = config[k];
      }
    }
  }

  // Kind-specific fields.
  final outputs = <BranchOutput>[];
  var matchAll = false;
  if (kind == 'function' || kind == 'branch') {
    final outsNode = stage['outputs'];
    if (outsNode is YamlList) {
      for (final o in outsNode) {
        if (o is! YamlMap) continue;
        outputs.add(BranchOutput(
          id: _toStr(o['id']) ?? '0',
          label: _toStr(o['label']) ?? '',
          expression: _toStr(o['expression']),
        ));
      }
    }
    matchAll = (stage['match_all'] as bool?) ?? false;
  }

  // Switch cases.
  final cases = <SwitchCase>[];
  if (kind == 'switch') {
    final c = stage['cases'];
    if (c is YamlList) {
      for (final cs in c) {
        if (cs is! YamlMap) continue;
        cases.add(SwitchCase(
          match: _toStr(cs['match']) ?? '',
          to: _toStringList(cs['to']),
        ));
      }
    }
  }

  // Branch routing cases (separate from branch-outputs above; legacy field).
  final branches = <BranchCase>[];
  if (stage['branches'] is YamlList) {
    for (final b in stage['branches'] as YamlList) {
      if (b is! YamlMap) continue;
        branches.add(BranchCase(
          match: _toStr(b['match']) ?? '',
          to: _toStringList(b['to']),
          loop: (b['loop'] as bool?) ?? false,
        ));
    }
  }

  // Join fields.
  final waitsFor = _toStringList(stage['waits_for']);
  final joinMode = (stage['mode'] as String?);

  // Fan/map fields.
  final over = stage['over']?.toString();
  final count = (stage['count'] as int?);
  final concurrency = (stage['concurrency'] as int?);
  final collect = stage['collect']?.toString();

  StageBody? body;
  final bodyNode = stage['body'];
  if (bodyNode is YamlMap) {
    body = StageBody(
      label: (bodyNode['label'] as String?) ?? '',
      model: bodyNode['model'] as String?,
      skills: _toStringList(bodyNode['skills']),
      prompt: (bodyNode['prompt'] as String?) ?? '',
    );
  }

  return WorkflowNode(
    id: id,
    kind: kind,
    label: label,
    sub: sub,
    model: model,
    skills: skills,
    x: x,
    y: y,
    outputs: outputs,
    matchAll: matchAll,
    prompt: prompt,
    resultFormat: resultFormat,
    schema: schema,
    timeout: timeout,
    retries: retries,
    parallelism: parallelism,
    connection: connection,
    configs: configs,
    cases: cases,
    branches: branches,
    waitsFor: waitsFor,
    joinMode: joinMode,
    over: over,
    count: count,
    concurrency: concurrency,
    collect: collect,
    body: body,
    expr: expr,
    intervalMs: intervalMs,
    httpIngressServer: httpIngressServer,
    httpIngressMethod: httpIngressMethod,
    httpIngressPath: httpIngressPath,
    httpEgressStatus: httpEgressStatus,
    httpEgressContentType: httpEgressContentType,
    httpEgressBody: httpEgressBody,
    httpRequestUrl: httpRequestUrl,
    httpRequestMethod: httpRequestMethod,
    httpEgressServer: httpEgressServer,
    payloadCode: payloadCode,
    payloadIsExpr: payloadIsExpr,
    once: once,
    loggingEnabled: loggingEnabled,
    logIn: logIn,
    logOut: logOut,
    config: genericConfig,
    channel: channel,
  );
}

WorkflowConnection _parseConnection(YamlMap e, int index) {
  final from = _toStr(e['from']) ?? '';
  final to = _toStr(e['to']) ?? '';
  // Legacy `port:` is read into sourcePort for in-memory continuity but is
  // not re-emitted (spec §10 — future case-expression ports).
  final port = e['port'] as int?;
  return WorkflowConnection(
    id: 'conn_${index}_$from\_$to',
    from: from,
    to: to,
    sourcePort: port,
  );
}

List<String> _toStringList(dynamic node) {
  if (node is YamlList) {
    return node.map((e) => e.toString()).toList();
  }
  if (node is String) return [node];
  if (node == null) return const [];
  return [node.toString()];
}

/// Coerce YAML scalars to string. Avoids `_TypeError` when an unquoted
/// value (e.g. `id: 0`) is parsed as int/double but consumers expect String.
String? _toStr(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

List<String> _toStringListFromYaml(dynamic node) {
  if (node is YamlList) {
    return node.map((e) => e.toString()).toList();
  }
  return [];
}
