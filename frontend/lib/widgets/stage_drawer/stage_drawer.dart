import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/workflow_node.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import 'editor_settings_tab.dart';
import 'editor_prompt_tab.dart';
import 'editor_result_tab.dart';
import 'job_log_view.dart';

enum StageDrawerView { builder, job }

class StageDrawer extends StatefulWidget {
  final WorkflowNode stage;
  final StageDrawerView view;
  final VoidCallback onClose;
  final bool isPortrait;

  const StageDrawer({
    super.key,
    required this.stage,
    this.view = StageDrawerView.builder,
    required this.onClose,
    this.isPortrait = false,
  });

  @override
  State<StageDrawer> createState() => _StageDrawerState();
}

class _StageDrawerState extends State<StageDrawer> {
  String _tab = 'settings';

  @override
  void didUpdateWidget(covariant StageDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.id != widget.stage.id) {
      _tab = 'settings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.stage.kind == 'worker'
        ? 'worker stage'
        : widget.stage.kind == 'fan'
            ? 'map \u2014 iterate over a list'
            : widget.stage.kind == 'branch'
                ? 'branch \u2014 if/else router'
                : 'routing operator';

    final isWorker = widget.stage.kind == 'worker';
    final isMap = widget.stage.kind == 'fan';
    final isBuilder = widget.view == StageDrawerView.builder;

    final tabs = isWorker
        ? [
            _Tab(value: 'settings', label: 'stage'),
            _Tab(value: 'prompt', label: 'prompt'),
            _Tab(value: 'result', label: 'result'),
          ]
        : isMap
            ? [_Tab(value: 'settings', label: 'container')]
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
                    color: (isWorker || isMap)
                        ? AppColors.bg3
                        : AppColors.bg3,
                    border: Border.all(
                      color: (isWorker || isMap)
                          ? Colors.transparent
                          : AppColors.border3,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: TrailheadIcon(
                    icon: isWorker
                        ? TrailheadIconData.zap
                        : isMap
                            ? TrailheadIconData.forEach
                            : TrailheadIconData.gitBranch,
                    size: 14,
                    color: (isWorker || isMap)
                        ? AppColors.accentInk
                        : AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stage.label,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.stage.id} \u00b7 $meta${!isBuilder ? " \u00b7 log" : ""}',
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
                    ? EditorSettingsTab(stage: widget.stage)
                    : _tab == 'prompt'
                        ? EditorPromptTab(stage: widget.stage)
                        : _tab == 'result'
                            ? EditorResultTab(stage: widget.stage)
                            : const SizedBox.shrink())
                : JobLogView(stage: widget.stage),
          ),
          // Footer (builder only)
          if (isBuilder && isWorker)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border1, width: 1),
                ),
                color: AppColors.bg2,
              ),
              child: Row(
                children: [
                  _FooterBtn(
                    icon: TrailheadIconData.copy,
                    label: 'duplicate',
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FooterBtn(
                    icon: TrailheadIconData.trash,
                    label: 'delete',
                    accent: AppColors.danger,
                    onTap: () {},
                  ),
                  const Spacer(),
                  _FooterBtn(
                    icon: TrailheadIconData.check,
                    label: 'save',
                    filled: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(_Tab t) {
    final active = _tab == t.value;
    return GestureDetector(
      onTap: () => setState(() => _tab = t.value),
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

class _FooterBtn extends StatefulWidget {
  final TrailheadIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;
  final bool filled;

  const _FooterBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.filled = false,
  });

  @override
  State<_FooterBtn> createState() => _FooterBtnState();
}

class _FooterBtnState extends State<_FooterBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.accent ??
        (widget.filled ? AppColors.accentInk : AppColors.fg0);
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.filled
                ? AppColors.accent
                : (_hover ? AppColors.bg3 : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TrailheadIcon(
                icon: widget.icon,
                size: 12,
                color: fg,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// Shared atoms
// ════════════════════════════════════════════════════════════════════════

class Field extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;

  const Field({
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

  const PreBlock({super.key, required this.value, this.borderColor});

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

class PromptTokens extends StatelessWidget {
  final String value;

  const PromptTokens({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final parts = value.split(RegExp(r'(\{\{[^}]+\}\})'));
    final matches = RegExp(r'\{\{[^}]+\}\}').allMatches(value).map((m) => m.group(0)!).toList();

    final spans = <InlineSpan>[];
    var matchIdx = 0;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
      if (matchIdx < matches.length) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                matches[matchIdx],
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        );
        matchIdx++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: spans,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            height: 1.55,
            color: AppColors.fg0,
          ),
        ),
      ),
    );
  }
}

class SchemaEditor extends StatelessWidget {
  final Map<String, dynamic> schema;

  const SchemaEditor({super.key, required this.schema});

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
  const _SyntaxLine({required this.line});

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
  const EmptyBlock({super.key, required this.label});

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
