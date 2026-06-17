import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NodeMenuAnchor {
  final Offset screenPos;
  final String nodeId;

  const NodeMenuAnchor({
    required this.screenPos,
    required this.nodeId,
  });
}

final nodeMenuProvider = StateProvider<NodeMenuAnchor?>((ref) => null);
