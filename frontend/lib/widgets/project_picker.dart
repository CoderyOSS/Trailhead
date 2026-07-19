import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mode_provider.dart';
import '../providers/thrt_provider.dart';
import '../theme/tokens.dart';

/// Dropdown binding the active workflow to a THRT project directory.
/// Options: "no project" (runtime default), the runtime's current project,
/// and every registered project. Selection writes `project:` into the
/// workflow YAML via workflowProvider (autosave persists it).
class ProjectPicker extends ConsumerWidget {
  const ProjectPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final workflow = ref.watch(workflowProvider);

    return projectsAsync.maybeWhen(
      data: (projects) {
        final dirs = projects.dirs;
        final current = workflow.project;

        return DropdownButton<String?>(
          value: current != null && dirs.contains(current) ? current : null,
          hint: Text(
            'no project',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.fg2,
            ),
          ),
          underline: const SizedBox.shrink(),
          isDense: true,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: AppColors.fg0,
          ),
          dropdownColor: AppColors.bg1,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'no project',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.fg2,
                ),
              ),
            ),
            for (final dir in dirs)
              DropdownMenuItem<String?>(
                value: dir,
                child: Text(dir, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (dir) {
            ref.read(workflowProvider.notifier).state =
                workflow.copyWith(project: dir);
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
