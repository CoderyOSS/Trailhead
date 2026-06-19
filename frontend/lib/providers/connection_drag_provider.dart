import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionDragState {
  final String sourceNodeId;
  final int? sourcePort;
  final bool sourceIsOutput;
  final Offset currentWorldPos;
  final String? targetNodeId;
  final bool? targetIsOutput;
  final int? targetPort;

  const ConnectionDragState({
    required this.sourceNodeId,
    this.sourcePort,
    required this.sourceIsOutput,
    required this.currentWorldPos,
    this.targetNodeId,
    this.targetIsOutput,
    this.targetPort,
  });

  ConnectionDragState copyWith({
    String? sourceNodeId,
    int? sourcePort,
    bool? sourceIsOutput,
    Offset? currentWorldPos,
    String? targetNodeId,
    bool? targetIsOutput,
    int? targetPort,
  }) {
    return ConnectionDragState(
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      sourcePort: sourcePort ?? this.sourcePort,
      sourceIsOutput: sourceIsOutput ?? this.sourceIsOutput,
      currentWorldPos: currentWorldPos ?? this.currentWorldPos,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      targetIsOutput: targetIsOutput ?? this.targetIsOutput,
      targetPort: targetPort ?? this.targetPort,
    );
  }
}

final connectionDragProvider = StateProvider<ConnectionDragState?>((ref) => null);
