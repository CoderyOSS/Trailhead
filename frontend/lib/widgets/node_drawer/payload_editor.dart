import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/elixir.dart';
import '../../providers/carta_provider.dart';
import '../../theme/tokens.dart';
import '../icons.dart';

/// Reusable payload editor widget.
///
/// Renders a multiline Elixir code field with server-side syntax validation
/// (debounced 350ms) and an optional Trigger button slot. Used by:
/// - Builder mode (no trigger; saves to YAML via onChanged)
/// - Active mode (trigger button present; sends current text to backend)
class PayloadEditor extends ConsumerStatefulWidget {
  final String initialCode;
  final ValueChanged<String> onChanged;
  final Widget? triggerSlot;

  /// When true, validation runs in expression mode (syntax-only server
  /// check) and the status line reads "expression". The code is evaluated
  /// once at deploy time / per trigger click — never per message.
  final bool isExpr;

  /// Optional: invoked with the latest validity result after each debounced
  /// server validation. Lets callers gate downstream actions (e.g. skip a
  /// save when the pip is invalid). Non-breaking for existing callers.
  final ValueChanged<bool>? onValidationChanged;

  const PayloadEditor({
    super.key,
    required this.initialCode,
    required this.onChanged,
    this.triggerSlot,
    this.isExpr = false,
    this.onValidationChanged,
  });

  @override
  ConsumerState<PayloadEditor> createState() => _PayloadEditorState();
}

class _PayloadEditorState extends ConsumerState<PayloadEditor> {
  late final CodeController _controller;
  Timer? _debounce;
  bool _validating = false;
  bool _isValid = true;
  String? _error;
  int? _errorLine;
  // X-dismissed errors stay hidden until the error changes (new validation
  // result) — dismissing must not permanently suppress the banner while the
  // same stale error persists.
  String? _dismissedError;
  // Last text seen via _onChanged. CodeController fires its listeners on
  // internal state changes (selection, focus, rebuild sync) — not just on
  // text mutations — so without this guard, spurious fires would endlessly
  // reset the parent's save debounce and prevent the PUT from ever firing.
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialCode,
      language: elixir,
    );
    _lastText = widget.initialCode;
    _controller.addListener(_onChanged);
    // Initial validation.
    if (widget.initialCode.trim().isNotEmpty) {
      _scheduleValidation();
    }
  }

  @override
  void didUpdateWidget(covariant PayloadEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mode switch changes the validation semantics — re-run on existing text.
    if (oldWidget.isExpr != widget.isExpr &&
        _controller.text.trim().isNotEmpty) {
      _scheduleValidation();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    final text = _controller.text;
    if (text == _lastText) return;
    _lastText = text;
    widget.onChanged(text);
    _scheduleValidation();
  }

  void _scheduleValidation() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _validate);
  }

  Future<void> _validate() async {
    final code = _controller.text;
    if (code.trim().isEmpty) {
      setState(() {
        _isValid = false;
        _error = 'empty';
        _errorLine = null;
        _validating = false;
      });
      widget.onValidationChanged?.call(false);
      return;
    }

    setState(() => _validating = true);

    try {
      final result = await ref
          .read(cartaApiProvider)
          .validateElixirTerm(code, isExpr: widget.isExpr);
      if (!mounted) return;
      setState(() {
        _isValid = result.ok;
        _error = result.error;
        _errorLine = result.line;
        _validating = false;
      });
      widget.onValidationChanged?.call(result.ok);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isValid = false;
        _error = 'validation failed (network)';
        _validating = false;
      });
      widget.onValidationChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Validation row
        Row(
          children: [
            _ValidationPip(validating: _validating, isValid: _isValid),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isValid
                    ? (widget.isExpr
                        ? 'valid Elixir expression'
                        : 'valid Elixir literal')
                    : 'invalid',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: _isValid ? AppColors.success : AppColors.danger,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_errorLine != null && !_isValid)
              Text(
                'line $_errorLine',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.fg3,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Code editor with floating error banner (excluded from layout flow —
        // the editor must not jump when the error appears/disappears).
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bg0,
                    border: Border.all(
                      color: _isValid ? AppColors.border2 : AppColors.danger,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _controller,
                          textStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                          minLines: 10,
                          maxLines: null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_isValid &&
                  !_validating &&
                  _error != null &&
                  _error != 'empty' &&
                  _error != _dismissedError)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      border: Border(
                        top: BorderSide(color: AppColors.danger, width: 0.5),
                      ),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(7)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CartaIcon(
                            icon: CartaIconData.alertTriangle,
                            size: 12,
                            color: AppColors.danger),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SelectableText(
                                _error!,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  height: 1.4,
                                ),
                              ),
                              // Literal mode rejects anything outside the
                              // whitelist parser — point at expression mode.
                              if (!widget.isExpr)
                                Text(
                                  'literals only — switch to expression mode for calls/operators',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: AppColors.fg3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _dismissedError = _error),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: CartaIcon(
                                  icon: CartaIconData.x,
                                  size: 11,
                                  color: AppColors.fg3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.triggerSlot != null) ...[
          const SizedBox(height: 12),
          widget.triggerSlot!,
        ],
      ],
    );
  }
}

class _ValidationPip extends StatelessWidget {
  final bool validating;
  final bool isValid;

  const _ValidationPip({required this.validating, required this.isValid});

  @override
  Widget build(BuildContext context) {
    final color = validating
        ? AppColors.fg3
        : (isValid ? AppColors.success : AppColors.danger);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
