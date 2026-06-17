import '../models/workflow_edge.dart';
import '../models/workflow_node.dart';
import '../providers/mock_data.dart';

String workflowToYaml(WorkflowSummary workflow) {
  final buf = StringBuffer();
  buf.writeln('name: ${workflow.name}');
  buf.writeln('version: ${workflow.version}');
  if (workflow.draft != null && workflow.draft != workflow.version) {
    buf.writeln('draft: ${workflow.draft}');
  }
  buf.writeln('');

  if (workflow.nodes.isNotEmpty) {
    buf.writeln('stages:');
    for (final node in workflow.nodes) {
      buf.writeln('  - name: ${node.id}');
      buf.writeln('    kind: ${node.kind}');
      buf.writeln('    label: ${node.label}');
      if (node.sub != null) buf.writeln('    sub: "${node.sub}"');
      if (node.model != null) buf.writeln('    model: ${node.model}');
      if (node.skills.isNotEmpty) {
        buf.writeln('    skills: [${node.skills.map((s) => '"$s"').join(', ')}]');
      }
      if (node.kind == 'branch') {
        if (node.matchAll) {
          buf.writeln('    match_all: true');
        }
        if (node.outputs.isNotEmpty) {
          buf.writeln('    outputs:');
          for (final out in node.outputs) {
            buf.writeln('      - id: ${out.id}');
            buf.writeln('        label: ${out.label}');
            if (out.expression != null && out.expression!.isNotEmpty) {
              buf.writeln('        expression: "${out.expression}"');
            }
          }
        }
      }
      buf.writeln('    pos: {x: ${node.x.toStringAsFixed(0)}, y: ${node.y.toStringAsFixed(0)}}');
    }
    buf.writeln('');
  }

  if (workflow.edges.isNotEmpty) {
    buf.writeln('edges:');
    for (final edge in workflow.edges) {
      buf.writeln('  - from: ${edge.sourceId}');
      buf.writeln('    to: ${edge.targetId}');
      if (edge.sourcePort != null) {
        buf.writeln('    port: ${edge.sourcePort}');
      }
    }
  }

  return buf.toString();
}
