import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/tokens.dart';
import '../providers/mode_provider.dart';
import '../providers/settings_provider.dart';
import 'icons.dart';

enum AppMode { build, active, history }

class ModeRail extends ConsumerWidget {
  final int activeCount;

  ModeRail({
    super.key,
    this.activeCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);

    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: AppColors.bg0,
        border: Border(
          right: BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: Column(
        children: [
          _BrandGlyph(),
          const SizedBox(height: 8),
          _RailButton(
            icon: TrailheadIconData.pencil,
            label: 'Build \u00b7 workflows',
            active: mode == AppMode.build,
            onTap: () => ref.read(modeProvider.notifier).state = AppMode.build,
          ),
          _RailButton(
            icon: TrailheadIconData.stopwatch,
            label: 'Active \u00b7 running jobs',
            active: mode == AppMode.active,
            badge: activeCount,
            onTap: () {
              ref.read(stageDrawerOpenProvider.notifier).state = false;
              ref.read(selectedStageIdProvider.notifier).state = null;
              ref.read(modeProvider.notifier).state = AppMode.active;
            },
          ),
          _RailButton(
            icon: TrailheadIconData.list,
            label: 'History \u00b7 past jobs',
            active: mode == AppMode.history,
            onTap: () {
              ref.read(stageDrawerOpenProvider.notifier).state = false;
              ref.read(selectedStageIdProvider.notifier).state = null;
              ref.read(modeProvider.notifier).state = AppMode.history;
            },
          ),
          const Spacer(),
          _RailButton(
            icon: TrailheadIconData.terminal,
            label: 'CLI \u00b7 tokens',
            onTap: () {},
          ),
          _RailButton(
            icon: TrailheadIconData.settings,
            label: 'Settings',
            onTap: () => ref.read(settingsModalOpenProvider.notifier).state = true,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFa4b475), Color(0xFF455429)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'jb',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fg0,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border1, width: 1),
        ),
      ),
      child: SvgPicture.asset(
        'assets/images/trailhead-logo.svg',
        width: 32,
        height: 32,
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  final TrailheadIconData icon;
  final String label;
  final bool active;
  final int? badge;
  final VoidCallback onTap;

  _RailButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.badge,
    required this.onTap,
  });

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton> {
  bool _hovering = false;

  Color get _bg {
    if (widget.active) return AppColors.bg4;
    if (_hovering) return AppColors.bg3;
    return Colors.transparent;
  }

  Color get _fg {
    if (widget.active) return AppColors.accent;
    if (_hovering) return AppColors.fg0;
    return AppColors.fg2;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          verticalOffset: 0,
          decoration: BoxDecoration(
            color: AppColors.bg4,
            border: Border.all(color: AppColors.border2),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          textStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.fg0,
          ),
          child: SizedBox(
            width: 52,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.active)
                  Positioned(
                    left: 0,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: TrailheadIcon(
                    icon: widget.icon,
                    size: 16,
                    color: _fg,
                  ),
                ),
                if (widget.badge != null && widget.badge! > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14),
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: widget.active
                            ? AppColors.accent
                            : AppColors.bg5,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.badge}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: widget.active
                              ? AppColors.accentInk
                              : AppColors.fg0,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
