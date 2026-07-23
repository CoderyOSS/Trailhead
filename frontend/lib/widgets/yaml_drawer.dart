import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/tokens.dart';
import '../providers/api_provider.dart';
import '../providers/flow_tabs_provider.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart' show WorkflowSummary;
import '../providers/subflows_provider.dart';
import '../services/jobs_api.dart';
import '../utils/workflow_to_yaml.dart';
import '../utils/yaml_to_workflow.dart';
import '../utils/clipboard_stub.dart'
    if (dart.library.html) '../utils/clipboard_web.dart';
import 'app_button.dart';
import 'icons.dart';
import 'validation_banner.dart';

class YamlDrawer extends ConsumerStatefulWidget {
  final WorkflowSummary workflow;
  final JobDto? job;
  final VoidCallback onClose;
  final bool isPortrait;

  YamlDrawer({
    super.key,
    required this.workflow,
    this.job,
    required this.onClose,
    this.isPortrait = false,
  });

  @override
  ConsumerState<YamlDrawer> createState() => _YamlDrawerState();
}

class _YamlDrawerState extends ConsumerState<YamlDrawer> {
  bool _copied = false;
  bool _showFind = false;
  bool _reloading = false;
  final _searchController = TextEditingController();

  /// Refetch the stored workflow YAML from the backend and replace the
  /// active canvas model. The drawer itself compiles from the canvas model,
  /// so this is how server-side changes (or a stale local draft) get pulled.
  /// Subflow tabs refetch through the subflow CRUD.
  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      if (ref.read(activeTabKindProvider) == FlowTabKind.subflow) {
        final dto =
            await ref.read(subflowsApiProvider).get(widget.workflow.name);
        final tab = FlowTab(FlowTabKind.subflow, dto.name);
        final updated =
            yamlToWorkflow(dto.name, dto.content).copyWith(id: tab.docId);
        ref.read(workflowProvider.notifier).state = updated;
        ref.invalidate(subflowsProvider);
      } else {
        final api = ref.read(workflowsApiProvider);
        final dto = await api.get(widget.workflow.name);
        final updated = yamlToWorkflow(dto.name, dto.content);
        ref.read(workflowProvider.notifier).state = updated;
        ref.invalidate(remoteWorkflowDtosProvider);
      }
    } catch (e) {
      debugPrint('yaml reload failed: $e');
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  String get _fileName {
    if (widget.job != null) return '${widget.job!.id}.resolved.yaml';
    return '${widget.workflow.name}.yaml';
  }

  String get _yamlText {
    // For resolved job runs, show the pinned backend YAML.
    // For builder mode, always compile the current canvas state so edits
    // are reflected immediately.
    final spec = workflowToYaml(widget.workflow);
    if (widget.job != null) {
      final remote = widget.workflow.remoteContent;
      if (remote != null && remote.isNotEmpty) {
        return '${_jobPreface(widget.job!)}\n$remote';
      }
      return '${_jobPreface(widget.job!)}\n$spec';
    }
    return spec;
  }

  String _jobPreface(JobDto job) {
    final status = job.status;
    return [
      '# --- resolved run spec ---',
      '# run:       ${job.id}',
      '# flow:      ${job.flowName}',
      '# status:    $status',
      '# this is the exact, pinned spec the run executed \u2014 read-only.',
      '# ---',
    ].join('\n');
  }

  void _copyAll() async {
    if (kIsWeb) {
      final ok = await fallbackCopy(_yamlText);
      if (!ok) return;
    } else {
      await Clipboard.setData(ClipboardData(text: _yamlText));
    }
    if (mounted) setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yamlResult = workflowToYamlWithLines(widget.workflow);
    // Builder mode always reflects the current canvas model; job mode shows
    // the pinned remote YAML when available.
    final compiledYaml = widget.job != null
        ? '${_jobPreface(widget.job!)}\n${yamlResult.yaml}'
        : yamlResult.yaml;
    final yamlText = compiledYaml;
    final lines = yamlText.split('\n');
    final lineCount = lines.length;
    final byteSize = yamlText.length;
    final sizeLabel = byteSize < 1024 ? '$byteSize B' : '${(byteSize / 1024).toStringAsFixed(1)} kB';
    final isJob = widget.job != null;
    final search = _searchController.text.trim().toLowerCase();
    final selectedNodeId = ref.watch(selectedNodeIdProvider);

    // Offset stage lines when job preface is present
    final prefaceOffset = isJob
        ? _jobPreface(widget.job!).split('\n').length + 1
        : 0;
    final nodeLines = yamlResult.nodeLines.map((k, v) => MapEntry(
          k,
          (start: v.start + prefaceOffset, end: v.end + prefaceOffset),
        ));

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
          // header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border1, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        border: Border.all(color: AppColors.border3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: CartaIcon(
                        icon: CartaIconData.file,
                        size: 14,
                        color: AppColors.accent,
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
                                  _fileName,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.fg0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ReadOnlyPill(),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$lineCount lines \u00b7 $sizeLabel \u00b7 ${isJob ? "pinned to run" : "compiled from v${widget.workflow.draft ?? widget.workflow.version} draft"}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: AppColors.fg2,
                              fontFeatures: [FontFeature.tabularFigures()],
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
                          child: CartaIcon(
                            icon: CartaIconData.x,
                            size: 14,
                            color: AppColors.fg2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // toolbar
                Row(
                  children: [
                    AppButton(
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      icon: _copied ? CartaIconData.check : CartaIconData.copy,
                      label: _copied ? 'copied' : 'copy',
                      onTap: _copyAll,
                    ),
                    const SizedBox(width: 6),
                    AppButton(
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      icon: CartaIconData.save,
                      label: 'download',
                      onTap: () {},
                    ),
                    const SizedBox(width: 6),
                    AppButton(
                      key: const Key('yaml_reload_button'),
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      icon: CartaIconData.refresh,
                      label: _reloading ? 'reloading…' : 'reload',
                      onTap: _reloading ? () {} : _reload,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showFind = !_showFind),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _showFind ? AppColors.bg4 : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: CartaIcon(
                            icon: CartaIconData.search,
                            size: 14,
                            color: _showFind ? AppColors.fg0 : AppColors.fg2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showFind) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    autofocus: true,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.fg0,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bg0,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      hintText: 'find in spec\u2026',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.fg3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // validation problems for this workflow (deploy-blocking)
          const ValidationBanner(),
          // body
          Expanded(
            child: Container(
              color: AppColors.bg2,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          _buildLine(
                            i + 1,
                            lines[i],
                            search,
                            nodeLines,
                            selectedNodeId,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border1, width: 1),
              ),
              color: AppColors.bg2,
            ),
            child: Row(
              children: [
                CartaIcon(
                  icon: CartaIconData.lock,
                  size: 11,
                  color: AppColors.fg2,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isJob
                        ? 'the canvas compiled this \u2014 rerun to change it'
                        : 'the canvas compiles this \u2014 edit nodes to change it',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: AppColors.fg2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(
    int lineNum,
    String raw,
    String query,
    Map<String, ({int start, int end})> nodeLines,
    String? selectedNodeId,
  ) {
    final hit = query.isNotEmpty && raw.toLowerCase().contains(query);

    // Find if this line belongs to a node
    String? nodeIdForLine;
    for (final entry in nodeLines.entries) {
      if (lineNum >= entry.value.start && lineNum <= entry.value.end) {
        nodeIdForLine = entry.key;
        break;
      }
    }
    final isNodeLine = nodeIdForLine != null;
    final isSelectedNode = nodeIdForLine == selectedNodeId;

    Color hitBg;
    if (hit) {
      hitBg = AppColors.accent.withValues(alpha: 0.14);
    } else if (isSelectedNode) {
      hitBg = AppColors.accent.withValues(alpha: 0.08);
    } else {
      hitBg = Colors.transparent;
    }

    return Container(
      color: hitBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gutter with node button
          Container(
            width: 64,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isNodeLine && raw.trimLeft().startsWith('- id:'))
                  GestureDetector(
                    onTap: () {
                      ref.read(selectedNodeIdProvider.notifier).state = nodeIdForLine;
                      ref.read(nodeDrawerOpenProvider.notifier).state = true;
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isSelectedNode
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : AppColors.bg3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: CartaIcon(
                          icon: CartaIconData.settings,
                          size: 10,
                          color: isSelectedNode ? AppColors.accent : AppColors.fg3,
                        ),
                      ),
                    ),
                  ),
                Text(
                  '$lineNum',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.fg3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _YamlLine(raw: raw),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CartaIcon(
            icon: CartaIconData.lock,
            size: 9,
            color: AppColors.fg2,
          ),
          const SizedBox(width: 4),
          Text(
            'read-only',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 9,
              color: AppColors.fg2,
            ),
          ),
        ],
      ),
    );
  }
}

class _YamlLine extends StatelessWidget {
  final String raw;

  _YamlLine({required this.raw});

  @override
  Widget build(BuildContext context) {
    final indentMatch = RegExp(r'^(\s*)(.*)$').firstMatch(raw);
    final indent = indentMatch?.group(1) ?? '';
    var rest = indentMatch?.group(2) ?? '';

    // Full-line comment.
    if (rest.startsWith('#')) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: indent),
            TextSpan(
              text: rest,
              style: TextStyle(
                color: AppColors.synComment,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            height: 1.65,
            color: AppColors.fg0,
          ),
        ),
      );
    }

    // Split off trailing inline comment.
    String? trailing;
    final hashIdx = rest.indexOf(RegExp(r'\s#'));
    if (hashIdx != -1) {
      final beforeHash = rest.substring(0, hashIdx);
      final quoteCount = beforeHash.split('"').length - 1;
      if (quoteCount % 2 == 0) {
        trailing = rest.substring(hashIdx);
        rest = beforeHash;
      }
    }

    // Leading list marker.
    String listMarker = '';
    final lm = RegExp(r'^(-\s+)(.*)$').firstMatch(rest);
    if (lm != null) {
      listMarker = lm.group(1)!;
      rest = lm.group(2)!;
    }

    final spans = <TextSpan>[];

    // key: value
    final kv = RegExp(r'^([A-Za-z0-9_.\-]+)(:)(\s*)(.*)$').firstMatch(rest);
    if (kv != null) {
      spans.add(TextSpan(text: kv.group(1), style: TextStyle(color: AppColors.synFunction)));
      spans.add(TextSpan(text: kv.group(2), style: TextStyle(color: AppColors.synPunct)));
      spans.add(TextSpan(text: kv.group(3), style: TextStyle(color: AppColors.fg0)));
      _pushValue(kv.group(4)!, spans);
    } else if (rest.isNotEmpty) {
      _pushValue(rest, spans);
    }

    final children = <InlineSpan>[
      TextSpan(text: indent),
    ];
    if (listMarker.isNotEmpty) {
      children.add(TextSpan(text: listMarker, style: TextStyle(color: AppColors.synPunct)));
    }
    children.addAll(spans);
    if (trailing != null) {
      children.add(TextSpan(
        text: trailing,
        style: TextStyle(color: AppColors.synComment, fontStyle: FontStyle.italic),
      ));
    }

    return Text.rich(
      TextSpan(
        children: children,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.65,
          color: AppColors.fg0,
        ),
      ),
    );
  }

  void _pushValue(String val, List<TextSpan> out) {
    if (val.isEmpty) return;

    // Block scalar indicators.
    if (val == '|' || val == '>' || val == '|-' || val == '>-') {
      out.add(TextSpan(text: val, style: TextStyle(color: AppColors.synKeyword)));
      return;
    }

    // Quoted string.
    if (RegExp(r'^".*"$').hasMatch(val)) {
      out.add(TextSpan(text: val, style: TextStyle(color: AppColors.synString)));
      return;
    }

    // Inline array [a, b, c].
    if (RegExp(r'^\[.*\]$').hasMatch(val)) {
      final inner = val.substring(1, val.length - 1);
      out.add(TextSpan(text: '[', style: TextStyle(color: AppColors.synPunct)));
      final parts = inner.split(RegExp(r'(,\s*)'));
      for (final tok in parts) {
        if (RegExp(r'^,\s*$').hasMatch(tok)) {
          out.add(TextSpan(text: tok, style: TextStyle(color: AppColors.synPunct)));
        } else {
          out.add(TextSpan(text: tok, style: TextStyle(color: AppColors.fg0)));
        }
      }
      out.add(TextSpan(text: ']', style: TextStyle(color: AppColors.synPunct)));
      return;
    }

    // Number.
    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(val)) {
      out.add(TextSpan(text: val, style: TextStyle(color: AppColors.synNumber)));
      return;
    }

    // Keyword literals + scalar types.
    const keywords = {'true', 'false', 'null'};
    const types = {'int', 'string', 'boolean', 'object', 'array', 'integer', 'number'};
    if (keywords.contains(val)) {
      out.add(TextSpan(text: val, style: TextStyle(color: AppColors.synKeyword)));
      return;
    }
    if (types.contains(val)) {
      out.add(TextSpan(text: val, style: TextStyle(color: AppColors.synType)));
      return;
    }

    // enum[...] shorthand.
    if (val.startsWith('enum[')) {
      out.add(TextSpan(text: val, style: TextStyle(color: AppColors.synType)));
      return;
    }

    // Bare scalar.
    out.add(TextSpan(text: val, style: TextStyle(color: AppColors.fg0)));
  }
}
