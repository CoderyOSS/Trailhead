import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/log_socket.dart';
import 'carta_provider.dart';

/// A single log point: node + direction.
class LogPoint {
  final String nodeId;
  final String dir; // 'in' or 'out'

  const LogPoint({required this.nodeId, required this.dir});

  @override
  bool operator ==(Object other) =>
      other is LogPoint && other.nodeId == nodeId && other.dir == dir;

  @override
  int get hashCode => Object.hash(nodeId, dir);

  @override
  String toString() => '$nodeId.$dir';
}

/// One socket per active flow. Auto-connects when the flow becomes deployed;
/// disconnects when undeployed.
class LogSocketNotifier extends StateNotifier<LogSocket?> {
  final Ref _ref;
  final Map<String, LogSocket> _sockets = {};

  LogSocketNotifier(this._ref) : super(null);

  /// Returns the socket for `flowName`, creating + connecting on demand.
  LogSocket forFlow(String flowName) {
    final existing = _sockets[flowName];
    if (existing != null) return existing;

    final api = _ref.read(cartaApiProvider);
    final url = api.logsStreamUrl(flowName);
    final socket = LogSocket(url: url);
    socket.connect();
    _sockets[flowName] = socket;
    return socket;
  }

  void disconnect(String flowName) {
    final s = _sockets.remove(flowName);
    s?.dispose();
  }

  @override
  void dispose() {
    for (final s in _sockets.values) {
      s.dispose();
    }
    _sockets.clear();
    super.dispose();
  }
}

final logSocketProvider =
    StateNotifierProvider<LogSocketNotifier, LogSocket?>((ref) {
  return LogSocketNotifier(ref);
});

/// Per-flow ring buffer of frames. Capped at 200 entries per point; older
/// evicted FIFO.
class LogBuffer {
  final List<LogFrame> _frames = [];
  final int cap;

  LogBuffer({this.cap = 200});

  void add(LogFrame f) {
    _frames.add(f);
    if (_frames.length > cap) {
      _frames.removeRange(0, _frames.length - cap);
    }
  }

  List<LogFrame> snapshot() => List.unmodifiable(_frames);

  void clear() => _frames.clear();
}

/// Per-flow frame store. Subscribes to the flow's LogSocket and routes frames
/// into a single ordered buffer (merged across all enabled log points).
class LogBufferNotifier extends StateNotifier<Map<String, LogBuffer>> {
  final Ref _ref;
  StreamSubscription<LogFrame>? _sub;
  String? _activeFlow;

  LogBufferNotifier(this._ref) : super({});

  /// Begin listening to frames for `flowName`. Replaces any prior subscription.
  void attach(String flowName) {
    if (_activeFlow == flowName) return;
    _sub?.cancel();

    _activeFlow = flowName;
    state.putIfAbsent(flowName, () => LogBuffer());

    final socket = _ref.read(logSocketProvider.notifier).forFlow(flowName);
    _sub = socket.frames.listen((f) {
      final buf = state[flowName] ?? LogBuffer();
      buf.add(f);
      // Trigger rebuild by replacing map entry.
      state = {...state, flowName: buf};
    });
  }

  /// Detach from the current flow (does NOT clear accumulated frames — caller
  /// may want them after switching back).
  void detach() {
    _sub?.cancel();
    _sub = null;
    _activeFlow = null;
  }

  List<LogFrame> framesFor(String flowName) =>
      state[flowName]?.snapshot() ?? const [];

  void clear(String flowName) {
    state[flowName]?.clear();
    state = {...state};
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final logBufferProvider =
    StateNotifierProvider<LogBufferNotifier, Map<String, LogBuffer>>((ref) {
  return LogBufferNotifier(ref);
});
