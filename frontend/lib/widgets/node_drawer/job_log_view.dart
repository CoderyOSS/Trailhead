import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stage_data.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../providers/mock_data.dart';
import '../../providers/carta_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import 'node_drawer.dart';
import 'payload_editor.dart';

class JobLogView extends StatefulWidget {
  final WorkflowNode node;

  JobLogView({super.key, required this.node});

  @override
  State<JobLogView> createState() => _JobLogViewState();
}

class _JobLogViewState extends State<JobLogView> {
  String? _openId;

  @override
  void initState() {
    super.initState();
    final executions = mockStageExecutions[widget.node.id] ?? [];
    if (executions.isNotEmpty) {
      final running = executions.firstWhere(
        (e) => e.status == 'running',
        orElse: () => executions.first,
      );
      _openId = running.id;
    }
  }

  @override
  void didUpdateWidget(covariant JobLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      final executions = mockStageExecutions[widget.node.id] ?? [];
      _openId = executions.isNotEmpty ? executions.first.id : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final executions = mockStageExecutions[widget.node.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.node.kind == 'genserver')
          _JobStageHeaderInfo(stage: widget.node),
        if (widget.node.kind == 'source.inject')
          _ActiveInjectSection(node: widget.node),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EXECUTIONS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 0.06 * 10,
                        color: AppColors.fg3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${executions.length} \u00b7 this job',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.fg3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...executions.map((ex) {
                  return ExecutionRow(
                    exec: ex,
                    expanded: _openId == ex.id,
                    onToggle: () {
                      setState(() {
                        _openId = _openId == ex.id ? null : ex.id;
                      });
                    },
                  );
                }),
                if (executions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Text(
                      'no executions yet for this node',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.fg3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                        '\u2014',
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

class ExecutionRow extends StatefulWidget {
  final StageExecution exec;
  final bool expanded;
  final VoidCallback onToggle;

  ExecutionRow({
    super.key,
    required this.exec,
    required this.expanded,
    required this.onToggle,
  });

  @override
  State<ExecutionRow> createState() => _ExecutionRowState();
}

class _ExecutionRowState extends State<ExecutionRow> {
  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta(widget.exec.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.expanded ? AppColors.accent : AppColors.border1,
        ),
        color: widget.expanded ? AppColors.bg0 : AppColors.bg2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: widget.expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: CartaIcon(
                      icon: CartaIconData.chevRight,
                      size: 11,
                      color: AppColors.fg3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.exec.label,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.fg0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ExStatusPip(status: widget.exec.status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (widget.exec.startedAt != null)
                              Text(
                                widget.exec.startedAt!,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.fg3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            if (widget.exec.startedAt != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '\u00b7',
                                  style: TextStyle(color: AppColors.border2),
                                ),
                              ),
                            Text(
                              _fmtDur(widget.exec.durMs),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: AppColors.fg3,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '\u00b7',
                                style: TextStyle(color: AppColors.border2),
                              ),
                            ),
                            Text(
                              '${_fmtTokens(widget.exec.tokens)} tok',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: AppColors.fg3,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (widget.exec.tools != null && widget.exec.tools!.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '\u00b7',
                                  style: TextStyle(color: AppColors.border2),
                                ),
                              ),
                              Text(
                                '${widget.exec.tools!.length} tool${widget.exec.tools!.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.fg3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.exec.status == 'running' && widget.exec.progress != null)
                    Text(
                      '${(widget.exec.progress! * 100).round()}%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.expanded)
            ExecutionDetail(exec: widget.exec),
        ],
      ),
    );
  }
}

class ExecutionDetail extends StatelessWidget {
  final StageExecution exec;

  ExecutionDetail({super.key, required this.exec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exec.status == 'running' && exec.streaming != null) ...[
            LogSection(
              label: 'streaming',
              accent: true,
              child: PreBlock(
                value: '\u25b8 ${exec.streaming}',
                borderColor: AppColors.accent,
              ),
            ),
            if (exec.progress != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: exec.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(exec.progress! * 100).round()}%',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: AppColors.fg0,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (exec.renderedPrompt != null)
            LogSection(
              label: 'rendered prompt',
              hint: 'full string sent to the model',
              child: PreBlock(value: exec.renderedPrompt!),
            ),
          if (exec.tools != null && exec.tools!.isNotEmpty)
            LogSection(
              label: 'tool calls',
              hint: '${exec.tools!.length} call${exec.tools!.length == 1 ? '' : 's'}',
              child: Column(
                children: exec.tools!.map((t) => ToolCallRow(call: t)).toList(),
              ),
            ),
          if (exec.status == 'passed' && exec.result != null)
            LogSection(
              label: 'result',
              child: SchemaEditor(schema: exec.result as Map<String, dynamic>),
            ),
          if (exec.status == 'failed' && exec.error != null)
            LogSection(
              label: 'error',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exec.error!.code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                        letterSpacing: 0.04 * 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exec.error!.message,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        height: 1.5,
                        color: AppColors.fg0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (exec.status == 'skipped' && exec.skipReason != null)
            LogSection(
              label: 'skipped',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  border: Border.all(color: AppColors.border1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exec.skipReason!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: AppColors.fg2,
                  ),
                ),
              ),
            ),
          if (exec.status == 'queued' && exec.waitsFor != null)
            LogSection(
              label: 'waiting for',
              child: Wrap(
                spacing: 4,
                children: exec.waitsFor!.map((w) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      border: Border.all(color: AppColors.border1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      w,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg2,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class LogSection extends StatelessWidget {
  final String label;
  final String? hint;
  final bool accent;
  final Widget child;

  LogSection({
    super.key,
    required this.label,
    this.hint,
    this.accent = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  letterSpacing: 0.06 * 9.5,
                  color: accent ? AppColors.accent : AppColors.fg3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hint != null)
                Text(
                  hint!,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.fg3,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

class ToolCallRow extends StatelessWidget {
  final ToolCall call;

  ToolCallRow({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final running = call.running || call.ok == null;
    final tone = call.ok == true
        ? AppColors.success
        : call.ok == false
            ? AppColors.danger
            : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tone,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: call.name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.fg0,
                    ),
                  ),
                  if (call.args != null)
                    TextSpan(
                      text: ' \u00b7 ${call.args}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg3,
                      ),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            running ? '\u2026' : '${call.ms}ms',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

({Color color, Color bg, String label}) _statusMeta(String status) {
  return switch (status) {
    'passed' => (color: AppColors.success, bg: AppColors.success.withValues(alpha: 0.15), label: 'passed'),
    'failed' => (color: AppColors.danger, bg: AppColors.danger.withValues(alpha: 0.15), label: 'failed'),
    'running' => (color: AppColors.accent, bg: AppColors.accent.withValues(alpha: 0.15), label: 'running'),
    'retrying' => (color: AppColors.warning, bg: AppColors.warning.withValues(alpha: 0.15), label: 'retrying'),
    'queued' => (color: AppColors.fg3, bg: AppColors.bg3, label: 'queued'),
    'skipped' => (color: AppColors.fg3, bg: AppColors.bg3, label: 'skipped'),
    _ => (color: AppColors.fg3, bg: AppColors.bg3, label: status),
  };
}

class _ExStatusPip extends StatelessWidget {
  final String status;

  _ExStatusPip({required this.status});

  @override
  Widget build(BuildContext context) {
    final m = _statusMeta(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: m.bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: m.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            m.label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: m.color,
              letterSpacing: 0.04 * 10,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDur(int ms) {
  if (ms == 0) return '\u2014';
  if (ms < 1000) return '${ms}ms';
  if (ms < 60000) return '${(ms / 1000).toStringAsFixed(ms < 10000 ? 2 : 1)}s';
  final m = ms ~/ 60000;
  final s = (ms % 60000) ~/ 1000;
  return '${m}m${s.toString().padLeft(2, '0')}s';
}

String _fmtTokens(int n) {
  if (n == 0) return '0';
  if (n < 1000) return '$n';
  return '${(n / 1000).toStringAsFixed(n < 10000 ? 2 : 1)}k';
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
