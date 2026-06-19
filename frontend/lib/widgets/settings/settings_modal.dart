import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import 'package:flutter/material.dart' as m;

// ---------------------------------------------------------------------------
// Intents
// ---------------------------------------------------------------------------

class _CloseIntent extends Intent {
  const _CloseIntent();
}

// ---------------------------------------------------------------------------
// Section metadata
// ---------------------------------------------------------------------------

class _SectionMeta {
  final String value;
  final String label;
  final TrailheadIconData icon;

  const _SectionMeta({
    required this.value,
    required this.label,
    required this.icon,
  });
}

const _sections = [
  _SectionMeta(value: 'appearance', label: 'Appearance', icon: TrailheadIconData.sun),
  _SectionMeta(value: 'canvas',     label: 'Canvas',     icon: TrailheadIconData.layout),
  _SectionMeta(value: 'workflow',   label: 'Workflow',   icon: TrailheadIconData.workflow),
  _SectionMeta(value: 'messaging',  label: 'Messaging',  icon: TrailheadIconData.send),
  _SectionMeta(value: 'plugins',    label: 'Plugins',    icon: TrailheadIconData.plug),
];

// ---------------------------------------------------------------------------
// Overlay
// ---------------------------------------------------------------------------

class SettingsModalOverlay extends ConsumerWidget {
  const SettingsModalOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(settingsModalOpenProvider);
    if (!open) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => ref.read(settingsModalOpenProvider.notifier).state = false,
            child: Container(
              color: AppColors.bg0.withValues(alpha: 0.62),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),
        Center(
          child: SettingsDialog(
            onClose: () => ref.read(settingsModalOpenProvider.notifier).state = false,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

class SettingsDialog extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const SettingsDialog({super.key, required this.onClose});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog>
    with SingleTickerProviderStateMixin {
  String section = 'appearance';
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).orientation == Orientation.portrait;

    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.escape): const _CloseIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _CloseIntent: CallbackAction<_CloseIntent>(
              onInvoke: (_) {
                widget.onClose();
                return null;
              },
            ),
          },
          child: FadeTransition(
            opacity: _ctrl,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 720,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 48,
                  maxHeight: MediaQuery.of(context).size.height * 0.86,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bg1,
                  border: Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: [
                      _buildHeader(),
                      if (compact) _buildCompactNav(),
                      Expanded(child: _buildBody(compact)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              border: Border.all(color: AppColors.border2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: TrailheadIcon(
                icon: TrailheadIconData.settings,
                color: AppColors.accent,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fg0,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'preferences · saved locally',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: AppColors.fg2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: TrailheadIcon(
                  icon: TrailheadIconData.x,
                  size: 14,
                  color: AppColors.fg2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg0,
        border: Border(
          bottom: BorderSide(color: AppColors.border1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _sections.map((s) {
            final on = s.value == section;
            return GestureDetector(
              onTap: () => setState(() => section = s.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: on ? AppColors.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TrailheadIcon(
                      icon: s.icon,
                      size: 14,
                      color: on ? AppColors.accent : AppColors.fg2,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on ? AppColors.fg0 : AppColors.fg2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(bool compact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Container(
            width: 178,
            decoration: const BoxDecoration(
              color: AppColors.bg0,
              border: Border(
                right: BorderSide(color: AppColors.border1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _sections.map((s) {
                  final on = s.value == section;
                  return GestureDetector(
                    onTap: () => setState(() => section = s.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: on ? AppColors.bg3 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          TrailheadIcon(
                            icon: s.icon,
                            size: 15,
                            color: on ? AppColors.accent : AppColors.fg2,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            s.label,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                              color: on ? AppColors.fg0 : AppColors.fg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
            child: _buildSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection() {
    switch (section) {
      case 'appearance':
        return const AppearanceSection();
      case 'canvas':
        return const CanvasSection();
      case 'workflow':
        return const WorkflowSection();
      case 'messaging':
        return const MessagingSection();
      case 'plugins':
        return const PluginsSection();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------------

class SettingRow extends StatelessWidget {
  final String title;
  final String? desc;
  final Widget control;
  final bool stacked;
  final bool last;

  const SettingRow({
    super.key,
    required this.title,
    this.desc,
    required this.control,
    this.stacked = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: last ? BorderSide.none : const BorderSide(color: AppColors.border1),
        ),
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(),
                const SizedBox(height: 12),
                control,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: _buildLabel(),
                  ),
                ),
                const SizedBox(width: 20),
                control,
              ],
            ),
    );
  }

  Widget _buildLabel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.fg0,
          ),
        ),
        if (desc != null) ...[
          const SizedBox(height: 3),
          Text(
            desc!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.fg2,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class SegOption {
  final String value;
  final String label;
  final Widget? glyph;

  const SegOption({
    required this.value,
    required this.label,
    this.glyph,
  });
}

class Seg extends StatelessWidget {
  final String value;
  final List<SegOption> options;
  final ValueChanged<String> onChange;

  Seg({
    super.key,
    required this.value,
    required this.options,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final active = o.value == value;
          return GestureDetector(
            onTap: () => onChange(o.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (o.glyph != null) ...[
                    o.glyph!,
                    const SizedBox(width: 6),
                  ],
                  Text(
                    o.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.accentInk : AppColors.fg2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class Toggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChange;

  Toggle({
    super.key,
    required this.on,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!on),
      child: Container(
        width: 40,
        height: 23,
        decoration: BoxDecoration(
          color: on ? AppColors.accent : AppColors.bg4,
          borderRadius: BorderRadius.circular(999),
          border: on ? null : Border.all(color: AppColors.border2),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 2,
              left: on ? 19 : 2,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: on ? AppColors.accentInk : AppColors.fg2,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChange;
  final String? placeholder;
  final bool mono;

  TextField({
    super.key,
    this.value,
    required this.onChange,
    this.placeholder,
    this.mono = false,
  });

  @override
  State<TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void didUpdateWidget(TextField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg3,
        border: Border.all(
          color: _hasFocus ? AppColors.accent : AppColors.border2,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: m.TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: TextStyle(
          fontFamily: widget.mono ? 'monospace' : null,
          fontSize: 12.5,
          color: AppColors.fg0,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            fontFamily: widget.mono ? 'monospace' : null,
            fontSize: 12.5,
            color: AppColors.fg3,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: widget.onChange,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme / accent data
// ---------------------------------------------------------------------------

class _ThemeData {
  final String value;
  final String name;
  final String desc;
  final String mode;
  final List<Color> swatch;

  const _ThemeData({
    required this.value,
    required this.name,
    required this.desc,
    required this.mode,
    required this.swatch,
  });
}

class _AccentData {
  final String value;
  final String name;
  final Gradient gradient;

  const _AccentData({
    required this.value,
    required this.name,
    required this.gradient,
  });
}

const _themes = [
  _ThemeData(
    value: 'hearth',
    name: 'Hearth',
    desc: 'Warm cocoa — the original.',
    mode: 'dark',
    swatch: [Color(0xFF160d07), Color(0xFF281a10), Color(0xFF422c1a), Color(0xFFe8923a)],
  ),
  _ThemeData(
    value: 'slate',
    name: 'Slate',
    desc: 'Neutral, near-black greys.',
    mode: 'dark',
    swatch: [Color(0xFF0c0d10), Color(0xFF1a1d23), Color(0xFF2b303a), Color(0xFF6ea8d9)],
  ),
  _ThemeData(
    value: 'trailhead',
    name: 'Trailhead',
    desc: 'Deep forest, mossy canvas.',
    mode: 'dark',
    swatch: [Color(0xFF0a120c), Color(0xFF142319), Color(0xFF253a2c), Color(0xFFa4c97a)],
  ),
  _ThemeData(
    value: 'paper',
    name: 'Paper',
    desc: 'Light mode, ink on cream.',
    mode: 'light',
    swatch: [Color(0xFFf5f2ec), Color(0xFFe8e3d6), Color(0xFFc9c2ad), Color(0xFFb86a1a)],
  ),
];

const _accents = [
  _AccentData(
    value: 'orange',
    name: 'Orange',
    gradient: LinearGradient(colors: [Color(0xFFf4a955), Color(0xFFe8923a), Color(0xFFc66e1f)]),
  ),
  _AccentData(
    value: 'green',
    name: 'Green',
    gradient: LinearGradient(colors: [Color(0xFFc4d49a), Color(0xFF7a8d4a), Color(0xFF5e7340)]),
  ),
];

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingRow(
          title: 'Color theme',
          desc: 'Applies across the whole app. More palettes can be added to the theme registry.',
          stacked: true,
          control: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ThemeCard(
                      theme: _themes[0],
                      selected: state.theme == _themes[0].value,
                      onTap: () => ref.read(settingsProvider.notifier).setTweak('theme', _themes[0].value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeCard(
                      theme: _themes[1],
                      selected: state.theme == _themes[1].value,
                      onTap: () => ref.read(settingsProvider.notifier).setTweak('theme', _themes[1].value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ThemeCard(
                      theme: _themes[2],
                      selected: state.theme == _themes[2].value,
                      onTap: () => ref.read(settingsProvider.notifier).setTweak('theme', _themes[2].value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeCard(
                      theme: _themes[3],
                      selected: state.theme == _themes[3].value,
                      onTap: () => ref.read(settingsProvider.notifier).setTweak('theme', _themes[3].value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SettingRow(
          title: 'Accent color',
          desc: 'The active / selected highlight used throughout the UI.',
          control: Row(
            children: [
              _AccentChip(
                accent: _accents[0],
                selected: state.accent == _accents[0].value,
                onTap: () => ref.read(settingsProvider.notifier).setTweak('accent', _accents[0].value),
              ),
              const SizedBox(width: 10),
              _AccentChip(
                accent: _accents[1],
                selected: state.accent == _accents[1].value,
                onTap: () => ref.read(settingsProvider.notifier).setTweak('accent', _accents[1].value),
              ),
            ],
          ),
        ),
        SettingRow(
          title: 'Interface density',
          desc: 'Spacing and node size on the canvas.',
          last: true,
          control: Seg(
            value: state.density,
            options: const [
              SegOption(value: 'comfortable', label: 'Comfortable'),
              SegOption(value: 'compact', label: 'Compact'),
            ],
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('density', v),
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final _ThemeData theme;
  final bool selected;
  final VoidCallback onTap;

  _ThemeCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.border1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Row(
                  children: [
                    Expanded(child: Container(color: theme.swatch[0])),
                    Expanded(child: Container(color: theme.swatch[1])),
                    Expanded(child: Container(color: theme.swatch[2])),
                    Container(width: 26, color: theme.swatch[3]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            theme.name,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.fg0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.bg3,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              theme.mode,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                letterSpacing: 0.36,
                                color: AppColors.fg2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme.desc,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.fg2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: TrailheadIcon(
                        icon: TrailheadIconData.check,
                        size: 11,
                        color: AppColors.accentInk,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  final _AccentData accent;
  final bool selected;
  final VoidCallback onTap;

  _AccentChip({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border1,
          ),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: accent.gradient,
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              accent.name,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.fg0 : AppColors.fg2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CanvasSection extends ConsumerWidget {
  const CanvasSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingRow(
          title: 'Default canvas layout',
          desc: 'How workflows are arranged when you open them. Graph routes freely; tree stacks top-down by dependency.',
          stacked: true,
          control: Seg(
            value: state.canvasStyle,
            options: const [
              SegOption(value: 'graph', label: 'Graph'),
              SegOption(value: 'tree', label: 'Tree'),
            ],
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('canvasStyle', v),
          ),
        ),
        SettingRow(
          title: 'Edge style',
          desc: 'How connections are drawn between stages.',
          last: true,
          control: Seg(
            value: state.edgeStyle,
            options: const [
              SegOption(value: 'curved', label: 'Curved'),
              SegOption(value: 'orthogonal', label: 'Ortho'),
              SegOption(value: 'straight', label: 'Straight'),
            ],
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('edgeStyle', v),
          ),
        ),
      ],
    );
  }
}

class WorkflowSection extends ConsumerWidget {
  const WorkflowSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingRow(
          title: 'Worker runner',
          desc: 'Where agent jobs execute. Localhost runs in-process; the others schedule containers on a backend.',
          stacked: true,
          control: Seg(
            value: state.workerRunner,
            options: const [
              SegOption(value: 'localhost', label: 'Localhost'),
              SegOption(value: 'docker', label: 'Docker'),
              SegOption(value: 'swarm', label: 'Swarm'),
              SegOption(value: 'k3s', label: 'K3s'),
            ],
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('workerRunner', v),
          ),
        ),
        SettingRow(
          title: 'Open on launch',
          desc: 'Which mode the app starts in. Takes effect next time you load.',
          control: Seg(
            value: state.defaultMode,
            options: const [
              SegOption(value: 'build', label: 'Build'),
              SegOption(value: 'active', label: 'Active'),
              SegOption(value: 'history', label: 'History'),
            ],
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('defaultMode', v),
          ),
        ),
        SettingRow(
          title: 'Confirm before stopping a run',
          desc: 'Ask for confirmation before cancelling an in-flight job.',
          control: Toggle(
            on: state.confirmStop,
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('confirmStop', v),
          ),
        ),
        SettingRow(
          title: 'Notify when a run finishes',
          desc: 'Post a toast when a job lands as passed or failed.',
          last: true,
          control: Toggle(
            on: state.notifyFinish,
            onChange: (v) => ref.read(settingsProvider.notifier).setTweak('notifyFinish', v),
          ),
        ),
      ],
    );
  }
}

class MessagingSection extends ConsumerWidget {
  const MessagingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final on = state.telegramEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.bg3,
                      border: Border.all(color: AppColors.border2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: TrailheadIcon(
                        icon: TrailheadIconData.send,
                        size: 17,
                        color: on ? AppColors.accent : AppColors.fg2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Telegram',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.fg0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: on ? AppColors.accent.withValues(alpha: 0.18) : AppColors.bg3,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                on ? 'connected' : 'off',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  letterSpacing: 0.36,
                                  color: on ? AppColors.accent : AppColors.fg2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Send run notifications to a Telegram chat through a bot.',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.fg2,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Toggle(
                    on: on,
                    onChange: (v) => ref.read(settingsProvider.notifier).setTweak('telegramEnabled', v),
                  ),
                ],
              ),
              if (on) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Bot token'),
                      const SizedBox(height: 5),
                      TextField(
                        value: state.telegramToken,
                        placeholder: '123456789:ABCdef…',
                        mono: true,
                        onChange: (v) => ref.read(settingsProvider.notifier).setTweak('telegramToken', v),
                      ),
                      const SizedBox(height: 10),
                      _FieldLabel('Chat ID'),
                      const SizedBox(height: 5),
                      TextField(
                        value: state.telegramChat,
                        placeholder: '@your_channel or -100…',
                        mono: true,
                        onChange: (v) => ref.read(settingsProvider.notifier).setTweak('telegramChat', v),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'More channels can be added to the messaging registry as they ship.',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11.5,
            color: AppColors.fg2,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: AppColors.fg2,
      ),
    );
  }
}

class PluginsSection extends ConsumerWidget {
  const PluginsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                border: Border.all(color: AppColors.border2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: TrailheadIcon(
                  icon: TrailheadIconData.plug,
                  size: 22,
                  color: AppColors.fg2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No plugins installed',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.fg0,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Extend Trailhead with custom stages, reviewers, and integrations.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: AppColors.fg2,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg0,
                border: Border.all(color: AppColors.border1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'trailhead plugin add <name>',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.fg1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
