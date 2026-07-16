import 'dart:ui' show Path;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/workflow_edge.dart';
import 'package:frontend/models/workflow_node.dart';
import 'package:frontend/widgets/canvas/connection_painter.dart';

WorkflowNode _node(String id, String kind, {double x = 0, double y = 0}) =>
    WorkflowNode(id: id, kind: kind, label: id, x: x, y: y);

void main() {
  group('ConnectionPainter API', () {
    final nodes = [
      _node('src', 'source.inject', x: 0, y: 0),
      _node('fn', 'function', x: 200, y: 0),
      _node('actor', 'genserver', x: 200, y: 100),
    ];

    test('painter exposes the connections it was constructed with', () {
      final conns = [
        WorkflowConnection(id: 'c1', from: 'src', to: 'fn'),
        WorkflowConnection(id: 'c2', from: 'src', to: 'actor'),
      ];
      final painter = ConnectionPainter(nodes: nodes, connections: conns);
      expect(painter.connections, conns);
    });

    test('painter accepts an invalidIds override for red rendering', () {
      // The painter must support deriving invalid IDs from connections+nodes
      // at construction time so it can render broken connections red without
      // duplicating validator logic.
      final conns = [
        WorkflowConnection(id: 'c1', from: 'src', to: 'fn'),
        WorkflowConnection(id: 'c2', from: 'src', to: 'fn'),
      ];
      final painter = ConnectionPainter(nodes: nodes, connections: conns);
      expect(painter.invalidIds, {'c1', 'c2'});
    });
  });

  group('ConnectionPainter.shouldRepaint', () {
    test('repaint when connections list identity changes', () {
      final nodes = [_node('a', 'function'), _node('b', 'genserver')];
      final c1 = [WorkflowConnection(id: 'x', from: 'a', to: 'b')];
      final c2 = [WorkflowConnection(id: 'y', from: 'a', to: 'b')];
      final p1 = ConnectionPainter(nodes: nodes, connections: c1);
      final p2 = ConnectionPainter(nodes: nodes, connections: c2);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('no repaint when all inputs equal', () {
      final nodes = [_node('a', 'function'), _node('b', 'genserver')];
      final conns = [WorkflowConnection(id: 'x', from: 'a', to: 'b')];
      final p1 = ConnectionPainter(nodes: nodes, connections: conns);
      final p2 = ConnectionPainter(nodes: nodes, connections: conns);
      expect(p1.shouldRepaint(p2), isFalse);
    });

    test('repaint when invalidIds set changes', () {
      // Two painters with same nodes/connections but different invalid IDs
      // (because node kinds differ) must repaint.
      final nodes1 = [
        _node('src', 'function'),
        _node('t1', 'function'),
        _node('t2', 'function'),
      ];
      final nodes2 = [
        _node('src', 'function'),
        _node('t1', 'genserver'), // changed kind: now a message, not a pipe
        _node('t2', 'function'),
      ];
      final conns = [
        WorkflowConnection(id: 'c1', from: 'src', to: 't1'),
        WorkflowConnection(id: 'c2', from: 'src', to: 't2'),
      ];
      final p1 = ConnectionPainter(nodes: nodes1, connections: conns);
      final p2 = ConnectionPainter(nodes: nodes2, connections: conns);
      expect(p1.shouldRepaint(p2), isTrue);
      expect(p1.invalidIds, {'c1', 'c2'}); // both pipes from src
      expect(p2.invalidIds, isEmpty); // c1 became a message; only 1 pipe now
    });
  });

  group('dashPath helper', () {
    test('produces non-empty output for a non-empty source', () {
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      final dashed = dashPath(source, dash: 6, gap: 4);
      final totalLength = dashed.computeMetrics().fold<double>(0.0,
          (prev, m) => prev + m.length);
      // Total visible length should be > 0 and less than full 100px (gaps).
      expect(totalLength, greaterThan(0));
      expect(totalLength, lessThan(100));
    });

    test('renders roughly dash/(dash+gap) of the source length', () {
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(1000, 0);
      final dashed = dashPath(source, dash: 6, gap: 4);
      final totalLength = dashed.computeMetrics().fold<double>(0.0,
          (prev, m) => prev + m.length);
      // Expect ~60% of 1000 = 600, allow tolerance for end boundary.
      expect(totalLength, inInclusiveRange(580, 600));
    });

    test('empty source → empty dashed path', () {
      final source = Path();
      final dashed = dashPath(source, dash: 6, gap: 4);
      expect(dashed.computeMetrics().isEmpty, isTrue);
    });

    test('source shorter than one dash → single truncated segment', () {
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(3, 0); // shorter than dash=6
      final dashed = dashPath(source, dash: 6, gap: 4);
      final totalLength = dashed.computeMetrics().fold<double>(0.0,
          (prev, m) => prev + m.length);
      expect(totalLength, 3.0);
    });
  });
}
