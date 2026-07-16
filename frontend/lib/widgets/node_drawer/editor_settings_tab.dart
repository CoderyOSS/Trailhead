import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stage_data.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import 'node_drawer.dart';

class EditorSettingsTab extends ConsumerStatefulWidget {
  final WorkflowNode node;

  EditorSettingsTab({super.key, required this.node});

  @override
  ConsumerState<EditorSettingsTab> createState() => _EditorSettingsTabState();
}

class _EditorSettingsTabState extends ConsumerState<EditorSettingsTab> {
  late TextEditingController _timeoutCtrl;
  late TextEditingController _retriesCtrl;
  late TextEditingController _parallelismCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _overCtrl;
  late TextEditingController _countCtrl;
  late TextEditingController _concurrencyCtrl;
  late TextEditingController _intervalMsCtrl;
  late TextEditingController _httpIngressServerCtrl;
  late TextEditingController _httpIngressPathCtrl;
  late TextEditingController _httpEgressStatusCtrl;
  late TextEditingController _httpEgressContentTypeCtrl;
  late TextEditingController _httpEgressBodyCtrl;
  late TextEditingController _httpRequestServerCtrl;
  late TextEditingController _httpRequestPathCtrl;

  @override
  void initState() {
    super.initState();
    _timeoutCtrl = TextEditingController(text: widget.node.timeout ?? '120s');
    _retriesCtrl = TextEditingController(text: widget.node.retries?.toString() ?? '2');
    _parallelismCtrl = TextEditingController(text: widget.node.parallelism?.toString() ?? '4');
    _labelCtrl = TextEditingController(text: widget.node.label);
    _overCtrl = TextEditingController(text: widget.node.over ?? 'files');
    _countCtrl = TextEditingController(text: widget.node.count?.toString() ?? '8');
    _concurrencyCtrl = TextEditingController(text: widget.node.concurrency?.toString() ?? '3');
    _intervalMsCtrl = TextEditingController(text: widget.node.intervalMs?.toString() ?? '1000');
    _httpIngressServerCtrl = TextEditingController(text: widget.node.httpIngressServer ?? '');
    _httpIngressPathCtrl = TextEditingController(text: widget.node.httpIngressPath ?? '/');
    _httpEgressStatusCtrl = TextEditingController(text: widget.node.httpEgressStatus?.toString() ?? '200');
    _httpEgressContentTypeCtrl = TextEditingController(text: widget.node.httpEgressContentType ?? 'application/json');
    _httpEgressBodyCtrl = TextEditingController(text: widget.node.httpEgressBody ?? '');
    _httpRequestServerCtrl = TextEditingController(text: widget.node.httpRequestServer ?? '');
    _httpRequestPathCtrl = TextEditingController(text: widget.node.httpRequestPath ?? '/');
  }

  @override
  void dispose() {
    _timeoutCtrl.dispose();
    _retriesCtrl.dispose();
    _parallelismCtrl.dispose();
    _labelCtrl.dispose();
    _overCtrl.dispose();
    _countCtrl.dispose();
    _concurrencyCtrl.dispose();
    _intervalMsCtrl.dispose();
    _httpIngressServerCtrl.dispose();
    _httpIngressPathCtrl.dispose();
    _httpEgressStatusCtrl.dispose();
    _httpEgressContentTypeCtrl.dispose();
    _httpEgressBodyCtrl.dispose();
    _httpRequestServerCtrl.dispose();
    _httpRequestPathCtrl.dispose();
    super.dispose();
  }

  void _updateNode(WorkflowNode updated) {
    final wf = ref.read(workflowProvider);
    ref.read(workflowProvider.notifier).state = wf.copyWith(
      nodes: wf.nodes.map((n) => n.id == updated.id ? updated : n).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isWorker = node.kind == 'genserver';
    final isBranch = node.kind == 'function';
    final isDelay = node.kind == 'delay';
    final isHttpIngress = node.kind == 'http.ingress';
    final isHttpEgress = node.kind == 'http.egress';
    final isHttpRequest = node.kind == 'http.request';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Field(
            label: 'node id',
            child: PreBlock(value: node.id),
          ),

          if (isWorker) ...[
            Field(
              label: 'model config',
              hint: 'provider \u00b7 model',
              child: _SelectField(
                value: node.connection ?? 'anthropic-claude-sonnet-4',
                options: const [
                  ('anthropic-claude-sonnet-4', 'Anthropic \u00b7 Claude Sonnet 4'),
                  ('anthropic-claude-opus-4', 'Anthropic \u00b7 Claude Opus 4'),
                  ('openai-gpt-4o', 'OpenAI \u00b7 GPT-4o'),
                  ('openai-gpt-4o-mini', 'OpenAI \u00b7 GPT-4o Mini'),
                  ('deepseek-chat', 'DeepSeek \u00b7 Chat'),
                ],
                onChanged: (v) => _updateNode(node.copyWith(connection: v)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Field(
                    label: 'timeout',
                    child: _TextInput(
                      controller: _timeoutCtrl,
                      onChanged: (v) => _updateNode(node.copyWith(timeout: v)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Field(
                    label: 'retries',
                    child: _TextInput(
                      controller: _retriesCtrl,
                      onChanged: (v) => _updateNode(node.copyWith(retries: int.tryParse(v))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Field(
                    label: 'parallelism',
                    child: _TextInput(
                      controller: _parallelismCtrl,
                      onChanged: (v) => _updateNode(node.copyWith(parallelism: int.tryParse(v))),
                    ),
                  ),
                ),
              ],
            ),
            _ConfigList(
              configs: node.configs,
              onUpdate: (c) => _updateNode(node.copyWith(configs: c)),
            ),
          ] else if (isBranch) ...[
            _BranchOutputsEditor(
              outputs: node.outputs,
              matchAll: node.matchAll,
              onUpdate: (outputs, matchAll, removedIndex) {
                var wf = ref.read(workflowProvider);
                if (removedIndex != null) {
                  wf = wf.copyWith(
                    edges: wf.edges
                        .where((e) => !(e.sourceId == node.id && e.sourcePort == removedIndex))
                        .map((e) {
                      if (e.sourceId == node.id && e.sourcePort != null && e.sourcePort! > removedIndex) {
                        return e.copyWith(sourcePort: e.sourcePort! - 1);
                      }
                      return e;
                    })
                        .toList(),
                  );
                }
                ref.read(workflowProvider.notifier).state = wf.copyWith(
                  nodes: wf.nodes.map((n) => n.id == node.id ? n.copyWith(outputs: outputs, matchAll: matchAll) : n).toList(),
                );
              },
            ),
          ] else if (isDelay) ...[
            Field(
              label: 'interval (ms)',
              hint: 'time to wait before emitting',
              child: _TextInput(
                controller: _intervalMsCtrl,
                onChanged: (v) => _updateNode(node.copyWith(intervalMs: int.tryParse(v))),
              ),
            ),
          ] else if (isHttpIngress) ...[
            Field(
              label: 'server',
              hint: 'server instance id, default is "default"',
              child: _TextInput(
                controller: _httpIngressServerCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpIngressServer: v.isEmpty ? null : v)),
              ),
            ),
            Field(
              label: 'method',
              hint: 'HTTP request method',
              child: _SelectField(
                value: node.httpIngressMethod ?? 'GET',
                options: const [
                  ('GET', 'GET'),
                  ('POST', 'POST'),
                  ('PUT', 'PUT'),
                  ('DELETE', 'DELETE'),
                  ('PATCH', 'PATCH'),
                ],
                onChanged: (v) => _updateNode(node.copyWith(httpIngressMethod: v)),
              ),
            ),
            Field(
              label: 'path',
              hint: 'url path, e.g. /webhook',
              child: _TextInput(
                controller: _httpIngressPathCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpIngressPath: v.isEmpty ? null : v)),
              ),
            ),
          ] else if (isHttpEgress) ...[
            Field(
              label: 'status',
              hint: 'HTTP status code, default 200',
              child: _TextInput(
                controller: _httpEgressStatusCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpEgressStatus: int.tryParse(v))),
              ),
            ),
            Field(
              label: 'content type',
              hint: 'response Content-Type header',
              child: _TextInput(
                controller: _httpEgressContentTypeCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpEgressContentType: v.isEmpty ? null : v)),
              ),
            ),
            Field(
              label: 'body',
              hint: 'static response body fallback',
              child: _TextInput(
                controller: _httpEgressBodyCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpEgressBody: v.isEmpty ? null : v)),
              ),
            ),
          ] else if (isHttpRequest) ...[
            Field(
              label: 'server',
              hint: 'base url of the target server',
              child: _TextInput(
                controller: _httpRequestServerCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpRequestServer: v.isEmpty ? null : v)),
              ),
            ),
            Field(
              label: 'method',
              hint: 'HTTP request method',
              child: _SelectField(
                value: node.httpRequestMethod ?? 'GET',
                options: const [
                  ('GET', 'GET'),
                  ('POST', 'POST'),
                  ('PUT', 'PUT'),
                  ('DELETE', 'DELETE'),
                  ('PATCH', 'PATCH'),
                ],
                onChanged: (v) => _updateNode(node.copyWith(httpRequestMethod: v)),
              ),
            ),
            Field(
              label: 'path',
              hint: 'url path, e.g. /api/v1/data',
              child: _TextInput(
                controller: _httpRequestPathCtrl,
                onChanged: (v) => _updateNode(node.copyWith(httpRequestPath: v.isEmpty ? null : v)),
              ),
            ),
          ] else ...[
            Field(
              label: 'label',
              child: _TextInput(
                controller: _labelCtrl,
                onChanged: (v) => _updateNode(node.copyWith(label: v)),
              ),
            ),
            Field(
              label: 'maps over',
              hint: 'the list this maps each item across',
              child: _TextInput(
                controller: _overCtrl,
                onChanged: (v) => _updateNode(node.copyWith(over: v)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Field(
                    label: 'items',
                    child: _TextInput(
                      controller: _countCtrl,
                      onChanged: (v) => _updateNode(node.copyWith(count: int.tryParse(v))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Field(
                    label: 'max parallel',
                    child: _TextInput(
                      controller: _concurrencyCtrl,
                      onChanged: (v) => _updateNode(node.copyWith(concurrency: int.tryParse(v))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Field(
                    label: 'collect',
                    child: _SelectField(
                      value: node.collect ?? 'array',
                      options: const [
                        ('array', 'array'),
                        ('object', 'object'),
                        ('concat', 'concat'),
                      ],
                      onChanged: (v) => _updateNode(node.copyWith(collect: v)),
                    ),
                  ),
                ),
              ],
            ),
            if (node.body != null) ...[
              const SizedBox(height: 8),
              _SubworkflowSelector(
                body: node.body!,
                onUpdate: (body) => _updateNode(node.copyWith(body: body)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  _TextInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: AppColors.fg0,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bg0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

class _SelectField extends StatefulWidget {
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  _SelectField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_SelectField> createState() => _SelectFieldState();
}

class _SelectFieldState extends State<_SelectField> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg0,
            border: Border.all(color: _hover ? AppColors.accent : AppColors.border2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.value,
              isDense: true,
              isExpanded: true,
              icon: TrailheadIcon(
                icon: TrailheadIconData.chevRight,
                size: 10,
                color: AppColors.fg2,
              ),
              dropdownColor: AppColors.bg0,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.fg0,
              ),
              items: widget.options.map((o) {
                return DropdownMenuItem(
                  value: o.$1,
                  child: Text(o.$2),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) widget.onChanged(v);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigList extends StatefulWidget {
  final List<String> configs;
  final ValueChanged<List<String>> onUpdate;

  _ConfigList({required this.configs, required this.onUpdate});

  @override
  State<_ConfigList> createState() => _ConfigListState();
}

class _ConfigListState extends State<_ConfigList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Field(
          label: 'attached configs',
          hint: '${widget.configs.length}',
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.configs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'no configs attached',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg3,
                      ),
                    ),
                  ),
                ...widget.configs.asMap().entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      border: Border.all(color: AppColors.border1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        TrailheadIcon(
                          icon: TrailheadIconData.file,
                          size: 11,
                          color: AppColors.fg3,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: AppColors.fg0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final next = List<String>.from(widget.configs)..removeAt(e.key);
                            widget.onUpdate(next);
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 16,
                              height: 16,
                              alignment: Alignment.center,
                              child: TrailheadIcon(
                                icon: TrailheadIconData.x,
                                size: 9,
                                color: AppColors.fg2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    // Add a mock config for demo
                    final next = List<String>.from(widget.configs)..add('new-config.yaml');
                    widget.onUpdate(next);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TrailheadIcon(
                            icon: TrailheadIconData.copy,
                            size: 10,
                            color: AppColors.fg2,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'attach config',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.fg2,
                            ),
                          ),
                        ],
                      ),
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

class _BranchOutputsEditor extends StatefulWidget {
  final List<BranchOutput> outputs;
  final bool matchAll;
  final void Function(List<BranchOutput>, bool, int? removedIndex) onUpdate;

  _BranchOutputsEditor({
    required this.outputs,
    required this.matchAll,
    required this.onUpdate,
  });

  @override
  State<_BranchOutputsEditor> createState() => _BranchOutputsEditorState();
}

class _BranchOutputsEditorState extends State<_BranchOutputsEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BRANCH OUTPUTS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 0.06 * 10,
                color: AppColors.fg3,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  'match all',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.fg2,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onUpdate(widget.outputs, !widget.matchAll, null),
                  child: Container(
                    width: 32,
                    height: 18,
                    decoration: BoxDecoration(
                      color: widget.matchAll
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : AppColors.bg3,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: widget.matchAll ? AppColors.accent : AppColors.border2,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 120),
                      alignment: widget.matchAll
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: widget.matchAll ? AppColors.accent : AppColors.fg2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...widget.outputs.asMap().entries.map((e) {
          final out = e.value;
          return _BranchOutputRow(
            output: out,
            onUpdate: (updated) {
              final next = List<BranchOutput>.from(widget.outputs);
              next[e.key] = updated;
              widget.onUpdate(next, widget.matchAll, null);
            },
            onDelete: () {
              final next = List<BranchOutput>.from(widget.outputs)..removeAt(e.key);
              widget.onUpdate(next, widget.matchAll, e.key);
            },
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final next = List<BranchOutput>.from(widget.outputs)
              ..add(BranchOutput(
                id: '${widget.outputs.length}',
                label: 'new',
              ));
            widget.onUpdate(next, widget.matchAll, null);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TrailheadIcon(
                    icon: TrailheadIconData.copy,
                    size: 10,
                    color: AppColors.fg2,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'add output',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.fg2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BranchOutputRow extends StatefulWidget {
  final BranchOutput output;
  final ValueChanged<BranchOutput> onUpdate;
  final VoidCallback onDelete;

  _BranchOutputRow({
    required this.output,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_BranchOutputRow> createState() => _BranchOutputRowState();
}

class _BranchOutputRowState extends State<_BranchOutputRow> {
  late TextEditingController _labelCtrl;
  late TextEditingController _exprCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.output.label);
    _exprCtrl = TextEditingController(text: widget.output.expression ?? '');
  }

  @override
  void didUpdateWidget(covariant _BranchOutputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.output.label != widget.output.label &&
        _labelCtrl.text != widget.output.label) {
      _labelCtrl.text = widget.output.label;
    }
    if (oldWidget.output.expression != widget.output.expression &&
        _exprCtrl.text != (widget.output.expression ?? '')) {
      _exprCtrl.text = widget.output.expression ?? '';
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _exprCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _labelCtrl,
                  onChanged: (v) => widget.onUpdate(
                    widget.output.copyWith(label: v),
                  ),
                  inputFormatters: [LengthLimitingTextInputFormatter(15)],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onDelete,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    child: TrailheadIcon(
                      icon: TrailheadIconData.x,
                      size: 10,
                      color: AppColors.fg2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'if',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: AppColors.fg3,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _exprCtrl,
                  onChanged: (v) => widget.onUpdate(
                    widget.output.copyWith(expression: v.isEmpty ? null : v),
                  ),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.fg0,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    filled: true,
                    fillColor: AppColors.bg2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.border1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.border1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    hintText: 'expression',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.fg3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubworkflowSelector extends StatefulWidget {
  final StageBody body;
  final ValueChanged<StageBody> onUpdate;

  _SubworkflowSelector({
    required this.body,
    required this.onUpdate,
  });

  @override
  State<_SubworkflowSelector> createState() => _SubworkflowSelectorState();
}

class _SubworkflowSelectorState extends State<_SubworkflowSelector> {
  bool _expanded = false;

  final _workflows = const [
    ('per-file-comment', 'per-file-comment'),
    ('lint-check', 'lint-check'),
    ('security-scan', 'security-scan'),
    ('doc-review', 'doc-review'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.crustGradient,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      blurRadius: 0,
                      spreadRadius: 0,
                      offset: const Offset(-3, 0),
                    ),
                  ],
                ),
                child: Text(
                  widget.body.label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fg0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.body.model != null)
                Text(
                  widget.body.model!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppColors.fg3,
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TrailheadIcon(
                      icon: TrailheadIconData.chevRight,
                      size: 10,
                      color: AppColors.fg2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.body.skills.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              children: widget.body.skills.map((sk) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg3,
                    border: Border.all(color: AppColors.border1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    sk,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.fg2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          PreBlock(
            value: widget.body.prompt,
            borderColor: AppColors.border1,
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg2,
                border: Border.all(color: AppColors.border1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _workflows.map((w) {
                  final selected = w.$1 == widget.body.label;
                  return GestureDetector(
                    onTap: () {
                      widget.onUpdate(widget.body.copyWith(label: w.$1));
                      setState(() => _expanded = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.bg4 : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        w.$2,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: selected ? AppColors.fg0 : AppColors.fg2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
