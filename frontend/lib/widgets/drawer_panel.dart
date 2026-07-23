import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_node.dart';
import '../providers/drawer_provider.dart';
import '../theme/tokens.dart';
import 'drawer/resize_handle.dart';
import 'node_drawer/node_drawer.dart';
import 'log_drawer/log_drawer.dart';

/// Unified drawer: settings (node details) and logs in a single panel with
/// a header view switcher (logs | settings | both), an internal split
/// direction toggle (horizontal/vertical), and drag-resize handles on the
/// outer edge (drawer ↔ graph) and between the two panes.
///
/// The outer extent is owned by the shell (SizedBox width in landscape,
/// height in portrait); this widget renders the leading-edge handle that
/// adjusts it. The settings pane shows an empty state when [node] is null.
class UnifiedDrawer extends ConsumerWidget {
  final WorkflowNode? node;
  final NodeDrawerView view;

  /// Key applied to the NodeDrawer so per-node editor state is preserved
  /// the same way it was before the merge.
  final Key nodeKey;
  final VoidCallback onClose;
  final bool isPortrait;

  /// When true (Active mode) the drawer is forced open and the close
  /// affordance is hidden.
  final bool forcedOpen;

  const UnifiedDrawer({
    super.key,
    required this.node,
    required this.view,
    required this.nodeKey,
    required this.onClose,
    this.isPortrait = false,
    this.forcedOpen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(drawerViewModeProvider);
    final layout = ref.watch(drawerLayoutProvider);
    final split = ref.watch(drawerSplitProvider);

    final screen = MediaQuery.of(context).size;

    void onOuterDelta(double delta) {
      // Leading edge: dragging outward grows the drawer. In landscape the
      // handle sits on the drawer's left edge, so drawer width grows as the
      // pointer moves left (negative dx). In portrait it sits on the top
      // edge, so height grows as the pointer moves up (negative dy).
      final cur = ref.read(drawerSizeProvider);
      final next = isPortrait
          ? (landscape: cur.landscape, portrait: cur.portrait - delta)
          : (landscape: cur.landscape - delta, portrait: cur.portrait);
      ref.read(drawerSizeProvider.notifier).state = (
        landscape: clampDrawerExtent(next.landscape, false, screen),
        portrait: clampDrawerExtent(next.portrait, true, screen),
      );
    }

    final outerHandle = ResizeHandle(
      axis: isPortrait ? Axis.vertical : Axis.horizontal,
      onDelta: onOuterDelta,
      onEnd: () => scheduleDrawerPrefsSave(ref),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DrawerHeader(
          viewMode: viewMode,
          layout: layout,
          showClose: !forcedOpen,
          onClose: onClose,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalSplit = layout == DrawerSplitLayout.horizontal;
              final total = horizontalSplit
                  ? constraints.maxWidth
                  : constraints.maxHeight;
              final frac = clampDrawerSplit(split, total);

              Widget settingsPane = NodeDrawer(
                key: nodeKey,
                node: node,
                view: view,
                onClose: onClose,
                isPortrait: isPortrait,
              );
              const logsPane = LogDrawer();

              if (viewMode == DrawerViewMode.logs) return logsPane;
              if (viewMode == DrawerViewMode.settings) return settingsPane;

              final logsExtent = total * frac;
              void onSplitDelta(double delta) {
                if (total <= 0) return;
                final next = (logsExtent + delta) / total;
                ref.read(drawerSplitProvider.notifier).state =
                    clampDrawerSplit(next, total);
              }

              final handle = ResizeHandle(
                axis: horizontalSplit ? Axis.horizontal : Axis.vertical,
                onDelta: onSplitDelta,
                onEnd: () => scheduleDrawerPrefsSave(ref),
              );

              final first = horizontalSplit
                  ? SizedBox(width: logsExtent, child: logsPane)
                  : SizedBox(height: logsExtent, child: logsPane);

              if (horizontalSplit) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [first, handle, Expanded(child: settingsPane)],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [first, handle, Expanded(child: settingsPane)],
              );
            },
          ),
        ),
      ],
    );

    return Container(
      color: AppColors.bg1,
      child: isPortrait
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [outerHandle, Expanded(child: content)],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [outerHandle, Expanded(child: content)],
            ),
    );
  }
}

class _DrawerHeader extends ConsumerWidget {
  final DrawerViewMode viewMode;
  final DrawerSplitLayout layout;
  final bool showClose;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.viewMode,
    required this.layout,
    required this.showClose,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border(bottom: BorderSide(color: AppColors.border1)),
      ),
      child: Row(
        children: [
          _ViewModeSegmented(current: viewMode),
          const Spacer(),
          if (viewMode == DrawerViewMode.both)
            _HeaderIconButton(
              icon: layout == DrawerSplitLayout.horizontal
                  ? Icons.swap_horiz
                  : Icons.swap_vert,
              tooltip: layout == DrawerSplitLayout.horizontal
                  ? 'stack panes vertically'
                  : 'arrange panes side by side',
              onTap: () {
                ref.read(drawerLayoutProvider.notifier).state =
                    layout == DrawerSplitLayout.horizontal
                        ? DrawerSplitLayout.vertical
                        : DrawerSplitLayout.horizontal;
                scheduleDrawerPrefsSave(ref);
              },
            ),
          if (showClose)
            _HeaderIconButton(
              icon: Icons.close,
              tooltip: 'close drawer',
              onTap: onClose,
            ),
        ],
      ),
    );
  }
}

class _ViewModeSegmented extends ConsumerWidget {
  final DrawerViewMode current;

  const _ViewModeSegmented({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final mode in DrawerViewMode.values) ...[
            _Segment(
              label: mode.name,
              active: current == mode,
              onTap: () {
                ref.read(drawerViewModeProvider.notifier).state = mode;
                scheduleDrawerPrefsSave(ref);
              },
            ),
            if (mode != DrawerViewMode.values.last) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.bg3
                : (_hovering ? AppColors.bg2 : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              bottom: BorderSide(
                color: widget.active ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
              color: widget.active ? AppColors.fg0 : AppColors.fg3,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: _hovering ? AppColors.bg3 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 14, color: AppColors.fg2),
          ),
        ),
      ),
    );
  }
}
