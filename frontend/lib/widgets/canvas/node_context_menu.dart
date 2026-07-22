import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';

class NodeContextMenu extends StatelessWidget {
  final Offset anchor;
  final bool canDuplicate;
  final VoidCallback onDuplicate;
  final VoidCallback onCollapse;
  final VoidCallback onDelete;
  final VoidCallback onInspect;
  final VoidCallback onClose;

  NodeContextMenu({
    super.key,
    required this.anchor,
    this.canDuplicate = true,
    required this.onDuplicate,
    required this.onCollapse,
    required this.onDelete,
    required this.onInspect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: anchor.dx,
          top: anchor.dy + 8,
          child: Container(
            width: 196,
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
                _MenuItem(
                  icon: CartaIconData.settings,
                  label: 'inspect node',
                  desc: 'open node editor',
                  onTap: onInspect,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Container(height: 1, color: AppColors.border1),
                ),
                if (canDuplicate)
                  _MenuItem(
                    icon: CartaIconData.copy,
                    label: 'duplicate',
                    desc: 'clone this node downstream',
                    onTap: onDuplicate,
                  ),
                _MenuItem(
                  icon: CartaIconData.collapseLink,
                  label: 'remove + collapse',
                  desc: 'delete & rewire parent -> child',
                  onTap: onCollapse,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Container(height: 1, color: AppColors.border1),
                ),
                _MenuItem(
                  icon: CartaIconData.x,
                  label: 'delete node',
                  desc: 'removes its connections too',
                  danger: true,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: anchor.dx - 16,
          top: anchor.dy - 16,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.32),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.22),
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ],
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

class _MenuItem extends StatefulWidget {
  final CartaIconData icon;
  final String label;
  final String desc;
  final bool danger;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
    this.danger = false,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hover
                ? (widget.danger
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.bg3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Center(
                  child: CartaIcon(
                    icon: widget.icon,
                    size: 14,
                    color: widget.danger ? AppColors.danger : AppColors.fg2,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.fg0,
                      ),
                    ),
                    Text(
                      widget.desc,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        color: widget.danger
                            ? AppColors.danger.withValues(alpha: 0.7)
                            : AppColors.fg3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
