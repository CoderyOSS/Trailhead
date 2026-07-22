import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';

/// Connected Carta instance identity: which project is open, where Carta is
/// installed from, and the runtime mode. Read-only — local-install mode fixes
/// the project dir at boot, so there is nothing to edit here.
class InstanceSection extends ConsumerWidget {
  const InstanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectInfoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          'INSTANCE',
          'The Carta runtime this frontend is talking to. Local installs fix '
          'the project at boot (cwd) — one instance, one project.',
        ),
        const SizedBox(height: 14),
        projectAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.fg2))),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SelectableText('Failed to load instance info: $e',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.danger)),
          ),
          data: (project) => Container(
            decoration: BoxDecoration(
              color: AppColors.bg2,
              border: Border.all(color: AppColors.border1, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Mode',
                  value: project.mode,
                  icon: CartaIconData.zap,
                ),
                _InfoRow(
                  label: 'Project dir',
                  value: project.dir,
                  icon: CartaIconData.file,
                ),
                _InfoRow(
                  label: 'Carta source',
                  value: project.cartaSource ?? '—',
                  icon: CartaIconData.gitBranch,
                ),
                _InfoRow(
                  label: 'Install dir',
                  value: project.installDir,
                  icon: CartaIconData.plug,
                  last: true,
                ),
              ],
            ),
          ),
        ),
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final CartaIconData icon;
  final bool last;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : BorderSide(color: AppColors.border1, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          CartaIcon(icon: icon, size: 12, color: AppColors.fg2),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fg2)),
          ),
          Expanded(
            child: SelectableText(value,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.fg0)),
          ),
        ],
      ),
    );
  }
}
