import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../providers/carta_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import 'node_drawer.dart';
import 'payload_editor.dart';

/// Runtime 'job' tab for a node in an active/historical job. Shows node
/// runtime info (genserver) and the inject trigger (source.inject). The old
/// mock EXECUTIONS feed was removed — per-node execution history is
/// unimplemented server-side.
class JobLogView extends StatelessWidget {
  final WorkflowNode node;

  const JobLogView({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final hasRuntimeSection =
        node.kind == 'genserver' || node.kind == 'source.inject';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (node.kind == 'genserver') _JobStageHeaderInfo(stage: node),
        if (node.kind == 'source.inject') _ActiveInjectSection(node: node),
        if (!hasRuntimeSection)
          Expanded(
            child: EmptyBlock(label: 'no runtime info for this node kind'),
          ),
      ],
    );
  }
}

class _JobStageHeaderInfo extends StatelessWidget {
  final WorkflowNode stage;

  _JobStageHeaderInfo({required this.stage});

  @override
  Widget build(BuildContext context) {
    final configs = stage.configs;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Field(
              label: 'connection',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg0,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CartaIcon(
                      icon: CartaIconData.zap,
                      size: 11,
                      color: AppColors.fg3,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stage.connection ?? 'default',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.fg0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Field(
              label: 'configs',
              hint: '${configs.length}',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg0,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: configs.isEmpty
                    ? Text(
                        '—',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.fg3,
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: configs.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg3,
                              border: Border.all(color: AppColors.border1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                color: AppColors.fg2,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Active-mode inject panel for `source.inject` nodes.
///
/// Holds an in-memory payload buffer (initialized from the node's YAML
/// `payload_code`, never written back). Trigger button POSTs the current
/// buffer text to `/api/v1/workflows/:name/inject` — backend parses the
/// Elixir literal and sends the envelope to the node.
class _ActiveInjectSection extends ConsumerStatefulWidget {
  final WorkflowNode node;

  const _ActiveInjectSection({required this.node});

  @override
  ConsumerState<_ActiveInjectSection> createState() =>
      _ActiveInjectSectionState();
}

class _ActiveInjectSectionState extends ConsumerState<_ActiveInjectSection> {
  String? _lastResult;
  bool _lastOk = true;
  bool _sending = false;

  String get _bufferKey => injectBufferKey(ref, widget.node.id);

  String _bufferText() {
    final buffers = ref.read(injectBufferProvider);
    return buffers[_bufferKey] ?? widget.node.payloadCode ?? '';
  }

  void _setBuffer(String text) {
    final buffers = Map<String, String>.from(ref.read(injectBufferProvider));
    buffers[_bufferKey] = text;
    ref.read(injectBufferProvider.notifier).state = buffers;
  }

  Future<void> _trigger() async {
    final wf = ref.read(canvasWorkflowProvider);
    final code = _bufferText();

    setState(() {
      _sending = true;
      _lastResult = null;
    });

    try {
      await triggerNodeInject(ref, wf.name, widget.node.id, code,
          isExpr: widget.node.payloadIsExpr);

      if (!mounted) return;
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      final ss = now.second.toString().padLeft(2, '0');
      setState(() {
        _sending = false;
        _lastOk = true;
        _lastResult = 'injected at $hh:$mm:$ss';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastOk = false;
        _lastResult = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wf = ref.watch(canvasWorkflowProvider);
    final statuses = ref.watch(flowStatusProvider);
    final deployed = statuses[wf.name]?.deployed ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INJECT PAYLOAD',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 0.06 * 10,
              color: AppColors.fg3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          PayloadEditor(
            key: ValueKey(_bufferKey),
            initialCode: _bufferText(),
            isExpr: widget.node.payloadIsExpr,
            onChanged: _setBuffer,
            triggerSlot: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: deployed && !_sending ? _trigger : null,
                  child: MouseRegion(
                    cursor: deployed && !_sending
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: deployed ? AppColors.accent : AppColors.bg3,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _sending ? 'injecting…' : 'trigger',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: deployed
                              ? AppColors.accentInk
                              : AppColors.fg3,
                          letterSpacing: 0.06 * 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!deployed) ...[
                  const SizedBox(height: 6),
                  Text(
                    'flow not deployed — trigger disabled',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: AppColors.fg3,
                    ),
                  ),
                ],
                if (_lastResult != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _lastResult!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: _lastOk ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
