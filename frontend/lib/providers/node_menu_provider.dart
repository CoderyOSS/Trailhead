import 'package:flutter_riverpod/flutter_riverpod.dart';

class NodeMenuAnchor {
  final String nodeId;

  const NodeMenuAnchor({required this.nodeId});
}

final nodeMenuProvider = StateProvider<NodeMenuAnchor?>((ref) => null);
