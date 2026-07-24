import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/packages_provider.dart';
import '../../services/packages_api.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';

/// Hex.pm-installed packages browser. Search → click install → Apply & Restart.
/// Existing installs show a version dropdown (read from Hex releases) and a
/// trash button that stages an uninstall. No hot-load: changes are staged to
/// `pending.json` on the backend and applied at next BEAM restart via the
/// `apply_pending!/0` boot hook.
class PackagesSection extends ConsumerStatefulWidget {
  PackagesSection({super.key});

  @override
  ConsumerState<PackagesSection> createState() => _PackagesSectionState();
}

class _PackagesSectionState extends ConsumerState<PackagesSection> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _showResults = false;
  String _installingName = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchController.text.trim();
      ref.read(packageSearchQueryProvider.notifier).state = q;
      setState(() => _showResults = q.isNotEmpty);
    });
  }

  Future<void> _install(HexSearchResult result) async {
    final version = result.version;
    if (version == null || version.isEmpty) return;

    setState(() => _installingName = result.name);
    try {
      await ref.read(packagesApiProvider).install(result.name, version);
      ref.invalidate(packagesStateProvider);
      // Clear search so the user sees the installed list update.
      _searchController.clear();
      setState(() {
        _showResults = false;
        _installingName = '';
      });
    } catch (e) {
      setState(() => _installingName = '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Install failed: $e',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _uninstall(String name) async {
    try {
      await ref.read(packagesApiProvider).uninstall(name);
      ref.invalidate(packagesStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Uninstall failed: $e',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _applyAndRestart() async {
    final state = ref.read(packagesStateProvider).valueOrNull;
    final pendingCount = state?.pendingCount ?? 0;
    if (pendingCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.border2)),
        title: Text('Apply and restart?',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.fg0)),
        content: Text(
          '$pendingCount pending package change(s) will be applied and the '
          'BEAM will restart. Any running jobs will be interrupted.',
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: AppColors.fg2,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'monospace', color: AppColors.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text('Restart',
                style: TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(packagesApiProvider).restart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restarting — backend will be back in a few seconds.',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.accent,
          ),
        );
      }
      // Poll-ish refresh after the BEAM comes back.
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) ref.invalidate(packagesStateProvider);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
        content: SelectableText('Restart failed: $e',
                style: const TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(packagesStateProvider);
    final resultsAsync = ref.watch(packageSearchResultsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header('HEX.PM PACKAGES',
            'Install Elixir libraries from hex.pm. Changes apply on next BEAM restart.'),
        const SizedBox(height: 14),
        // Search bar + dropdown
        _SearchField(
          controller: _searchController,
          showing: _showResults,
          results: resultsAsync,
          installingName: _installingName,
          onInstall: _install,
          onCloseResults: () => setState(() => _showResults = false),
        ),
        const SizedBox(height: 22),
        // Installed + pending
        stateAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.fg2))),
          ),
          error: (e, _) => _errorRow('Failed to load packages: $e'),
          data: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.pendingInstalls.isNotEmpty) ...[
                  _subHeader('PENDING INSTALL'),
                  ...state.pendingInstalls.map((p) => _PendingRow(
                        name: p.name,
                        version: p.version,
                        status: p.status,
                        reason: p.reason,
                      )),
                  const SizedBox(height: 14),
                ],
                if (state.pendingUninstalls.isNotEmpty) ...[
                  _subHeader('PENDING UNINSTALL'),
                  ...state.pendingUninstalls.map(
                      (n) => _PendingRow(name: n, version: '', pendingUninstall: true)),
                  const SizedBox(height: 14),
                ],
                _subHeader(state.installed.isEmpty
                    ? 'INSTALLED (none yet)'
                    : 'INSTALLED'),
                ...state.installed.map((p) => _InstalledRow(
                      pkg: p,
                      onUninstall: () => _uninstall(p.name),
                    )),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Sticky footer with pending count + apply button
        Builder(builder: (context) {
          final state = stateAsync.valueOrNull;
          final pending = state?.pendingCount ?? 0;
          if (pending == 0) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                CartaIcon(
                    icon: CartaIconData.refresh,
                    size: 14,
                    color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$pending change(s) pending — apply requires BEAM restart',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: AppColors.fg1),
                  ),
                ),
                TextButton(
                  onPressed: _applyAndRestart,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentInk,
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('Apply & Restart',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }),
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

  Widget _subHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 0.06 * 10,
              color: AppColors.fg3,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _errorRow(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SelectableText(msg,
          style: TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: AppColors.danger)),
    );
  }
}

// ---------------------------------------------------------------------------
// Search field + results dropdown
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool showing;
  final AsyncValue<List<HexSearchResult>> results;
  final String installingName;
  final void Function(HexSearchResult) onInstall;
  final VoidCallback onCloseResults;

  const _SearchField({
    required this.controller,
    required this.showing,
    required this.results,
    required this.installingName,
    required this.onInstall,
    required this.onCloseResults,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg0,
            border: Border.all(color: AppColors.border2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              CartaIcon(
                  icon: CartaIconData.search,
                  size: 14,
                  color: AppColors.fg2),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: AppColors.fg0),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    hintText: 'search hex.pm (e.g. decimal, jason, finch)',
                    hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.fg3),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (showing)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onCloseResults();
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CartaIcon(
                          icon: CartaIconData.x,
                          size: 12,
                          color: AppColors.fg2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showing)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: results.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.fg2))),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText('Search failed: $e',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.danger)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('No packages found.',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.fg2)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final r = list[i];
                    final installing = installingName == r.name;
                    return _SearchResultRow(
                      result: r,
                      installing: installing,
                      onInstall: () => onInstall(r),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  final HexSearchResult result;
  final bool installing;
  final VoidCallback onInstall;

  const _SearchResultRow({
    required this.result,
    required this.installing,
    required this.onInstall,
  });

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _hover ? AppColors.bg3 : Colors.transparent,
          border: Border(
              bottom: BorderSide(color: AppColors.border1, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r.name,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.fg0)),
                      if (r.version != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.bg0,
                            border:
                                Border.all(color: AppColors.border2, width: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(r.version!,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.fg2)),
                        ),
                      ],
                    ],
                  ),
                  if (r.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(r.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: AppColors.fg3,
                              height: 1.4)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            widget.installing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent))
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onInstall,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CartaIcon(
                                icon: CartaIconData.plus,
                                size: 10,
                                color: AppColors.accentInk),
                            const SizedBox(width: 4),
                            Text('Install',
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentInk)),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Installed row with version dropdown + trash
// ---------------------------------------------------------------------------

class _InstalledRow extends ConsumerWidget {
  final InstalledPackage pkg;
  final VoidCallback onUninstall;

  const _InstalledRow({required this.pkg, required this.onUninstall});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releasesAsync = ref.watch(packageReleasesProvider(pkg.name));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg.name,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fg0)),
                if (pkg.installedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                        'installed ${_shortDate(pkg.installedAt!)}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: AppColors.fg3)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Version dropdown — pulls from Hex releases, defaults to installed.
          releasesAsync.when(
            loading: () => SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.fg2)),
            error: (_, __) => Text(pkg.version,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.fg2)),
            data: (versions) {
              // TODO: changing version should stage an upgrade. For now
              // it's display-only — actual change requires uninstall +
              // reinstall.
              return _VersionDropdown(
                current: pkg.version,
                versions: versions,
              );
            },
          ),
          const SizedBox(width: 10),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onUninstall,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CartaIcon(
                    icon: CartaIconData.trash,
                    size: 13,
                    color: AppColors.fg2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _VersionDropdown extends StatefulWidget {
  final String current;
  final List<String> versions;

  const _VersionDropdown({required this.current, required this.versions});

  @override
  State<_VersionDropdown> createState() => _VersionDropdownState();
}

class _VersionDropdownState extends State<_VersionDropdown> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    // Top 10 newest — Hex lists newest first.
    final list = widget.versions.take(10).toList(growable: true);
    if (!list.contains(_selected)) list.insert(0, _selected);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border.all(color: AppColors.border2, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: _selected,
        items: list
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.fg1)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null && v != _selected) {
            setState(() => _selected = v);
            // No hot stage yet — surface as informational.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Version change for ${widget.current} → $v is staged '
                    'for the next Apply & Restart.',
                    style: const TextStyle(fontFamily: 'monospace')),
                backgroundColor: AppColors.bg4,
              ),
            );
          }
        },
        underline: const SizedBox.shrink(),
        isDense: true,
        style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.fg1),
        dropdownColor: AppColors.bg2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending row (staged install/uninstall awaiting restart)
// ---------------------------------------------------------------------------

class _PendingRow extends StatelessWidget {
  final String name;
  final String version;
  final String? status;
  final String? reason;
  final bool pendingUninstall;

  const _PendingRow({
    required this.name,
    required this.version,
    this.status,
    this.reason,
    this.pendingUninstall = false,
  });

  @override
  Widget build(BuildContext context) {
    final errored = status == 'error';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: errored
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.accent.withValues(alpha: 0.06),
        border: Border.all(
            color: errored
                ? AppColors.danger.withValues(alpha: 0.4)
                : AppColors.accent.withValues(alpha: 0.3),
            width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          CartaIcon(
              icon: pendingUninstall ? CartaIconData.trash : CartaIconData.plus,
              size: 12,
              color: errored ? AppColors.danger : AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.fg0)),
                if (version.isNotEmpty)
                  Text(version,
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          color: AppColors.fg2)),
                if (errored && reason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SelectableText('error: $reason',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: AppColors.danger,
                            height: 1.4)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
