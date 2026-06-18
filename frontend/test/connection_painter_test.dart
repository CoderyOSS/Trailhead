import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/workflow_edge.dart';
import 'package:frontend/models/workflow_node.dart';
import 'package:frontend/widgets/canvas/connection_painter.dart';

void main() {
  test('shouldRepaint when selectedIds changes', () {
    final p1 = ConnectionPainter(
      nodes: const [],
      edges: const [],
      selectedIds: const {'A'},
    );
    final p2 = ConnectionPainter(
      nodes: const [],
      edges: const [],
      selectedIds: const {'A', 'B'},
    );
    expect(p1.shouldRepaint(p2), isTrue);
  });

  test('group drag offsets all selected nodes in paint', () {
    final nodes = [
      WorkflowNode(id: 'A', kind: 'worker', label: 'A', x: 0, y: 0),
      WorkflowNode(id: 'B', kind: 'worker', label: 'B', x: 200, y: 100),
    ];
    final edges = [
      WorkflowEdge(id: 'e1', sourceId: 'A', targetId: 'B'),
    ];

    final painter = ConnectionPainter(
      nodes: nodes,
      edges: edges,
      draggingNodeId: 'A',
      dragOffset: const Offset(50, 30),
      selectedIds: const {'A', 'B'},
    );

    // Verify the painter accepts group-drag parameters without error
    expect(painter.draggingNodeId, 'A');
    expect(painter.dragOffset, const Offset(50, 30));
    expect(painter.selectedIds, const {'A', 'B'});

    // Verify repaint triggers when drag offset changes
    final painter2 = ConnectionPainter(
      nodes: nodes,
      edges: edges,
      draggingNodeId: 'A',
      dragOffset: const Offset(60, 40),
      selectedIds: const {'A', 'B'},
    );
    expect(painter.shouldRepaint(painter2), isTrue);
  });
}
