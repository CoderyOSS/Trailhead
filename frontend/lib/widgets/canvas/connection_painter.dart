import 'dart:math' show atan2, cos, sin;
import 'package:flutter/material.dart';
import '../../models/workflow_edge.dart';
import '../../models/workflow_node.dart';
import '../../providers/connection_drag_provider.dart';
import '../../theme/theme_controller.dart';
import '../../theme/tokens.dart';
import '../../utils/connection_validator.dart';

/// Breaks [source] into alternating dash/gap segments and returns a new
/// [Path] containing only the dash portions.
///
/// Used to render message connections (dashed bezier). [dash] is the visible
/// segment length; [gap] is the space between dashes. Both in the same
/// coordinate space as the path.
Path dashPath(Path source, {required double dash, required double gap}) {
  final result = Path();
  final stride = dash + gap;
  if (stride <= 0) return result;
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final legEnd = (distance + dash).clamp(0.0, metric.length);
      if (legEnd > distance) {
        result.addPath(
          metric.extractPath(distance, legEnd),
          Offset.zero,
        );
      }
      distance += stride;
    }
  }
  return result;
}

/// Painter for workflow connections.
///
/// Each connection is classified from its target node:
///   - target.isActor → message → **dashed** bezier (`send/2` semantics)
///   - else           → pipe    → **solid** bezier (`|>` semantics)
///
/// Invalid connections (over-piped source, dangling refs) render in
/// [AppColors.danger] so the user sees the broken state. Validation is
/// derived at construction time via [ConnectionValidator] — no state drift.
class ConnectionPainter extends CustomPainter {
  final List<WorkflowNode> nodes;
  final List<WorkflowConnection> connections;
  final String? draggingNodeId;
  final Offset dragOffset;
  final Set<String> selectedIds;
  final ConnectionDragState? connectionDrag;

  /// IDs of connections that violate a validation rule (over-piped source or
  /// dangling endpoint reference). Derived at construction from [nodes] +
  /// [connections] via [ConnectionValidator.invalidIds]. Rendered red.
  final Set<String> invalidIds;

  /// Dash pattern for message connections (spec §6.2.3 suggests 6/4).
  static const double messageDash = 6.0;
  static const double messageGap = 4.0;

  static const double _controlMin = 40.0;
  static const double _controlMax = 150.0;

  ConnectionPainter({
    required this.nodes,
    required this.connections,
    this.draggingNodeId,
    this.dragOffset = Offset.zero,
    this.selectedIds = const {},
    this.connectionDrag,
    Set<String>? invalidIds,
  })  : invalidIds = invalidIds ??
            ConnectionValidator.invalidIds(
              connections,
              {for (final n in nodes) n.id: n},
            ),
        super(repaint: ThemeController());

  Offset _nodePos(WorkflowNode node) {
    final inGroupDrag = draggingNodeId != null &&
        selectedIds.length > 1 &&
        selectedIds.contains(draggingNodeId) &&
        selectedIds.contains(node.id);
    if (draggingNodeId == node.id || inGroupDrag) {
      return Offset(node.x + dragOffset.dx, node.y + dragOffset.dy);
    }
    return Offset(node.x, node.y);
  }

  Offset _exitPoint(WorkflowNode node, WorkflowConnection conn) {
    final pos = _nodePos(node);
    if (node.kind == 'function' && node.outputs.isNotEmpty) {
      return _branchExitPoint(node, pos, conn.sourcePort);
    }
    return Offset(pos.dx + node.width, pos.dy + node.height / 2);
  }

  Offset _entryPoint(WorkflowNode node) {
    final pos = _nodePos(node);
    return Offset(pos.dx, pos.dy + node.height / 2);
  }

  Offset _handlePoint(WorkflowNode node, bool isOutput, int? port) {
    final pos = _nodePos(node);
    if (isOutput) {
      if (node.kind == 'function' && node.outputs.isNotEmpty) {
        return _branchExitPoint(node, pos, port);
      }
      return Offset(pos.dx + node.width, pos.dy + node.height / 2);
    }
    return Offset(pos.dx, pos.dy + node.height / 2);
  }

  Offset _branchExitPoint(WorkflowNode node, Offset pos, int? sourcePort) {
    if (sourcePort == null || node.outputs.isEmpty) {
      return Offset(pos.dx + node.width, pos.dy + node.height / 2);
    }
    final y = pos.dy +
        WorkflowNode.branchPadY +
        sourcePort * WorkflowNode.branchRowHeight +
        WorkflowNode.branchRowHeight / 2;
    return Offset(pos.dx + node.width, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final n in nodes) n.id: n};

    for (final conn in connections) {
      final source = nodeMap[conn.from];
      final target = nodeMap[conn.to];
      if (source == null || target == null) continue;

      final p0 = _exitPoint(source, conn);
      final p3 = _entryPoint(target);

      final dx = (p3.dx - p0.dx).abs();
      final controlLen = dx.clamp(_controlMin, _controlMax);

      final p1 = Offset(p0.dx + controlLen, p0.dy);
      final p2 = Offset(p3.dx - controlLen, p3.dy);

      final isMessage = target.isActor; // message → dashed; pipe → solid
      final isInvalid = invalidIds.contains(conn.id);
      final strokeColor = isInvalid ? AppColors.danger : AppColors.border3;

      final linePaint = Paint()
        ..color = strokeColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final arrowPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);

      if (isMessage) {
        // Message connection → dashed bezier.
        canvas.drawPath(
          dashPath(path, dash: messageDash, gap: messageGap),
          linePaint,
        );
      } else {
        canvas.drawPath(path, linePaint);
      }

      // Arrowhead at target end (always solid — even on dashed messages).
      final tangent = Offset(p3.dx - p2.dx, p3.dy - p2.dy);
      _drawArrowhead(canvas, p3, tangent, arrowPaint);
    }

    // Temporary drag line (always solid regardless of inferred type —
    // classification + validation happens on drop, not during drag).
    final drag = connectionDrag;
    if (drag != null) {
      final source = nodeMap[drag.sourceNodeId];
      if (source != null) {
        final p0 = _handlePoint(
          source,
          drag.sourceIsOutput,
          drag.sourcePort,
        );
        final p3 = drag.targetNodeId != null
            ? (() {
                final target = nodeMap[drag.targetNodeId!];
                if (target == null) return drag.currentWorldPos;
                return _handlePoint(
                  target,
                  drag.targetIsOutput!,
                  drag.targetPort,
                );
              })()
            : drag.currentWorldPos;

        final dx = (p3.dx - p0.dx).abs();
        final controlLen = dx.clamp(_controlMin, _controlMax);

        final p1 = Offset(p0.dx + controlLen, p0.dy);
        final p2 = Offset(p3.dx - controlLen, p3.dy);

        final dragLinePaint = Paint()
          ..color = AppColors.border3
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final dragArrowPaint = Paint()
          ..color = AppColors.border3
          ..style = PaintingStyle.fill;

        final dragPath = Path()
          ..moveTo(p0.dx, p0.dy)
          ..cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, p3.dx, p3.dy);
        canvas.drawPath(dragPath, dragLinePaint);

        final tangent = Offset(p3.dx - p2.dx, p3.dy - p2.dy);
        _drawArrowhead(canvas, p3, tangent, dragArrowPaint);
      }
    }
  }

  void _drawArrowhead(Canvas canvas, Offset tip, Offset tangent, Paint paint) {
    final angle = atan2(tangent.dy, tangent.dx);
    const headLen = 7.0;
    const headAngle = 0.45;

    final p1 = Offset(
      tip.dx - headLen * cos(angle - headAngle),
      tip.dy - headLen * sin(angle - headAngle),
    );
    final p2 = Offset(
      tip.dx - headLen * cos(angle + headAngle),
      tip.dy - headLen * sin(angle + headAngle),
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  bool _setsEqual(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter old) {
    return old.nodes != nodes ||
        old.connections != connections ||
        old.draggingNodeId != draggingNodeId ||
        old.dragOffset != dragOffset ||
        old.connectionDrag != connectionDrag ||
        !_setsEqual(old.invalidIds, invalidIds) ||
        !_setsEqual(old.selectedIds, selectedIds);
  }
}
