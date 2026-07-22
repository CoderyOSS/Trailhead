import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/carta_provider.dart';
import '../theme/tokens.dart';

/// Error banner listing Carta validation problems for the active workflow.
/// Hidden when the workflow is valid. Shown above the canvas in build mode
/// and inside the YAML drawer.
class ValidationBanner extends ConsumerWidget {
  const ValidationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(validationErrorsProvider);
    if (errors.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'workflow validation failed — deploy will be rejected',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final e in errors)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                e,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.fg0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
