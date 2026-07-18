import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'node_drawer.dart';
import 'payload_editor.dart';

/// Builder-mode "payload" tab for `source.inject` nodes.
///
/// Binds the editor to `node.payloadCode` and writes back through
/// `workflowProvider.copyWith` — the autosave listener in main.dart handles
/// persistence.
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
            hint: 'elixir literal — backend parses',
            child: PayloadEditor(
              initialCode: node.payloadCode ?? '',
              onChanged: (code) {
                final wf = ref.read(workflowProvider);
                ref.read(workflowProvider.notifier).state = wf.copyWith(
                  nodes: wf.nodes
                      .map((n) =>
                          n.id == node.id ? n.copyWith(payloadCode: code) : n)
                      .toList(),
                );
              },
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
                      final wf = ref.read(workflowProvider);
                      ref.read(workflowProvider.notifier).state = wf.copyWith(
                        nodes: wf.nodes
                            .map((n) => n.id == node.id
                                ? n.copyWith(once: v)
                                : n)
                            .toList(),
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
