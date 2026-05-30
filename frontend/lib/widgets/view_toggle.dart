import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ViewToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChange;

  const ViewToggle({
    super.key,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Item(
            label: 'grouped',
            active: value == 'grouped',
            onTap: () => onChange('grouped'),
          ),
          _Item(
            label: 'flat',
            active: value == 'flat',
            onTap: () => onChange('flat'),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Item({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.bg4
                : (_hovering ? AppColors.bg3 : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
              color: widget.active ? AppColors.fg0 : AppColors.fg2,
            ),
          ),
        ),
      ),
    );
  }
}
