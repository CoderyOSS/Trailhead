import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import 'stage_drawer.dart';

class EditorResultTab extends ConsumerStatefulWidget {
  final WorkflowNode stage;

  EditorResultTab({super.key, required this.stage});

  @override
  ConsumerState<EditorResultTab> createState() => _EditorResultTabState();
}

class _EditorResultTabState extends ConsumerState<EditorResultTab> {
  late String _format;

  @override
  void initState() {
    super.initState();
    _format = widget.stage.resultFormat ?? 'json';
  }

  @override
  void didUpdateWidget(covariant EditorResultTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.id != widget.stage.id) {
      _format = widget.stage.resultFormat ?? 'json';
    }
  }

  void _updateFormat(String format) {
    setState(() => _format = format);
    final wf = ref.read(workflowProvider);
    ref.read(workflowProvider.notifier).state = wf.copyWith(
      nodes: wf.nodes.map((n) {
        if (n.id == widget.stage.id) {
          return n.copyWith(resultFormat: format);
        }
        return n;
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stage.kind != 'worker') {
      return EmptyBlock(
        label: "routing operators don't define a result schema",
      );
    }

    final downstream = _format == 'json'
        ? 'Fields autocomplete in any downstream prompt as {{${widget.stage.id}.<field>}}.'
        : 'Reference the full text in downstream prompts as {{${widget.stage.id}.text}}.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Field(
            label: 'result format',
            hint: 'how this stage\'s output is interpreted',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                border: Border.all(color: AppColors.border1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  _FormatOption(
                    label: 'JSON schema',
                    sub: 'structured \u00b7 strict',
                    active: _format == 'json',
                    onTap: () => _updateFormat('json'),
                  ),
                  _FormatOption(
                    label: 'Plain text',
                    sub: 'freeform blob',
                    active: _format == 'text',
                    onTap: () => _updateFormat('text'),
                  ),
                ],
              ),
            ),
          ),
          if (_format == 'json' && widget.stage.schema != null)
            Field(
              label: 'result schema \u00b7 JSON',
              hint: 'strict \u2014 workers fail-soft on mismatch',
              child: SchemaEditor(schema: widget.stage.schema!),
            ),
          Field(
            label: 'downstream usage',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border.all(color: AppColors.border1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                downstream,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: AppColors.fg2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatOption extends StatefulWidget {
  final String label;
  final String sub;
  final bool active;
  final VoidCallback onTap;

  _FormatOption({
    required this.label,
    required this.sub,
    required this.active,
    required this.onTap,
  });

  @override
  State<_FormatOption> createState() => _FormatOptionState();
}

class _FormatOptionState extends State<_FormatOption> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active ? AppColors.bg4 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.active ? AppColors.fg0 : AppColors.fg2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                widget.sub,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  color: AppColors.fg3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
