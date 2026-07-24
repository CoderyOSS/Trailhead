import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/configs_provider.dart';
import '../../services/configs_api.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../node_drawer/payload_editor.dart';

/// Settings section: project-scoped configuration objects (named Elixir
/// literals stored server-side in configs/*.yaml). Each card expands to a
/// PayloadEditor bound to its source. Nodes opt in via config.config_key.
class ConfigsSection extends ConsumerWidget {
  ConfigsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(configsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, ref),
        const SizedBox(height: 14),
        configsAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: AppColors.fg2),
              ),
            ),
          ),
          error: (e, _) =>
              _errorRow('Failed to load configuration objects: $e'),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No configuration objects yet. Click + New to create one, '
                  'then reference it from a node via config.config_key.',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.fg2,
                      height: 1.5),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _subHeader('CONFIGS (${items.length})'),
                ...items.map((c) => _ConfigCard(config: c)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _header(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONFIGURATION OBJECTS',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 0.08 * 11,
                      color: AppColors.fg3,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                'Named Elixir literals stored server-side (configs/*.yaml). '
                'Reference one from a node via config.config_key; its term is '
                "deep-merged over the node's inline config at deploy.",
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.fg2,
                    height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _promptNewKey(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CartaIcon(icon: CartaIconData.plus, size: 11, color: AppColors.accentInk),
                  const SizedBox(width: 5),
                  Text('New',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentInk)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _promptNewKey(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: AppColors.border2)),
        title: Text('New configuration object',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.fg0)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.fg0),
          decoration: InputDecoration(
            hintText: 'key name (e.g. db_settings)',
            hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.fg3),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border2)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(fontFamily: 'monospace', color: AppColors.fg2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text('Create',
                style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (key == null || key.isEmpty) return;
    try {
      await ref.read(configsApiProvider).create(key, '%{}');
      ref.invalidate(configsProvider);
    } on ConfigsApiException catch (e) {
      if (!context.mounted) return;
      _snack(context,
          e.statusCode == 409 ? "Key '$key' already exists." : 'Create failed: $e',
          danger: true);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Create failed: $e', danger: true);
    }
  }

  void _snack(BuildContext context, String msg, {bool danger = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(msg, style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: danger ? AppColors.danger : AppColors.accent,
      ),
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
          style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.danger)),
    );
  }
}

class _ConfigCard extends ConsumerStatefulWidget {
  final ConfigDto config;
  const _ConfigCard({required this.config});

  @override
  ConsumerState<_ConfigCard> createState() => _ConfigCardState();
}

class _ConfigCardState extends ConsumerState<_ConfigCard> {
  bool _expanded = false;
  // Mount the PayloadEditor on first expand, then keep it mounted (hidden via
  // Offstage when collapsed). PayloadEditor binds initialCode in initState
  // only, so a conditional remount would rebind to a possibly-stale
  // cfg.source and clobber the user's edits — keeping state alive preserves
  // the typed text across collapse/re-expand.
  bool _everExpanded = false;

  // Debounce saves: PayloadEditor fires onChanged per keystroke; without a
  // debounce every intermediate (invalid) state would hit the backend and
  // generate a 400 SnackBar, queuing many toasts during rapid typing. The
  // timer collapses rapid edits into a single PUT 1.5s after typing stops.
  Timer? _saveDebounce;

  // Single current error (replaces SnackBar queue). Cleared on next keystroke;
  // replaced (not appended) on each failed PUT.
  String? _localError;

  // Tracks the PayloadEditor's pip validity via onValidationChanged. When
  // false, the save is skipped entirely — saves a backend roundtrip on
  // intermediate invalid states.
  bool _isValid = true;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (_expanded) _everExpanded = true;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: _expanded ? math.pi / 2 : 0.0,
                    child: CartaIcon(icon: CartaIconData.chevRight, size: 12, color: AppColors.fg2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cfg.key,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fg0)),
                  ),
                  if (cfg.updatedAt != null)
                    Text(_shortDate(cfg.updatedAt!),
                        style: TextStyle(
                            fontFamily: 'monospace', fontSize: 10, color: AppColors.fg3)),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _delete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CartaIcon(icon: CartaIconData.trash, size: 13, color: AppColors.fg2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Mount the editor once on first expand, then keep it mounted
          // (Offstage hides it when collapsed). See _everExpanded for why.
          if (_everExpanded)
            Offstage(
              offstage: !_expanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_localError != null) ...[
                      _errorBanner(_localError!),
                      const SizedBox(height: 8),
                    ],
                    PayloadEditor(
                      key: ValueKey('cfg-${cfg.key}'),
                      initialCode: cfg.source,
                      isExpr: false,
                      onChanged: (source) => _scheduleSave(cfg.key, source),
                      onValidationChanged: (ok) => _isValid = ok,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.danger, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CartaIcon(icon: CartaIconData.alertTriangle, size: 12, color: AppColors.danger),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(msg,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.danger,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  // Schedule a debounced save. Any keystroke cancels the pending timer and
  // clears the current error — guarantees only ONE error is shown at a time
  // (never a queue) and a PUT only fires after the user stops typing for
  // 1.5s. Skipped entirely when the pip reports the editor invalid.
  void _scheduleSave(String key, String source) {
    if (_localError != null) {
      setState(() => _localError = null);
    }
    _saveDebounce?.cancel();
    if (source.trim().isEmpty) return;
    _saveDebounce = Timer(const Duration(milliseconds: 1500), () => _save(key, source));
  }

  Future<void> _save(String key, String source) async {
    if (!_isValid) return;
    try {
      await ref.read(configsApiProvider).replace(key, source);
      // Invalidate so the cached FutureProvider refetches the latest source.
      // Without this, reopening settings shows stale source from the cached
      // list — looks like the save never persisted.
      ref.invalidate(configsProvider);
      if (mounted && _localError != null) setState(() => _localError = null);
    } on ConfigsApiException catch (e) {
      if (!mounted) return;
      setState(() => _localError = 'Save failed: $e');
    } catch (e) {
      if (!mounted) return;
      setState(() => _localError = 'Save failed: $e');
    }
  }

  Future<void> _delete() async {
    try {
      await ref.read(configsApiProvider).delete(widget.config.key);
      ref.invalidate(configsProvider);
    } on ConfigsApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: SelectableText('Delete failed: $e',
              style: const TextStyle(fontFamily: 'monospace')),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
