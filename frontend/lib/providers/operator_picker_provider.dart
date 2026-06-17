import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PickerAnchor {
  final Offset screenPos;
  final String sourceNodeId;
  final int? sourcePort;

  const PickerAnchor({
    required this.screenPos,
    required this.sourceNodeId,
    this.sourcePort,
  });
}

final operatorPickerProvider = StateProvider<PickerAnchor?>((ref) => null);
