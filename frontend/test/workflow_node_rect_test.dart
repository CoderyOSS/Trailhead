import 'dart:ui' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/workflow_node.dart';

void main() {
  group('WorkflowNodeRect', () {
    test('worker rect is 168x36 at (x,y)', () {
      final n = const WorkflowNode(id: 'w', kind: 'worker', label: 'w', x: 10, y: 20);
      expect(n.width, 168.0);
      expect(n.height, 36.0);
      expect(n.rect, const Rect.fromLTWH(10, 20, 168, 36));
    });

    test('fan rect is 168x36 at (x,y)', () {
      final n = const WorkflowNode(id: 'f', kind: 'fan', label: 'f', x: 0, y: 0);
      expect(n.width, 168.0);
      expect(n.height, 36.0);
    });

    test('branch with outputs uses outputs.length', () {
      final n = WorkflowNode(
        id: 'b', kind: 'branch', label: 'b', x: 5, y: 6,
        outputs: const [
          BranchOutput(id: '0', label: 'a'),
          BranchOutput(id: '1', label: 'b'),
          BranchOutput(id: '2', label: 'c'),
        ],
      );
      // padY*2 + 3*rowHeight = 9*2 + 3*27 = 99
      expect(n.width, 130.0);
      expect(n.height, 99.0);
    });

    test('branch rect composes correctly', () {
      final n = WorkflowNode(
        id: 'b', kind: 'branch', label: 'b', x: 5, y: 6,
        outputs: const [BranchOutput(id: '0', label: 'a')],
      );
      // padY*2 + 1*rowHeight = 18 + 27 = 45
      expect(n.rect, const Rect.fromLTWH(5, 6, 130, 45));
    });

    test('branch with no outputs defaults to defaultBranchOutputs.length rows', () {
      const n = WorkflowNode(id: 'b', kind: 'branch', label: 'b', x: 0, y: 0);
      expect(
        n.height,
        WorkflowNode.branchPadY * 2 +
            WorkflowNode.defaultBranchOutputs.length *
                WorkflowNode.branchRowHeight,
      );
      // defaultBranchOutputs has 4 entries -> 9*2 + 4*27 = 126
      expect(n.height, 126.0);
    });
  });
}
