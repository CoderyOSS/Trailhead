import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workflow_node.dart';
import '../../providers/mode_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import 'editor_settings_tab.dart';
import 'editor_prompt_tab.dart';
import 'editor_result_tab.dart';
import 'job_log_view.dart';

enum NodeDrawerView { builder, job }

class NodeDrawer extends ConsumerStatefulWidget {
  final WorkflowNode node;
  final NodeDrawerView view;
  final VoidCallback onClose;
  final bool isPortrait;

  NodeDrawer({
    super.key,
    required this.node,
    this.view = NodeDrawerView.builder,
    required this.onClose,
    this.isPortrait = false,
  });

  @override
  ConsumerState<NodeDrawer> createState() => _NodeDrawerState();
}

class _NodeDrawerState extends ConsumerState<NodeDrawer> {
  late TextEditingController _labelCtrl;

  String get _tabKey => '${widget.node.id}_${widget.view.name}';

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.node.label);
  }

  @override
  void didUpdateWidget(covariant NodeDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _labelCtrl.text = widget.node.label;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _updateLabel(String value) {
    final wf = ref.read(workflowProvider);
    ref.read(workflowProvider.notifier).state = wf.copyWith(
      nodes: wf.nodes.map((n) {
        if (n.id == widget.node.id) {
          return n.copyWith(label: value);
        }
        return n;
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabsMap = ref.watch(nodeDrawerTabProvider);
    final _tab = tabsMap[_tabKey] ?? 'settings';
    final meta = widget.node.kind == 'genserver'
        ? 'genserver node'
        : widget.node.kind == 'task'
            ? 'task node'
            : widget.node.kind == 'delay'
                ? 'delay node'
                : widget.node.kind == 'http.ingress'
                    ? 'http ingress node'
                    : widget.node.kind == 'http.egress'
                        ? 'http egress node'
                        : widget.node.kind == 'http.request'
                            ? 'http request node'
                            : widget.node.kind == 'source.inject'
                        ? 'inject node'
                        : widget.node.kind == 'function'
                            ? 'function \u2014 if/else router'
                            : widget.node.kind == 'sink.log'
                                ? 'log sink node'
                                : 'node';

    final isWorker = widget.node.kind == 'genserver' || widget.node.kind == 'task' || widget.node.kind == 'delay' || widget.node.kind == 'http.ingress' || widget.node.kind == 'http.egress' || widget.node.kind == 'http.request' || widget.node.kind == 'source.inject' || widget.node.kind == 'sink.log';
    final isBuilder = widget.view == NodeDrawerView.builder;

    final tabs = isWorker
        ? [
            _Tab(value: 'settings', label: 'node'),
            _Tab(value: 'prompt', label: 'prompt'),
            _Tab(value: 'result', label: 'result'),
          ]
        : [_Tab(value: 'settings', label: 'routing')];

    return Container(
      width: widget.isPortrait ? double.infinity : 460,
      height: widget.isPortrait ? double.infinity : null,
      decoration: BoxDecoration(
        color: AppColors.bg1,
        border: Border(
          top: widget.isPortrait
              ? BorderSide(color: AppColors.border1, width: 1)
              : BorderSide.none,
          left: widget.isPortrait
              ? BorderSide.none
              : BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border1, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: (isWorker)
                        ? AppColors.bg3
                        : AppColors.bg3,
                    border: Border.all(
                      color: (isWorker)
                          ? Colors.transparent
                          : AppColors.border3,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: TrailheadIcon(
                    icon: isWorker
                        ? TrailheadIconData.zap
                        : TrailheadIconData.gitBranch,
                    size: 14,
                    color: (isWorker)
                        ? AppColors.accentInk
                        : AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _labelCtrl,
                        onChanged: _updateLabel,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg0,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.node.id} \u00b7 $meta${!isBuilder ? " \u00b7 log" : ""}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: AppColors.fg2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onClose,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: TrailheadIcon(
                        icon: TrailheadIconData.x,
                        size: 14,
                        color: AppColors.fg2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabs (builder only)
          if (isBuilder && tabs.length > 1)
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg2,
                border: Border(
                  bottom: BorderSide(color: AppColors.border1, width: 1),
                ),
              ),
              child: Row(
                children: tabs.map((t) => _buildTab(t)).toList(),
              ),
            ),
          // Body
          Expanded(
            child: isBuilder
                ? (_tab == 'settings'
                    ? EditorSettingsTab(node: widget.node)
                    : _tab == 'prompt'
                        ? EditorPromptTab(node: widget.node)
                        : _tab == 'result'
                            ? EditorResultTab(node: widget.node)
                            : const SizedBox.shrink())
                : JobLogView(node: widget.node),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(_Tab t) {
    final tabsMap = ref.watch(nodeDrawerTabProvider);
    final tab = tabsMap[_tabKey] ?? 'settings';
    final active = tab == t.value;
    return GestureDetector(
      onTap: () {
        final next = Map<String, String>.from(tabsMap);
        next[_tabKey] = t.value;
        ref.read(nodeDrawerTabProvider.notifier).state = next;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          t.label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppColors.fg0 : AppColors.fg2,
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String value;
  final String label;
  _Tab({required this.value, required this.label});
}

// ════════════════════════════════════════════════════════════════════════
// Shared atoms
// ════════════════════════════════════════════════════════════════════════

class Field extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;

  Field({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 0.06 * 10,
                color: AppColors.fg3,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hint != null)
              Expanded(
                child: Text(
                  hint!,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.fg3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

class PreBlock extends StatelessWidget {
  final String value;
  final Color? borderColor;

  PreBlock({super.key, required this.value, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(
          color: borderColor ?? AppColors.border2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.fg0,
        ),
      ),
    );
  }
}

class SchemaEditor extends StatelessWidget {
  final Map<String, dynamic> schema;

  SchemaEditor({super.key, required this.schema});

  @override
  Widget build(BuildContext context) {
    final text = const JsonEncoder.withIndent('  ').convert(schema);
    final lines = text.split('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.asMap().entries.map((e) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                padding: const EdgeInsets.only(right: 10),
                alignment: Alignment.topRight,
                child: Text(
                  '${e.key + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.fg3,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: _SyntaxLine(line: e.value),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SyntaxLine extends StatelessWidget {
  final String line;
  _SyntaxLine({required this.line});

  @override
  Widget build(BuildContext context) {
    final keywords = {'true', 'false', 'null'};
    final types = {'object', 'string', 'integer', 'boolean', 'array', 'number'};
    final spans = <TextSpan>[];

    var i = 0;
    while (i < line.length) {
      final ch = line[i];
      if (ch == '"') {
        var j = i + 1;
        while (j < line.length && line[j] != '"') j++;
        final s = line.substring(i, j + 1);
        final after = line.substring(j + 1).trimLeft();
        final isKey = after.startsWith(':');
        final inner = s.substring(1, s.length - 1);
        var color = AppColors.synString;
        if (isKey) color = AppColors.synFunction;
        else if (types.contains(inner)) color = AppColors.synKeyword;
        spans.add(TextSpan(text: s, style: TextStyle(color: color)));
        i = j + 1;
      } else if (RegExp(r'[0-9]').hasMatch(ch)) {
        var j = i;
        while (j < line.length && RegExp(r'[0-9.]').hasMatch(line[j])) j++;
        spans.add(TextSpan(
          text: line.substring(i, j),
          style: TextStyle(color: AppColors.synNumber),
        ));
        i = j;
      } else if (RegExp(r'[a-z]').hasMatch(ch)) {
        var j = i;
        while (j < line.length && RegExp(r'[a-z0-9_]').hasMatch(line[j])) j++;
        final word = line.substring(i, j);
        final color = keywords.contains(word)
            ? AppColors.synKeyword
            : types.contains(word)
                ? AppColors.synType
                : AppColors.fg0;
        spans.add(TextSpan(text: word, style: TextStyle(color: color)));
        i = j;
      } else {
        spans.add(TextSpan(
          text: ch,
          style: TextStyle(color: AppColors.synPunct),
        ));
        i++;
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.fg0,
        ),
      ),
    );
  }
}

class EmptyBlock extends StatelessWidget {
  final String label;
  EmptyBlock({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.fg3,
        ),
      ),
    );
  }
}
