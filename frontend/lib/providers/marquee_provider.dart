import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarqueeState {
  final Rect screenRect;
  final bool active;

  const MarqueeState({this.screenRect = Rect.zero, this.active = false});

  MarqueeState copyWith({Rect? screenRect, bool? active}) {
    return MarqueeState(
      screenRect: screenRect ?? this.screenRect,
      active: active ?? this.active,
    );
  }
}

final marqueeProvider = StateProvider<MarqueeState>(
  (ref) => const MarqueeState(),
);

final mouseMarqueeStartProvider = StateProvider<Offset?>((ref) => null);
