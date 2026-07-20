import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/elixir.dart';
import '../../providers/thrt_provider.dart';
import '../../theme/tokens.dart';

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

  const PayloadEditor({
    super.key,
    required this.initialCode,
    required this.onChanged,
    this.triggerSlot,
    this.isExpr = false,
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

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialCode,
      language: elixir,
    );
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
    widget.onChanged(_controller.text);
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
      return;
    }

    setState(() => _validating = true);

    try {
      final result = await ref
          .read(thrtApiProvider)
          .validateElixirTerm(code, isExpr: widget.isExpr);
      if (!mounted) return;
      setState(() {
        _isValid = result.ok;
        _error = result.error;
        _errorLine = result.line;
        _validating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isValid = false;
        _error = 'validation failed (network)';
        _validating = false;
      });
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
                    : (_error ?? 'invalid'),
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
        // Literal mode rejects anything outside the whitelist parser — point
        // users at expression mode instead of leaving a bare "invalid".
        if (!widget.isExpr && !_isValid && !_validating)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'literals only — switch to expression mode for calls/operators',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.fg3,
              ),
            ),
          ),
        const SizedBox(height: 8),
        // Code editor
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.bg0,
            border: Border.all(
              color: _isValid ? AppColors.border2 : AppColors.danger,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
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
