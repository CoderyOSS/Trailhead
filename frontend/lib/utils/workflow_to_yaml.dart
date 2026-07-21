import '../providers/mock_data.dart';
import '../models/server_def.dart';

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
  if (workflow.project != null) {
    buf.writeln('project: ${workflow.project}');
  }

  // Servers section
  if (workflow.servers.isNotEmpty) {
    buf.writeln('servers:');
    for (final s in workflow.servers) {
      buf.writeln('  - id: ${s.id}');
      buf.writeln('    port: ${s.port}');
      buf.writeln('    scheme: ${s.scheme}');
      if (s.tlsCert != null) buf.writeln('    tls_cert: "${s.tlsCert}"');
      if (s.tlsKey != null) buf.writeln('    tls_key: "${s.tlsKey}"');
      if (s.cors != null) {
        buf.writeln('    cors:');
        buf.writeln('      origins: [${s.cors!.origins.map((o) => '"$o"').join(', ')}]');
        buf.writeln('      methods: [${s.cors!.methods.map((m) => '"$m"').join(', ')}]');
        buf.writeln('      headers: [${s.cors!.headers.map((h) => '"$h"').join(', ')}]');
      }
    }
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

      // Function outputs (routing). The transform expression is NOT emitted
      // here — it folds into the single `config:` block below so logging
      // flags and expr never produce duplicate `config:` keys (YAML keeps
      // only the last duplicate, silently dropping the expr).
      if (node.kind == 'function') {
        if (node.expr == null && node.outputs.isNotEmpty) {
          if (node.matchAll) {
            buf.writeln('    match_all: true');
          }
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
      final wantsConfig = node.kind == 'delay' ||
          node.kind == 'http.server.ingress' ||
          node.kind == 'http.server.egress' ||
          node.kind == 'http.client.request' ||
          node.kind == 'source.inject' ||
          node.kind == 'subflow' ||
          (node.kind == 'function' && node.expr != null) ||
          node.loggingEnabled ||
          node.logIn ||
          node.logOut;

      if (wantsConfig) {
        // Build child lines first — a bare `config:` header with no entries
        // parses as nil server-side and crashes node init.
        final configLines = <String>[];
        // Function expr as block scalar — avoids quote-escaping bugs with
        // exprs containing double quotes, and keeps a single config block.
        if (node.kind == 'function' && node.expr != null) {
          configLines.add('      expr: |');
          for (final line in node.expr!.split('\n')) {
            configLines.add('        $line');
          }
        }
        if (node.kind == 'delay' && node.intervalMs != null) {
          configLines.add('      interval_ms: ${node.intervalMs}');
        }
        if (node.kind == 'http.server.ingress') {
          if (node.httpIngressServer != null) configLines.add('      server: "${node.httpIngressServer}"');
          if (node.httpIngressMethod != null) configLines.add('      method: ${node.httpIngressMethod}');
          if (node.httpIngressPath != null) configLines.add('      path: "${node.httpIngressPath}"');
        }
        if (node.kind == 'http.server.egress') {
          if (node.httpEgressServer != null) configLines.add('      server: "${node.httpEgressServer}"');
          if (node.httpEgressStatus != null) configLines.add('      status: ${node.httpEgressStatus}');
          if (node.httpEgressContentType != null) configLines.add('      content_type: "${node.httpEgressContentType}"');
          if (node.httpEgressBody != null) configLines.add('      body: ${_yamlValue(node.httpEgressBody)}');
        }
        if (node.kind == 'http.client.request') {
          if (node.httpRequestUrl != null) configLines.add('      url: "${node.httpRequestUrl}"');
          if (node.httpRequestMethod != null) configLines.add('      method: ${node.httpRequestMethod}');
        }
        if (node.kind == 'source.inject') {
          if (node.payloadCode != null && node.payloadCode!.isNotEmpty) {
            final key = node.payloadIsExpr ? 'payload_expr' : 'payload_code';
            configLines.add('      $key: |');
            for (final line in node.payloadCode!.split('\n')) {
              configLines.add('        $line');
            }
          }
          if (node.once == true) configLines.add('      once: true');
          if (node.intervalMs != null) configLines.add('      interval_ms: ${node.intervalMs}');
        }
        if (node.loggingEnabled) configLines.add('      logging_enabled: true');
        if (node.logIn) configLines.add('      log_in: true');
        if (node.logOut) configLines.add('      log_out: true');

        // Subflow nodes — emit `subflow:` plus one entry per param. The
        // node.config map carries the full payload (key 'subflow' is the
        // "module/subflow" identifier; remaining keys are param values).
        if (node.kind == 'subflow' && node.config != null) {
          for (final entry in node.config!.entries) {
            configLines.add('      ${entry.key}: ${_yamlValue(entry.value)}');
          }
        }

        if (configLines.isNotEmpty) {
          buf.writeln('    config:');
          for (final line in configLines) {
            buf.writeln(line);
          }
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
