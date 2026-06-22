import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'stage_drawer.dart';

class EditorPromptTab extends ConsumerStatefulWidget {
  final WorkflowNode stage;

  EditorPromptTab({super.key, required this.stage});

  @override
  ConsumerState<EditorPromptTab> createState() => _EditorPromptTabState();
}

class _EditorPromptTabState extends ConsumerState<EditorPromptTab> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.stage.prompt ?? '');
  }

  @override
  void didUpdateWidget(covariant EditorPromptTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.id != widget.stage.id) {
      _ctrl.text = widget.stage.prompt ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _update(String value) {
    final wf = ref.read(workflowProvider);
    ref.read(workflowProvider.notifier).state = wf.copyWith(
      nodes: wf.nodes.map((n) {
        if (n.id == widget.stage.id) {
          return n.copyWith(prompt: value);
        }
        return n;
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stage.prompt == null || widget.stage.prompt!.isEmpty) {
      return EmptyBlock(label: 'no prompt for this routing operator');
    }

    final refs = [...RegExp(r'\{\{([^}]+)\}\}')
        .allMatches(widget.stage.prompt!)
        .map((m) => m.group(1)!.trim())
        .toSet()];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Field(
            label: 'prompt template',
            hint: '${refs.length} dynamic refs',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border.all(color: AppColors.border2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: _update,
                maxLines: null,
                minLines: 8,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.fg0,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg0,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),
          ),
          Field(
            label: 'syntax',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border.all(color: AppColors.border1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Reference values from previous stages with ',
                    ),
                    TextSpan(
                      text: '{{stage_id.field}}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.accent,
                      ),
                    ),
                    const TextSpan(
                      text: '.\nUse ',
                    ),
                    TextSpan(
                      text: '{{inputs.x}}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.accent,
                      ),
                    ),
                    const TextSpan(
                      text: ' for workflow inputs, ',
                    ),
                    TextSpan(
                      text: '{{skills.<name>}}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.accent,
                      ),
                    ),
                    const TextSpan(
                      text: ' to inject a skill file,\nand ',
                    ),
                    TextSpan(
                      text: '{{item}}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.accent,
                      ),
                    ),
                    const TextSpan(
                      text: ' inside a map body.',
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: AppColors.fg2,
                  ),
                ),
              ),
            ),
          ),
          if (refs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: refs.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '{{$r}}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
