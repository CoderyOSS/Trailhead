import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/log_provider.dart';
import '../../providers/mode_provider.dart';
import '../../services/log_socket.dart';
import '../../theme/tokens.dart';

/// Aggregated log stream. Merges frames from all enabled log points into a
/// single timestamp-ordered view. Auto-scrolls to the latest frame.
class LogStreamView extends ConsumerStatefulWidget {
  const LogStreamView({super.key});

  @override
  ConsumerState<LogStreamView> createState() => _LogStreamViewState();
}

class _LogStreamViewState extends ConsumerState<LogStreamView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wf = ref.watch(workflowProvider);
    final buffers = ref.watch(logBufferProvider);
    final enabled = ref.watch(enabledLogPointsProvider);

    final all = buffers[wf.name]?.snapshot() ?? const <LogFrame>[];
    final frames = all
        .where((f) => enabled.contains('${f.nodeId}.${f.dir}'))
        .toList()
      ..sort((a, b) {
        final byTs = a.ts.compareTo(b.ts);
        if (byTs != 0) return byTs;
        // Monotonic seq tie-breaks frames in the same millisecond (server
        // emits it; null = older server without seq — keep arrival order).
        if (a.seq != null && b.seq != null) return a.seq!.compareTo(b.seq!);
        return 0;
      });

    // Auto-scroll when frame count changes.
    _scrollToEnd();

    if (frames.isEmpty) {
      return Center(
        child: Text(
          'no log frames yet',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.fg3,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: frames.length,
      itemBuilder: (context, i) => _FrameLine(frame: frames[i]),
    );
  }
}

class _FrameLine extends StatelessWidget {
  final LogFrame frame;

  const _FrameLine({required this.frame});

  String _fmtTs(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    final mmm = dt.millisecond.toString().padLeft(3, '0');
    return '$hh:$mm:$ss.$mmm';
  }

  @override
  Widget build(BuildContext context) {
    final isIn = frame.dir == 'in';
    final dirColor = isIn ? AppColors.info : AppColors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _fmtTs(frame.ts),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: AppColors.fg3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: dirColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isIn ? 'in' : 'out',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: dirColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  frame.nodeId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.fg2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 2),
            child: Text(
              frame.payload,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: AppColors.fg0,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
