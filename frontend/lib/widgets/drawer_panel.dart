import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_node.dart';
import '../providers/mode_provider.dart';
import '../theme/tokens.dart';
import 'node_drawer/node_drawer.dart';
import 'log_drawer/log_drawer.dart';

/// Top-level drawer panel with [NODE | LOG] tab switcher.
///
/// In builder mode the tabs are hidden and only the NodeDrawer renders.
/// In active mode (job view) both tabs are visible; the LogDrawer ignores
/// node selection entirely.
class DrawerPanel extends ConsumerWidget {
  final WorkflowNode node;
  final NodeDrawerView view;
  final VoidCallback onClose;
  final bool isPortrait;

  const DrawerPanel({
    super.key,
    required this.node,
    required this.view,
    required this.onClose,
    this.isPortrait = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBuilder = view == NodeDrawerView.builder;
    if (isBuilder) {
      return NodeDrawer(
        node: node,
        view: view,
        onClose: onClose,
        isPortrait: isPortrait,
      );
    }

    final panel = ref.watch(drawerPanelProvider);

    return Container(
      width: isPortrait ? double.infinity : 460,
      height: isPortrait ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(
          top: isPortrait
              ? BorderSide(color: AppColors.border1, width: 1)
              : BorderSide.none,
          left: isPortrait
              ? BorderSide.none
              : BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTabs(active: panel),
          Expanded(
            child: panel == 'log'
                ? const LogDrawer()
                : NodeDrawer(
                    node: node,
                    view: view,
                    onClose: onClose,
                    isPortrait: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PanelTabs extends ConsumerWidget {
  final String active;

  const _PanelTabs({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border(bottom: BorderSide(color: AppColors.border1, width: 1)),
      ),
      child: Row(
        children: [
          _PanelTab(value: 'node', label: 'node', active: active),
          _PanelTab(value: 'log', label: 'log', active: active),
        ],
      ),
    );
  }
}

class _PanelTab extends ConsumerWidget {
  final String value;
  final String label;
  final String active;

  const _PanelTab({required this.value, required this.label, required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = active == value;
    return GestureDetector(
      onTap: () => ref.read(drawerPanelProvider.notifier).state = value,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.fg0 : AppColors.fg2,
            ),
          ),
        ),
      ),
    );
  }
}
