import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'icons.dart';

enum AppButtonVariant { primary, trail, secondary, ghost, danger }

enum AppButtonSize { sm, md }

class AppButton extends StatefulWidget {
  final AppButtonVariant variant;
  final AppButtonSize size;
  final String? label;
  final CartaIconData? icon;
  final VoidCallback? onTap;

  AppButton({
    super.key,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.md,
    this.label,
    this.icon,
    this.onTap,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovering = false;

  double get _height => widget.size == AppButtonSize.sm ? 26 : 32;
  double get _fontSize => widget.size == AppButtonSize.sm ? 12 : 13;
  double get _iconSize => widget.size == AppButtonSize.sm ? 12 : 14;
  EdgeInsets get _padding =>
      widget.size == AppButtonSize.sm
          ? const EdgeInsets.symmetric(horizontal: 8)
          : const EdgeInsets.symmetric(horizontal: 12);

  Color get _bg {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.accent;
      case AppButtonVariant.trail:
        return const Color(0xFF8b6914);
      case AppButtonVariant.secondary:
        return _hovering ? AppColors.bg4 : AppColors.bg3;
      case AppButtonVariant.ghost:
        return _hovering ? AppColors.bg3 : Colors.transparent;
      case AppButtonVariant.danger:
        return _hovering ? AppColors.danger.withValues(alpha: 0.15) : Colors.transparent;
    }
  }

  Color get _fg {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.accentInk;
      case AppButtonVariant.trail:
        return const Color(0xFFfbf3e6);
      case AppButtonVariant.secondary:
        return AppColors.fg0;
      case AppButtonVariant.ghost:
        return AppColors.fg1;
      case AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color get _border {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.trail:
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.secondary:
        return AppColors.border2;
      case AppButtonVariant.danger:
        return AppColors.danger.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: _height,
          padding: _padding,
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                CartaIcon(
                  icon: widget.icon!,
                  size: _iconSize,
                  color: _fg,
                ),
                if (widget.label != null) const SizedBox(width: 6),
              ],
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    color: _fg,
                    height: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
