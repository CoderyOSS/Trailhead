import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class LogFrame {
  final String nodeId;
  final String dir; // "in" or "out"
  final int ts;
  final int? seq; // monotonic tie-breaker when two frames share a millisecond
  final String payload;

  const LogFrame({
    required this.nodeId,
    required this.dir,
    required this.ts,
    this.seq,
    required this.payload,
  });

  factory LogFrame.fromJson(Map<String, dynamic> json) {
    return LogFrame(
      nodeId: json['node_id'] as String,
      dir: json['dir'] as String,
      ts: (json['ts'] as num).toInt(),
      seq: (json['seq'] as num?)?.toInt(),
      payload: json['payload'] as String,
    );
  }
}

enum LogSocketState { disconnected, connecting, connected, error }

/// Manages a single WebSocket connection to `/api/v1/workflows/:name/logs/stream`.
///
/// Frames are decoded into [LogFrame]s and pushed through [frames]. Reconnects
/// with exponential backoff on disconnect (1s, 2s, 5s, 10s cap).
class LogSocket {
  final String url;
  final Duration pingInterval;

  WebSocketChannel? _channel;
  StreamController<LogFrame> _frameController =
      StreamController<LogFrame>.broadcast();
  StreamController<LogSocketState> _stateController =
      StreamController<LogSocketState>.broadcast();

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _manualClose = false;

  LogSocket({required this.url, this.pingInterval = const Duration(seconds: 30)});

  Stream<LogFrame> get frames => _frameController.stream;
  Stream<LogSocketState> get state => _stateController.stream;
  LogSocketState currentState = LogSocketState.disconnected;

  void connect() {
    if (_manualClose) return;
    if (currentState == LogSocketState.connecting ||
        currentState == LogSocketState.connected) return;

    _setState(LogSocketState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        _onData,
        onError: (Object e) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _setState(LogSocketState.connected);
      _reconnectAttempts = 0;
      _startPing();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic message) {
    if (message is! String) return;
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == 'log') {
        _frameController.add(LogFrame.fromJson(json));
      }
      // 'pong' frames ignored.
    } catch (_) {
      // Malformed frame — drop silently.
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      try {
        _channel?.sink.add(jsonEncode({'action': 'ping'}));
      } catch (_) {
        // Swallow — next onDone will trigger reconnect.
      }
    });
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;

    if (_manualClose) {
      _setState(LogSocketState.disconnected);
      return;
    }

    _setState(LogSocketState.disconnected);

    const backoffs = [1, 2, 5, 10];
    final delaySec = backoffs[
        _reconnectAttempts < backoffs.length ? _reconnectAttempts : backoffs.length - 1];
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySec), connect);
  }

  void _setState(LogSocketState s) {
    currentState = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<void> close() async {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(LogSocketState.disconnected);
  }

  void dispose() {
    close();
    _frameController.close();
    _stateController.close();
  }
}
