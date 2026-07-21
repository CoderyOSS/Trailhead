import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/modules_provider.dart';
import '../../services/modules_api.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';

/// THRT module (linked package) browser. Lists every visible package —
/// project links, registered project dirs, and global packages — with their
/// node types and packaged subflows. Register/unregister writes through to
/// `~/.trailhead/projects.yaml` (idempotent — no restart needed).
class ModulesSection extends ConsumerStatefulWidget {
  const ModulesSection({super.key});

  @override
  ConsumerState<ModulesSection> createState() => _ModulesSectionState();
}

class _ModulesSectionState extends ConsumerState<ModulesSection> {
  final _registerController = TextEditingController();
  bool _showRegister = false;
  String _registering = '';

  @override
  void dispose() {
    _registerController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final path = _registerController.text.trim();
    if (path.isEmpty) return;

    setState(() => _registering = path);
    try {
      await ref.read(modulesApiProvider).register(path);
      ref.invalidate(registeredModulesProvider);
      _registerController.clear();
      if (mounted) {
        setState(() {
          _showRegister = false;
          _registering = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registered $path',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.bg4,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _registering = '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Register failed: $e',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _unregister(InstalledModule m) async {
    try {
      await ref.read(modulesApiProvider).unregister(m.sourcePath);
      ref.invalidate(registeredModulesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unlinked ${m.name}. Restart BEAM to fully unload modules.',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.bg4,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unlink failed: $e',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _reload() async {
    try {
      await ref.read(modulesApiProvider).reload();
      ref.invalidate(registeredModulesProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(registeredModulesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          'MODULES',
          'THRT-linked packages provide node types and reusable subflows. '
          'Changes appear without restart — link/unlink is hot.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text('REGISTERED PACKAGES',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 0.06 * 10,
                      color: AppColors.fg3,
                      fontWeight: FontWeight.w600)),
            ),
            _iconButton(
              icon: TrailheadIconData.refresh,
              tip: 'Reload registry',
              onTap: _reload,
            ),
            const SizedBox(width: 6),
            _iconButton(
              icon: TrailheadIconData.plus,
              tip: 'Register package path',
              onTap: () => setState(() => _showRegister = !_showRegister),
            ),
          ],
        ),
        if (_showRegister) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _registerController,
                    autofocus: true,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.fg0),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      hintText: '/abs/path/to/package (must have thrt_package.yaml)',
                      hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.fg3),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _register(),
                  ),
                ),
                const SizedBox(width: 8),
                _registering.isNotEmpty
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent))
                    : MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _register,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Link',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentInk)),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        modulesAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.fg2))),
          ),
          error: (e, _) => _errorRow('Failed to load modules: $e'),
          data: (modules) {
            if (modules.isEmpty) {
              return _emptyState();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: modules
                  .map((m) => _ModuleCard(
                        module: m,
                        onUnregister: () => _unregister(m),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 0.08 * 11,
                color: AppColors.fg3,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.fg2,
                height: 1.5)),
      ],
    );
  }

  Widget _iconButton({
    required TrailheadIconData icon,
    required String tip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TrailheadIcon(
                icon: icon, size: 11, color: AppColors.fg1),
          ),
        ),
      ),
    );
  }

  Widget _errorRow(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(msg,
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: AppColors.danger)),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: TrailheadIcon(
                  icon: TrailheadIconData.plug,
                  size: 18,
                  color: AppColors.fg2),
            ),
          ),
          const SizedBox(height: 14),
          Text('No modules registered',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fg0)),
          const SizedBox(height: 6),
          Text(
            'Register a package directory (one with a thrt_package.yaml) '
            'using the + button above.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: AppColors.fg2,
                height: 1.55),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Module card — expandable tile per registered package
// ---------------------------------------------------------------------------

class _ModuleCard extends StatefulWidget {
  final InstalledModule module;
  final VoidCallback onUnregister;

  const _ModuleCard({required this.module, required this.onUnregister});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Header row (tap to expand)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    TrailheadIcon(
                        icon: TrailheadIconData.chevRight,
                        size: 10,
                        color: AppColors.fg2),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(m.name,
                                  style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.fg0)),
                              if (m.version != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg0,
                                    border: Border.all(
                                        color: AppColors.border2, width: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text('v${m.version}',
                                      style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9.5,
                                          color: AppColors.fg2)),
                                ),
                              ],
                              const SizedBox(width: 8),
                              _originPill(m.origin),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(m.sourcePath,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  color: AppColors.fg3)),
                        ],
                      ),
                    ),
                    // Unlink (only for registered — current project's own
                    // links can't be removed here, user must edit trailhead.yaml).
                    if (m.origin != ModuleOrigin.project)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onUnregister,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: TrailheadIcon(
                                icon: TrailheadIconData.x,
                                size: 11,
                                color: AppColors.fg2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(28, 4, 14, 12),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border1, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.nodeTypes.isNotEmpty) ...[
                    _subLabel('NODE TYPES (${m.nodeTypes.length})'),
                    ...m.nodeTypes.map((n) => _NodeTypeRow(node: n)),
                    if (m.subflows.isNotEmpty) const SizedBox(height: 12),
                  ],
                  if (m.subflows.isNotEmpty) ...[
                    _subLabel('SUBFLOWS (${m.subflows.length})'),
                    ...m.subflows.map((s) => _SubflowRow(
                          module: m.name,
                          subflow: s,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      'Subflow editor coming soon — drop a `subflow` node on '
                      'the canvas to consume.',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.fg3,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _originPill(ModuleOrigin o) {
    final (label, color) = switch (o) {
      ModuleOrigin.project =>
        ('project', AppColors.accent.withValues(alpha: 0.7)),
      ModuleOrigin.registered =>
        ('registered', AppColors.fg2.withValues(alpha: 0.7)),
      ModuleOrigin.global => ('global', AppColors.fg3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: color)),
    );
  }

  Widget _subLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              letterSpacing: 0.06 * 9.5,
              color: AppColors.fg3,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _NodeTypeRow extends StatelessWidget {
  final ModuleNodeType node;
  const _NodeTypeRow({required this.node});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: node.actor
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : AppColors.bg3,
              border: Border.all(color: AppColors.border2, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: TrailheadIcon(
                  icon: node.actor ? TrailheadIconData.zap : TrailheadIconData.terminal,
                  size: 9,
                  color: node.actor ? AppColors.accent : AppColors.fg2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.fullType,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg0)),
                if (node.desc.isNotEmpty)
                  Text(node.desc,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.fg3,
                          height: 1.4)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              border: Border.all(color: AppColors.border2, width: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(node.actor ? 'actor' : 'function',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: AppColors.fg2)),
          ),
        ],
      ),
    );
  }
}

class _SubflowRow extends StatelessWidget {
  final String module;
  final String subflow;
  const _SubflowRow({required this.module, required this.subflow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          TrailheadIcon(
              icon: TrailheadIconData.workflow,
              size: 11,
              color: AppColors.fg2),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$module / $subflow',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.fg0)),
              ],
            ),
          ),
          // Disabled editor button — feature is deferred.
          Tooltip(
            message: 'Subflow editor coming soon',
            waitDuration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border.all(color: AppColors.border2, width: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TrailheadIcon(
                      icon: TrailheadIconData.lock,
                      size: 9,
                      color: AppColors.fg3),
                  const SizedBox(width: 4),
                  Text('Open editor',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          color: AppColors.fg3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
