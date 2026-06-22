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
///   - stages: array of {name, kind, label, pos, ...kind-specific fields}
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

  final stagesNode = doc['stages'];
  final nodes = <WorkflowNode>[];
  if (stagesNode is YamlList) {
    for (var i = 0; i < stagesNode.length; i++) {
      final stage = stagesNode[i];
      if (stage is! YamlMap) {
        throw WorkflowParseException('stage at index $i is not a mapping');
      }
      nodes.add(_parseNode(stage, i));
    }
  } else if (stagesNode is YamlMap) {
    throw WorkflowParseException(
      'stages is a map — incompatible with frontend schema (array expected). '
      'This workflow uses the scheduler format and cannot be edited on the canvas.',
    );
  } else if (stagesNode == null) {
    // Empty workflow with no stages is allowed.
  } else {
    throw WorkflowParseException('unexpected stages shape: ${stagesNode.runtimeType}');
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
  final id = stage['name'] as String?;
  if (id == null || id.isEmpty) {
    throw WorkflowParseException('stage at index $index missing "name"');
  }
  final kind = (stage['kind'] as String?) ?? 'worker';
  final label = (stage['label'] as String?) ?? id;
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

  // Kind-specific fields.
  final outputs = <BranchOutput>[];
  var matchAll = false;
  if (kind == 'branch') {
    final outsNode = stage['outputs'];
    if (outsNode is YamlList) {
      for (final o in outsNode) {
        if (o is! YamlMap) continue;
        outputs.add(BranchOutput(
          id: (o['id'] as String?) ?? '0',
          label: (o['label'] as String?) ?? '',
          expression: o['expression'] as String?,
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
          match: (cs['match'] as String?) ?? '',
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
        match: (b['match'] as String?) ?? '',
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
  );
}

WorkflowEdge _parseEdge(YamlMap e, int index) {
  final from = e['from'] as String? ?? '';
  final to = e['to'] as String? ?? '';
  final port = e['port'] as int?;
  final label = e['label'] as String?;
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
  return const [];
}
