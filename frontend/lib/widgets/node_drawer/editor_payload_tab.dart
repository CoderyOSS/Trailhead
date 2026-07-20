import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'node_drawer.dart';
import 'payload_editor.dart';

/// "Payload" tab for `source.inject` nodes (builder and job views).
///
/// Binds the editor to `node.payloadCode` and writes back through
/// [updateCanvasNode] — builder mode hits `workflowProvider` (autosave
/// persists), job view hits the job's snapshot only.
class EditorPayloadTab extends ConsumerWidget {
  final WorkflowNode node;

  const EditorPayloadTab({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Field(
            label: 'payload code',
            hint: node.payloadIsExpr
                ? 'elixir expression — evaluated once at deploy'
                : 'elixir literal — backend parses',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeToggle(
                  isExpr: node.payloadIsExpr,
                  onChanged: (isExpr) {
                    updateCanvasNode(
                      ref,
                      node.id,
                      (n) => n.copyWith(payloadIsExpr: isExpr),
                    );
                  },
                ),
                const SizedBox(height: 8),
                PayloadEditor(
                  // Keyed by node id — initialCode binds in initState only,
                  // so an unkeyed editor keeps the previous node's payload.
                  key: ValueKey('payload-${node.id}'),
                  initialCode: node.payloadCode ?? '',
                  isExpr: node.payloadIsExpr,
                  onChanged: (code) {
                    updateCanvasNode(
                      ref,
                      node.id,
                      (n) => n.copyWith(payloadCode: code),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Field(
            label: 'emit options',
            hint: 'optional auto-fire',
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border.all(color: AppColors.border2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _ToggleRow(
                    label: 'once',
                    description: 'emit once 20ms after deploy',
                    value: node.once ?? false,
                    onChanged: (v) {
                      updateCanvasNode(
                        ref,
                        node.id,
                        (n) => n.copyWith(once: v),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isExpr;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isExpr, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(label: 'literal', selected: !isExpr, onTap: () => onChanged(false)),
          _option(label: 'expression', selected: isExpr, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: selected ? AppColors.accentInk : AppColors.fg2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? AppColors.accent : AppColors.bg2,
                border: Border.all(
                  color: value ? AppColors.accent : AppColors.border2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.center,
              child: value
                  ? Icon(Icons.check, size: 12, color: AppColors.accentInk)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.fg0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: AppColors.fg3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
