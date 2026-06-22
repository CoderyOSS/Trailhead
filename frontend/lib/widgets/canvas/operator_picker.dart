import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';

class OperatorPicker extends StatelessWidget {
  final Offset anchor;
  final void Function(OperatorType type) onSelect;
  final VoidCallback onClose;

  OperatorPicker({
    super.key,
    required this.anchor,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // scrim
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        // picker
        Positioned(
          left: anchor.dx,
          top: anchor.dy + 14,
          child: Transform.translate(
            offset: const Offset(-120, 0),
            child: Container(
              width: 240,
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
                  // header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ADD NEXT STAGE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            letterSpacing: 0.08 * 10,
                            color: AppColors.fg3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Padding(
                            padding: EdgeInsets.all(4),
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
                  Divider(height: 1, color: AppColors.border1),
                  // list
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: OperatorType.values.map((type) {
                        return _OperatorRow(
                          type: type,
                          onTap: () => onSelect(type),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum OperatorType {
  worker(kind: 'worker', label: 'worker', desc: 'skills \u00b7 prompt \u00b7 result', icon: TrailheadIconData.zap),
  branch(kind: 'branch', label: 'branch', desc: 'conditional routing', icon: TrailheadIconData.gitBranch),
  fan(kind: 'fan', label: 'fan', desc: 'fan-out a list, fan-in results', icon: TrailheadIconData.forEach);

  const OperatorType({
    required this.kind,
    required this.label,
    required this.desc,
    required this.icon,
  });

  /// Internal kind string used in [WorkflowNode.kind].
  final String kind;
  final String label;
  final String desc;
  final TrailheadIconData icon;
}

class _OperatorRow extends StatefulWidget {
  final OperatorType type;
  final VoidCallback onTap;

  _OperatorRow({required this.type, required this.onTap});

  @override
  State<_OperatorRow> createState() => _OperatorRowState();
}

class _OperatorRowState extends State<_OperatorRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isWorker = widget.type == OperatorType.worker;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  color: isWorker
                      ? AppColors.accent.withValues(alpha: 0.14)
                      : AppColors.bg3,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: TrailheadIcon(
                    icon: widget.type.icon,
                    size: 11,
                    color: isWorker ? AppColors.accent : AppColors.fg2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type.label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: AppColors.fg0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.type.desc,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.fg3,
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
