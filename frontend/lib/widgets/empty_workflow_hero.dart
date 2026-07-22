import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_provider.dart';
import '../providers/canvas_controller.dart';
import '../providers/mode_provider.dart';
import '../providers/mock_data.dart' show WorkflowSummary;
import '../theme/tokens.dart';
import '../utils/workflow_to_yaml.dart';
import 'app_button.dart';
import 'icons.dart';

/// Full-canvas hero shown when no workflows exist in the backend.
/// Single CTA: create the first workflow (empty canvas, add nodes via toolbar).
class EmptyWorkflowHero extends ConsumerStatefulWidget {
  EmptyWorkflowHero({super.key});

  @override
  ConsumerState<EmptyWorkflowHero> createState() => _EmptyWorkflowHeroState();
}

class _EmptyWorkflowHeroState extends ConsumerState<EmptyWorkflowHero> {
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(workflowsApiProvider);
      final existing = ref.read(workflowsProvider).map((w) => w.name).toSet();
      var name = 'untitled';
      var i = 2;
      while (existing.contains(name)) {
        name = 'untitled-$i';
        i++;
      }
      final placeholder = WorkflowSummary(
        id: 'wf_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        version: 1,
        updated: 'just now',
        nodes: const [],
      );
      await api.create(name, workflowToYaml(placeholder));
      ref.invalidate(remoteWorkflowsProvider);
      await ref.read(remoteWorkflowsProvider.future);
      final created = ref.read(workflowsProvider).firstWhere(
            (w) => w.name == name,
            orElse: () => placeholder,
          );
      ref.read(workflowProvider.notifier).state = created;
      ref.read(canvasControllerProvider.notifier).reset();
      ref.read(workflowDirtyProvider.notifier).state = false;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                icon: CartaIconData.bot,
                size: 38,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Build your first workflow',
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
              'Workflows are directed graphs of nodes. Add genservers, tasks, functions, and log sinks to compose your pipeline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: AppColors.fg2,
              ),
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            variant: AppButtonVariant.primary,
            size: AppButtonSize.md,
            icon: CartaIconData.plus,
            label: _busy ? 'creating…' : 'Create workflow',
            onTap: _busy ? null : _create,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              'create failed: $_error',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.danger,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
