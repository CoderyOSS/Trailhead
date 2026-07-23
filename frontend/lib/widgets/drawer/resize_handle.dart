import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// Slim drag handle for resizing drawer regions. Works with touch, finger
/// pad, and mouse (single GestureDetector path — drag gestures are
/// pointer-agnostic in Flutter).
///
/// Renders an 8px hit strip with a 1px centered line that highlights on
/// hover/drag. [axis] determines drag direction and hover cursor:
/// Axis.horizontal = drag left/right (vertical strip), Axis.vertical = drag
/// up/down (horizontal strip).
class ResizeHandle extends StatefulWidget {
  final Axis axis;

  /// Called continuously with the pointer delta along [axis] since the last
  /// update (px). Sign follows the drag direction.
  final ValueChanged<double> onDelta;

  /// Called when the drag ends (e.g. to persist the new size).
  final VoidCallback? onEnd;

  const ResizeHandle({
    super.key,
    required this.axis,
    required this.onDelta,
    this.onEnd,
  });

  @override
  State<ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<ResizeHandle> {
  bool _hovering = false;
  bool _dragging = false;

  bool get _active => _hovering || _dragging;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    return MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart:
            horizontal ? (_) => setState(() => _dragging = true) : null,
        onVerticalDragStart:
            horizontal ? null : (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate:
            horizontal ? (d) => widget.onDelta(d.delta.dx) : null,
        onVerticalDragUpdate:
            horizontal ? null : (d) => widget.onDelta(d.delta.dy),
        onHorizontalDragEnd: horizontal ? (_) => _endDrag() : null,
        onVerticalDragEnd: horizontal ? null : (_) => _endDrag(),
        onHorizontalDragCancel: horizontal ? _cancelDrag : null,
        onVerticalDragCancel: horizontal ? null : _cancelDrag,
        child: SizedBox(
          width: horizontal ? 8 : double.infinity,
          height: horizontal ? double.infinity : 8,
          child: Center(
            child: Container(
              width: horizontal ? 1 : double.infinity,
              height: horizontal ? double.infinity : 1,
              color: _active ? AppColors.accent : AppColors.border1,
            ),
          ),
        ),
      ),
    );
  }

  void _endDrag() {
    setState(() => _dragging = false);
    widget.onEnd?.call();
  }

  void _cancelDrag() {
    setState(() => _dragging = false);
  }
}
