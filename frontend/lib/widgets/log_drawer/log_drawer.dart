import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/log_provider.dart';
import '../../providers/mode_provider.dart';
import '../../providers/thrt_provider.dart';
import '../../theme/tokens.dart';
import 'log_stream_view.dart';

/// Log drawer. Selection-agnostic: shows all log points where a node has
/// `logging_enabled: true` plus the corresponding runtime dir flag on.
///
/// Left rail lists every available log point with a visibility toggle
/// (client-side filter). Right pane shows the aggregated stream of frames
/// from all toggled-on points, ordered by timestamp.
class LogDrawer extends ConsumerStatefulWidget {
  const LogDrawer({super.key});

  @override
  ConsumerState<LogDrawer> createState() => _LogDrawerState();
}

class _LogDrawerState extends ConsumerState<LogDrawer> {
  @override
  void initState() {
    super.initState();
    // Attach buffer listener to the canvas document's socket (job snapshot
    // in Active mode, live workflow otherwise).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wf = ref.read(canvasWorkflowProvider);
      if (wf.name.isNotEmpty) {
        ref.read(logBufferProvider.notifier).attach(wf.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wf = ref.watch(canvasWorkflowProvider);
    final statuses = ref.watch(flowStatusProvider);
    final deployed = statuses[wf.name]?.deployed ?? false;

    // All candidate log points: nodes with loggingEnabled && (logIn || logOut).
    final points = <String>{};
    for (final n in wf.nodes) {
      if (!n.loggingEnabled) continue;
      if (n.logIn) points.add('${n.id}.in');
      if (n.logOut) points.add('${n.id}.out');
    }

    // Default-enable all points on first render if the provider is empty.
    final enabled = ref.watch(enabledLogPointsProvider);
    if (enabled.isEmpty && points.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(enabledLogPointsProvider.notifier).state = Set.of(points);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DrawerHeader(deployed: deployed),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left rail: log-point toggles
              Container(
                width: 150,
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  border: Border(right: BorderSide(color: AppColors.border1)),
                ),
                child: points.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'no log points — enable logging_enabled on a node',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: AppColors.fg3,
                            height: 1.5,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        children: [
                          for (final p in points.toList()..sort())
                            _PointToggle(key: ValueKey(p), point: p),
                        ],
                      ),
              ),
              // Right: aggregated stream
              const Expanded(child: LogStreamView()),
            ],
          ),
        ),
      ],
    );
  }
}

/// flowStatusProvider lives in thrt_provider; imported above.
class _DrawerHeader extends ConsumerWidget {
  final bool deployed;

  const _DrawerHeader({required this.deployed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border1)),
      ),
      child: Row(
        children: [
          Text(
            'LOG',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: 0.06 * 10,
              color: AppColors.fg3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Clear accumulated frames for the current flow.
          GestureDetector(
            onTap: () {
              final name = ref.read(canvasWorkflowProvider).name;
              if (name.isNotEmpty) {
                ref.read(logBufferProvider.notifier).clear(name);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'clear',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    color: AppColors.fg3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: deployed ? AppColors.success : AppColors.fg3,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            deployed ? 'live' : 'not deployed',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              color: deployed ? AppColors.success : AppColors.fg3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointToggle extends ConsumerWidget {
  final String point;

  const _PointToggle({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(enabledLogPointsProvider);
    final on = enabled.contains(point);
    final parts = point.split('.');
    final dir = parts.last;
    final nodeId = parts.sublist(0, parts.length - 1).join('.');

    return GestureDetector(
      onTap: () {
        final next = Set<String>.of(enabled);
        if (on) {
          next.remove(point);
        } else {
          next.add(point);
        }
        ref.read(enabledLogPointsProvider.notifier).state = next;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AppColors.bg3 : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: on ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: on
                      ? (dir == 'in' ? AppColors.info : AppColors.success)
                      : AppColors.fg3,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  nodeId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: on ? AppColors.fg0 : AppColors.fg3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                dir,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  color: on ? AppColors.fg2 : AppColors.fg3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
