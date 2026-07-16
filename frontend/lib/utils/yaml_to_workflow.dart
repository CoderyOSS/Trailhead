import '../models/stage_data.dart';
import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';
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
///   - edges: array of {from, to, port?}
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

  final edgesNode = doc['edges'];
  final edges = <WorkflowEdge>[];
  if (edgesNode is YamlList) {
    for (var i = 0; i < edgesNode.length; i++) {
      final e = edgesNode[i];
      if (e is! YamlMap) continue;
      edges.add(_parseEdge(e, i));
    }
  }

  // No entrypoint injection — workflows can start from any node.

  return WorkflowSummary(
    id: 'wf_${name.replaceAll(RegExp(r'[^a-z0-9_-]'), '_').toLowerCase()}',
    name: name,
    version: version,
    draft: draft,
    updated: '',
    nodes: nodes,
    edges: edges,
    remoteContent: yamlText,
  );
}

WorkflowNode _parseNode(YamlMap stage, int index) {
  final id = _toStr(stage['id']) ?? _toStr(stage['name']);
  if (id == null || id.isEmpty) {
    throw WorkflowParseException('node at index $index missing "id" (or legacy "name")');
  }
  final kind = _toStr(stage['type']) ?? _toStr(stage['kind']) ?? 'genserver';
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
  int? intervalMs;
  String? httpServer;
  String? httpMethod;
  String? httpPath;
  if (config is YamlMap) {
    if (kind == 'delay') {
      intervalMs = config['interval_ms'] as int?;
    }
    if (kind == 'http') {
      httpServer = _toStr(config['server']);
      httpMethod = _toStr(config['method']);
      httpPath = _toStr(config['path']);
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
    intervalMs: intervalMs,
    httpServer: httpServer,
    httpMethod: httpMethod,
    httpPath: httpPath,
  );
}

WorkflowEdge _parseEdge(YamlMap e, int index) {
  final from = _toStr(e['from']) ?? '';
  final to = _toStr(e['to']) ?? '';
  final port = e['port'] as int?;
  final label = _toStr(e['label']);
  return WorkflowEdge(
    id: 'edge_${index}_$from\_$to',
    sourceId: from,
    targetId: to,
    sourcePort: port,
    label: label,
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
