import '../providers/mock_data.dart';

class YamlResult {
  final String yaml;
  final Map<String, ({int start, int end})> nodeLines;

  const YamlResult({required this.yaml, required this.nodeLines});
}

YamlResult workflowToYamlWithLines(WorkflowSummary workflow) {
  final buf = StringBuffer();
  final nodeLines = <String, ({int start, int end})>{};

  buf.writeln('name: ${workflow.name}');
  buf.writeln('version: ${workflow.version}');
  if (workflow.draft != null && workflow.draft != workflow.version) {
    buf.writeln('draft: ${workflow.draft}');
  }
  buf.writeln('');

  if (workflow.nodes.isNotEmpty) {
    buf.writeln('nodes:');
    for (final node in workflow.nodes) {
      final startLine = buf.toString().split('\n').length;
      buf.writeln('  - id: "${node.id}"');
      buf.writeln('    type: ${node.kind}');
      buf.writeln('    label: "${node.label}"');
      if (node.sub != null) buf.writeln('    sub: "${node.sub}"');
      if (node.model != null) buf.writeln('    model: ${node.model}');
      if (node.skills.isNotEmpty) {
        buf.writeln('    skills: [${node.skills.map((s) => '"$s"').join(', ')}]');
      }

      // Worker-specific fields
      if (node.connection != null) {
        buf.writeln('    connection: ${node.connection}');
      }
      if (node.timeout != null) {
        buf.writeln('    timeout: ${node.timeout}');
      }
      if (node.retries != null) {
        buf.writeln('    retries: ${node.retries}');
      }
      if (node.parallelism != null) {
        buf.writeln('    parallelism: ${node.parallelism}');
      }
      if (node.configs.isNotEmpty) {
        buf.writeln('    configs: [${node.configs.map((c) => '"$c"').join(', ')}]');
      }

      // Prompt
      if (node.prompt != null && node.prompt!.isNotEmpty) {
        buf.writeln('    prompt: |');
        for (final line in node.prompt!.split('\n')) {
          buf.writeln('      $line');
        }
      }

      // Result format + schema
      if (node.resultFormat != null) {
        buf.writeln('    result_format: ${node.resultFormat}');
      }
      if (node.schema != null && node.schema!.isNotEmpty) {
        buf.writeln('    schema:');
        _writeJson(buf, node.schema!, indent: 6);
      }

      // Function outputs
      if (node.kind == 'function') {
        if (node.matchAll) {
          buf.writeln('    match_all: true');
        }
        if (node.outputs.isNotEmpty) {
          buf.writeln('    outputs:');
          for (final out in node.outputs) {
            buf.writeln('      - id: "${out.id}"');
            buf.writeln('        label: "${out.label}"');
            if (out.expression != null && out.expression!.isNotEmpty) {
              buf.writeln('        expression: "${out.expression}"');
            }
          }
        }
      }

      // Node kinds with config sub-map
      if (node.kind == 'delay' || node.kind == 'http.ingress' || node.kind == 'http.egress' || node.kind == 'http.request' || node.kind == 'source.inject') {
        buf.writeln('    config:');
        if (node.kind == 'delay' && node.intervalMs != null) {
          buf.writeln('      interval_ms: ${node.intervalMs}');
        }
        if (node.kind == 'http.ingress') {
          if (node.httpIngressServer != null) buf.writeln('      server: "${node.httpIngressServer}"');
          if (node.httpIngressMethod != null) buf.writeln('      method: ${node.httpIngressMethod}');
          if (node.httpIngressPath != null) buf.writeln('      path: "${node.httpIngressPath}"');
        }
        if (node.kind == 'http.egress') {
          if (node.httpEgressStatus != null) buf.writeln('      status: ${node.httpEgressStatus}');
          if (node.httpEgressContentType != null) buf.writeln('      content_type: "${node.httpEgressContentType}"');
          if (node.httpEgressBody != null) buf.writeln('      body: "${node.httpEgressBody}"');
        }
        if (node.kind == 'http.request') {
          if (node.httpRequestServer != null) buf.writeln('      server: "${node.httpRequestServer}"');
          if (node.httpRequestMethod != null) buf.writeln('      method: ${node.httpRequestMethod}');
          if (node.httpRequestPath != null) buf.writeln('      path: "${node.httpRequestPath}"');
        }
      }

      // Join fields
      if (node.kind == 'join') {
        if (node.waitsFor.isNotEmpty) {
          buf.writeln('    waits_for: [${node.waitsFor.map((w) => '"$w"').join(', ')}]');
        }
        if (node.joinMode != null) buf.writeln('    mode: ${node.joinMode}');
      }

      // Switch cases
      if (node.cases.isNotEmpty) {
        buf.writeln('    cases:');
        for (final c in node.cases) {
          buf.writeln('      - match: "${c.match}"');
          buf.writeln('        to: [${c.to.map((t) => '"$t"').join(', ')}]');
        }
      }

      // Branch cases
      if (node.branches.isNotEmpty) {
        buf.writeln('    branches:');
        for (final b in node.branches) {
          buf.writeln('      - match: "${b.match}"');
          buf.writeln('        to: [${b.to.map((t) => '"$t"').join(', ')}]');
          if (b.loop) buf.writeln('        loop: true');
        }
      }

      buf.writeln('    pos: {x: ${node.x.toStringAsFixed(0)}, y: ${node.y.toStringAsFixed(0)}}');
      final endLine = buf.toString().split('\n').length - 1;
      nodeLines[node.id] = (start: startLine, end: endLine);
    }
    buf.writeln('');
  }

  if (workflow.connections.isNotEmpty) {
    buf.writeln('connections:');
    for (final conn in workflow.connections) {
      buf.writeln('  - from: "${conn.from}"');
      buf.writeln('    to: "${conn.to}"');
    }
  }

  return YamlResult(yaml: buf.toString(), nodeLines: nodeLines);
}

String workflowToYaml(WorkflowSummary workflow) {
  return workflowToYamlWithLines(workflow).yaml;
}

void _writeJson(StringBuffer buf, dynamic value, {required int indent}) {
  final prefix = ' ' * indent;
  if (value is Map) {
    for (final entry in value.entries) {
      final k = entry.key;
      final v = entry.value;
      if (v is Map || v is List) {
        buf.writeln('$prefix$k:');
        _writeJson(buf, v, indent: indent + 2);
      } else {
        buf.writeln('$prefix$k: ${_yamlValue(v)}');
      }
    }
  } else if (value is List) {
    for (final item in value) {
      if (item is Map || item is List) {
        buf.writeln('$prefix-');
        _writeJson(buf, item, indent: indent + 2);
      } else {
        buf.writeln('$prefix- ${_yamlValue(item)}');
      }
    }
  } else {
    buf.writeln('$prefix${_yamlValue(value)}');
  }
}

String _yamlValue(dynamic v) {
  if (v == null) return 'null';
  if (v is bool) return v.toString();
  if (v is num) return v.toString();
  if (v is String) {
    if (v.contains('\n') || v.contains(':') || v.contains('#')) {
      return '"${v.replaceAll('"', '\\"')}"';
    }
    return v;
  }
  return v.toString();
}
