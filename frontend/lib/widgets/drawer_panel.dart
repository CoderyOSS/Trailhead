import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_node.dart';
import '../providers/mode_provider.dart';
import '../theme/tokens.dart';
import 'mode_rail.dart';
import 'node_drawer/node_drawer.dart';
import 'log_drawer/log_drawer.dart';

/// Top-level drawer panel.
///
/// In builder mode only the NodeDrawer renders.
/// In active mode the panel is forced open as a 2-column layout: logs on the
/// left, node details on the right. With no node selected the node column is
/// hidden and only the logs render.
class DrawerPanel extends ConsumerWidget {
  final WorkflowNode? node;
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
        node: node!,
        view: view,
        onClose: onClose,
        isPortrait: isPortrait,
      );
    }

    final mode = ref.watch(modeProvider);
    final job = ref.watch(selectedJobProvider);

    if (mode == AppMode.active) {
      final showNode = node != null;
      return Container(
        width: isPortrait ? double.infinity : (showNode ? 900 : 450),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isPortrait
                ? Expanded(child: _logsColumn(job != null))
                : SizedBox(width: 450, child: _logsColumn(job != null)),
            if (showNode) ...[
              Container(width: 1, color: AppColors.border1),
              isPortrait
                  ? Expanded(
                      child: NodeDrawer(
                        node: node!,
                        view: view,
                        onClose: onClose,
                        isPortrait: true,
                      ),
                    )
                  : SizedBox(
                      width: 450,
                      child: NodeDrawer(
                        node: node!,
                        view: view,
                        onClose: onClose,
                        isPortrait: true,
                      ),
                    ),
            ],
          ],
        ),
      );
    }

    // History mode: node drawer is suppressed by the shell; nothing renders.
    return const SizedBox.shrink();
  }

  Widget _logsColumn(bool hasJob) {
    if (!hasJob) {
      return Center(
        child: Text(
          'no job selected',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.fg3,
          ),
        ),
      );
    }
    return const LogDrawer();
  }
}
