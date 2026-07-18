import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/node_catalog.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';

class OperatorPicker extends StatefulWidget {
  final Offset anchor;
  final void Function(NodeEntry entry) onSelect;
  final VoidCallback onClose;

  OperatorPicker({
    super.key,
    required this.anchor,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<OperatorPicker> createState() => _OperatorPickerState();
}

class _OperatorPickerState extends State<OperatorPicker> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _fuzzyMatch(String text, String query) {
    if (query.isEmpty) return true;
    text = text.toLowerCase();
    query = query.toLowerCase();
    var ti = 0;
    for (var qi = 0; qi < query.length; qi++) {
      ti = text.indexOf(query[qi], ti);
      if (ti == -1) return false;
      ti++;
    }
    return true;
  }

  bool _entryMatches(NodeEntry entry, String query) {
    if (query.isEmpty) return true;
    return _fuzzyMatch(entry.label, query) ||
        _fuzzyMatch(entry.kind, query) ||
        _fuzzyMatch(entry.desc, query);
  }

  List<NodeEntry> _filtered(List<NodeEntry> entries) {
    if (_query.isEmpty) return entries;
    return entries.where((e) => _entryMatches(e, _query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: widget.anchor.dx,
          top: widget.anchor.dy,
          child: Container(
            width: 270,
            constraints: const BoxConstraints(maxHeight: 440),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // header + search
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
                  child: Row(
                    children: [
                      Text(
                        'ADD NODE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          letterSpacing: 0.08 * 10,
                          color: AppColors.fg3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: TrailheadIcon(
                            icon: TrailheadIconData.x,
                            size: 10,
                            color: AppColors.fg3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: SizedBox(
                    height: 26,
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg0,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.bg0,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        hintText: 'fuzzy search...',
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: AppColors.fg3,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: AppColors.border2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: AppColors.border2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.border1),
                // scrollable list
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(4),
                    shrinkWrap: true,
                    children: () {
                      final cats = <Widget>[];
                      for (final cat in nodeCategories) {
                        final filtered = _filtered(cat.entries);
                        if (filtered.isEmpty) continue;
                        cats.add(
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                letterSpacing: 0.06 * 9,
                                color: AppColors.fg3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                        for (final entry in filtered) {
                          cats.add(
                            _OperatorRow(
                              entry: entry,
                              onTap: () => widget.onSelect(entry),
                            ),
                          );
                        }
                      }
                      return cats;
                    }(),
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

class _OperatorRow extends StatefulWidget {
  final NodeEntry entry;
  final VoidCallback onTap;

  const _OperatorRow({required this.entry, required this.onTap});

  @override
  State<_OperatorRow> createState() => _OperatorRowState();
}

class _OperatorRowState extends State<_OperatorRow> {
  bool _hover = false;

  Future<void> _openDocs() async {
    final url = widget.entry.docsUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isTransform = entry.isTransform;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: _hover ? AppColors.bg3 : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      isTransform
                          ? AppColors.bg3
                          : AppColors.accent.withValues(alpha: 0.14),
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: TrailheadIcon(
                    icon: entry.icon,
                    size: 11,
                    color: isTransform ? AppColors.fg2 : AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      entry.desc,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        color: AppColors.fg3,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.docsUrl != null)
                GestureDetector(
                  onTap: _openDocs,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TrailheadIcon(
                        icon: TrailheadIconData.globe,
                        size: 11,
                        color: AppColors.fg3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
