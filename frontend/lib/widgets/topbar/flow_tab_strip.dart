import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workflow_document.dart';
import '../../providers/api_provider.dart';
import '../../providers/flow_tabs_provider.dart';
import '../../providers/mode_provider.dart';
import '../../providers/mock_data.dart' show WorkflowSummary;
import '../../providers/subflows_provider.dart';
import '../../providers/carta_provider.dart';
import '../../theme/tokens.dart';
import '../../utils/workflow_to_yaml.dart';
import '../icons.dart';

/// Node-RED-style tab strip across the TopBar: one tab per project flow,
/// subflows as visually distinct tabs. Horizontal scroll overflow, drag to
/// reorder (persisted via flow-order for flows), `+` menu to create, and a
/// context/long-press menu for rename + delete (no close buttons).
class FlowTabStrip extends ConsumerStatefulWidget {
  const FlowTabStrip({super.key});

  @override
  ConsumerState<FlowTabStrip> createState() => _FlowTabStripState();
}

class _FlowTabStripState extends ConsumerState<FlowTabStrip> {
  FlowTab? _renaming;
  OverlayEntry? _menu;
  OverlayEntry? _plusMenu;
  final _plusLink = LayerLink();

  @override
  void dispose() {
    _closeMenus();
    super.dispose();
  }

  void _closeMenus() {
    _menu?.remove();
    _menu = null;
    _plusMenu?.remove();
    _plusMenu = null;
  }

  // ---- reorder ----

  void _onReorder(int oldIndex, int newIndex) {
    final tabs = List<FlowTab>.from(ref.read(flowTabsProvider));
    if (newIndex > oldIndex) newIndex -= 1;
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
    ref.read(flowTabsProvider.notifier).state = tabs;
    persistFlowOrder(ref, tabs);
  }

  // ---- context menu ----

  void _showTabMenu(FlowTab tab, Offset pos) {
    _closeMenus();
    _menu = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenus,
              onSecondaryTap: _closeMenus,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: pos.dx,
            top: pos.dy + 4,
            child: _TabMenu(
              onRename: () {
                _closeMenus();
                setState(() => _renaming = tab);
              },
              onDelete: () {
                _closeMenus();
                _confirmDelete(tab);
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_menu!);
  }

  // ---- delete ----

  Future<void> _confirmDelete(FlowTab tab) async {
    final kindLabel = tab.kind == FlowTabKind.flow ? 'flow' : 'subflow';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Delete $kindLabel?',
            style: TextStyle(color: AppColors.fg0)),
        content: Text(
          '"${tab.name}" will be permanently deleted from the project.',
          style: TextStyle(color: AppColors.fg2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteTab(tab);
  }

  Future<void> _deleteTab(FlowTab tab) async {
    try {
      if (tab.kind == FlowTabKind.flow) {
        await ref.read(workflowsApiProvider).delete(tab.name);
      } else {
        await ref.read(subflowsApiProvider).delete(tab.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delete failed: $e')),
        );
      }
      return;
    }

    // Remove the tab locally BEFORE refreshing the server list: the sync
    // provider reconciles tabs against the refreshed list, so the local set
    // must already reflect the delete or the reconcile + selection repair
    // race the neighbor switch below.
    final tabs = List<FlowTab>.from(ref.read(flowTabsProvider));
    final index = tabs.indexOf(tab);
    tabs.remove(tab);
    ref.read(flowTabsProvider.notifier).state = tabs;
    ref.read(documentsProvider.notifier).update((docs) {
      final m = Map<String, WorkflowDocument>.from(docs)..remove(tab.docId);
      return m;
    });
    if (tab.kind == FlowTabKind.flow) {
      persistFlowOrder(ref, tabs);
    }

    // If the active tab was deleted, switch to a neighbor (the sync
    // provider only repairs flow-tab selection — subflows are handled here).
    final current = ref.read(workflowProvider);
    final wasActive = ref.read(activeTabKindProvider) == tab.kind &&
        current.name == tab.name;
    if (wasActive) {
      // Reset to the sentinel first so the switch never flushes the deleted
      // document back to the backend.
      ref.read(workflowProvider.notifier).state = WorkflowSummary(
          id: emptyWorkflowId, name: '', version: 0, updated: '');
      if (tabs.isNotEmpty) {
        final neighbor = tabs[index.clamp(0, tabs.length - 1)];
        await switchToTab(ref, neighbor);
      } else {
        ref.read(activeTabKindProvider.notifier).state = FlowTabKind.flow;
      }
    }

    // Refresh the server list last so the sync reconcile sees the already
    // consistent local tab set.
    try {
      if (tab.kind == FlowTabKind.flow) {
        await refreshWorkflows(ref);
      } else {
        ref.invalidate(subflowsProvider);
        await ref.read(subflowsProvider.future);
      }
    } catch (e) {
      debugPrint('post-delete refresh failed: $e');
    }
  }

  // ---- rename ----

  Future<void> _commitRename(FlowTab tab, String clean) async {
    setState(() => _renaming = null);
    if (clean == tab.name) return;
    final newTab = FlowTab(tab.kind, clean);
    // The live document for the active tab is workflowProvider (with any
    // unsaved canvas edits) — prefer it over the viewport cache / remote
    // list, which only see flushed state.
    final liveDoc = ref.read(workflowProvider);
    final isActive = ref.read(activeTabKindProvider) == tab.kind &&
        liveDoc.name == tab.name;

    // Apply the tab swap + active-doc / viewport-cache migration immediately
    // (before the server-list refresh): the sync provider reconciles tabs
    // against the refreshed list and would otherwise drop the old-named tab
    // mid-rename — a subflow tab would never be re-added.
    void swapTab() {
      final tabs = List<FlowTab>.from(ref.read(flowTabsProvider));
      final idx = tabs.indexOf(tab);
      if (idx >= 0) {
        tabs[idx] = newTab;
        ref.read(flowTabsProvider.notifier).state = tabs;
      }
      final current = ref.read(workflowProvider);
      if (ref.read(activeTabKindProvider) == tab.kind &&
          current.name == tab.name) {
        ref.read(workflowProvider.notifier).state =
            current.copyWith(name: clean, id: newTab.docId);
      }
      ref.read(documentsProvider.notifier).update((docs) {
        if (!docs.containsKey(tab.docId)) return docs;
        final m = Map<String, WorkflowDocument>.from(docs);
        m[newTab.docId] = m.remove(tab.docId)!;
        return m;
      });
    }

    try {
      if (tab.kind == FlowTabKind.flow) {
        // Serialize the live/cached canvas doc when present, else the remote
        // list entry — mirrors the old dropdown's rename semantics.
        final wf = isActive
            ? liveDoc
            : ref.read(documentsProvider)[tab.docId]?.workflow ??
                ref
                    .read(workflowsProvider)
                    .cast<WorkflowSummary?>()
                    .firstWhere((w) => w!.name == tab.name, orElse: () => null);
        if (wf == null) return;
        final api = ref.read(workflowsApiProvider);
        await api.replace(clean, workflowToYaml(wf));
        await api.delete(tab.name).catchError((_) => false);
        swapTab();
        await refreshWorkflows(ref);
      } else {
        final cached = isActive
            ? liveDoc
            : ref.read(documentsProvider)[tab.docId]?.workflow;
        String? content = cached != null ? workflowToYaml(cached) : null;
        if (content == null) {
          for (final s in ref.read(subflowsProvider).valueOrNull ?? []) {
            if (s.name == tab.name) {
              content = s.content;
              break;
            }
          }
        }
        if (content == null) return;
        final api = ref.read(subflowsApiProvider);
        await api.replace(clean, content);
        await api.delete(tab.name).catchError((_) => false);
        swapTab();
        ref.invalidate(subflowsProvider);
        await ref.read(subflowsProvider.future);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('rename failed: $e')),
        );
      }
      return;
    }

    if (tab.kind == FlowTabKind.flow) {
      persistFlowOrder(ref, ref.read(flowTabsProvider));
    }
  }

  // ---- + menu ----

  void _togglePlusMenu() {
    if (_plusMenu != null) {
      _closeMenus();
      return;
    }
    _closeMenus();
    _plusMenu = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenus,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _plusLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlusMenuRow(
                      icon: CartaIconData.workflow,
                      label: 'new flow',
                      onTap: () {
                        _closeMenus();
                        createUntitledFlow(ref);
                      },
                    ),
                    _PlusMenuRow(
                      icon: CartaIconData.gitBranch,
                      label: 'new subflow',
                      iconColor: AppColors.info,
                      onTap: () {
                        _closeMenus();
                        createUntitledSubflow(ref);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_plusMenu!);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(flowTabsProvider);
    final activeName = ref.watch(workflowProvider).name;
    final activeKind = ref.watch(activeTabKindProvider);
    final statuses = ref.watch(flowStatusProvider);

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: tabs.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (context, i) {
                final tab = tabs[i];
                final siblings = tab.kind == FlowTabKind.flow
                    ? ref
                        .read(workflowsProvider)
                        .map((w) => w.name)
                        .where((n) => n != tab.name)
                        .toList()
                    : (ref.read(subflowsProvider).valueOrNull ?? [])
                        .map((s) => s.name)
                        .where((n) => n != tab.name)
                        .toList();
                return ReorderableDragStartListener(
                  key: ValueKey(tab.docId),
                  index: i,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _TabChip(
                      tab: tab,
                      active:
                          tab.kind == activeKind && tab.name == activeName,
                      deployed: tab.kind == FlowTabKind.flow &&
                          (statuses[tab.name]?.deployed ?? false),
                      renaming: _renaming == tab,
                      siblings: siblings,
                      onTap: () {
                        _closeMenus();
                        switchToTab(ref, tab);
                      },
                      onContextMenu: (pos) => _showTabMenu(tab, pos),
                      onRenameCommit: (name) => _commitRename(tab, name),
                      onRenameCancel: () => setState(() => _renaming = null),
                    ),
                  ),
                );
              },
            ),
          ),
          CompositedTransformTarget(
            link: _plusLink,
            child: _PlusButton(onTap: _togglePlusMenu),
          ),
        ],
      ),
    );
  }
}

class _PlusButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlusButton({required this.onTap});

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.bg3 : AppColors.bg2,
            border: Border.all(color: AppColors.border1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: CartaIcon(
              icon: CartaIconData.plus,
              size: 13,
              color: AppColors.fg2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatefulWidget {
  final FlowTab tab;
  final bool active;
  final bool deployed;
  final bool renaming;
  final List<String> siblings;
  final VoidCallback onTap;
  final ValueChanged<Offset> onContextMenu;
  final ValueChanged<String> onRenameCommit;
  final VoidCallback onRenameCancel;

  const _TabChip({
    required this.tab,
    required this.active,
    required this.deployed,
    required this.renaming,
    required this.siblings,
    required this.onTap,
    required this.onContextMenu,
    required this.onRenameCommit,
    required this.onRenameCancel,
  });

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (widget.renaming) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 3),
          child: _TabRenameField(
            initial: widget.tab.name,
            siblings: widget.siblings,
            onCommit: widget.onRenameCommit,
            onCancel: widget.onRenameCancel,
          ),
        ),
      );
    }

    final isFlow = widget.tab.kind == FlowTabKind.flow;
    final iconColor = isFlow
        ? (widget.active ? AppColors.accent : AppColors.fg3)
        : AppColors.info;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (d) => widget.onContextMenu(d.globalPosition),
        onLongPressStart: (d) => widget.onContextMenu(d.globalPosition),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
            decoration: BoxDecoration(
              color: widget.active
                  ? AppColors.bg2
                  : (_hovering ? AppColors.bg2 : Colors.transparent),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            // Accent underline on a separate decoration layer with NO
            // borderRadius — the bottom edge of the rect is straight (only
            // the top is rounded), so a rectangular Border.bottom paints a
            // clean line with no clip-path bleed at the corners.
            foregroundDecoration: widget.active
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 2, color: AppColors.accent),
                    ),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CartaIcon(
                  icon: isFlow
                      ? CartaIconData.workflow
                      : CartaIconData.gitBranch,
                  size: 12,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    widget.tab.name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: widget.active
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.active ? AppColors.fg0 : AppColors.fg1,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.deployed) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabRenameField extends StatefulWidget {
  final String initial;
  final List<String> siblings;
  final ValueChanged<String> onCommit;
  final VoidCallback onCancel;

  const _TabRenameField({
    required this.initial,
    required this.siblings,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<_TabRenameField> createState() => _TabRenameFieldState();
}

class _TabRenameFieldState extends State<_TabRenameField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focusNode;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _ctrl.text.length,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static String _sanitize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  bool get _invalid {
    final clean = _sanitize(_ctrl.text);
    return clean.isEmpty ||
        widget.siblings.any((n) => n.toLowerCase() == clean.toLowerCase());
  }

  void _commit() {
    if (_committed || _invalid) return;
    _committed = true;
    widget.onCommit(_sanitize(_ctrl.text));
  }

  void _cancel() {
    if (_committed) return;
    _committed = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final invalid = _invalid && _ctrl.text.trim().isNotEmpty;
    return SizedBox(
      width: 160,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              _cancel();
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (!_invalid) _commit();
            }
          }
        },
        child: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _invalid ? null : _commit(),
          onTapOutside: (_) => _invalid ? _cancel() : _commit(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.fg0,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            filled: true,
            fillColor: AppColors.bg0,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: invalid ? AppColors.danger : AppColors.accent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: invalid ? AppColors.danger : AppColors.accent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: invalid ? AppColors.danger : AppColors.accent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabMenu extends StatelessWidget {
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _TabMenu({required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.bg1,
          border: Border.all(color: AppColors.border2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TabMenuRow(
              icon: CartaIconData.pencil,
              label: 'rename',
              onTap: onRename,
            ),
            _TabMenuRow(
              icon: CartaIconData.trash,
              label: 'delete',
              danger: true,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabMenuRow extends StatefulWidget {
  final CartaIconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _TabMenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
    required this.onTap,
  });

  @override
  State<_TabMenuRow> createState() => _TabMenuRowState();
}

class _TabMenuRowState extends State<_TabMenuRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.danger ? AppColors.danger : AppColors.fg1;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.bg3 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              CartaIcon(icon: widget.icon, size: 13, color: fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
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

class _PlusMenuRow extends StatefulWidget {
  final CartaIconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _PlusMenuRow({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  State<_PlusMenuRow> createState() => _PlusMenuRowState();
}

class _PlusMenuRowState extends State<_PlusMenuRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.bg3 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              CartaIcon(
                icon: widget.icon,
                size: 13,
                color: widget.iconColor ?? AppColors.fg2,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.fg1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
