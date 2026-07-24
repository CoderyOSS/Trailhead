import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_state.dart';
import '../providers/mode_provider.dart';
import '../theme/tokens.dart';
import 'icons.dart';

/// Full-canvas empty state shown in Active mode when no job is selected.
///
/// Two variants, derived from [jobsProvider]:
///  - no running jobs exist   → "No active jobs"
///  - running jobs exist but
///    none is selected         → "No job selected"
///
/// Text-only (no CTA buttons). Reads [AppColors], so the ctor and all
/// instantiations must stay non-const (see the theme-reactivity rule in
/// tokens.dart).
class EmptyActiveJobHero extends ConsumerWidget {
  EmptyActiveJobHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobsProvider);
    final hasRunning = jobsAsync.maybeWhen(
      data: (list) =>
          list.any((j) => j.jobState == JobState.running),
      orElse: () => false,
    );

    final title = hasRunning ? 'No job selected' : 'No active jobs';
    final body = hasRunning
        ? 'Select a job from the dropdown above to view its graph.'
        : 'There are no running jobs to show. Launch one from Build mode.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.crustGradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border2),
            ),
            child: Center(
              child: CartaIcon(
                icon: CartaIconData.stopwatch,
                size: 38,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.fg0,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: AppColors.fg2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
