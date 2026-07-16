import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Transient red flash shown at a world position when the user attempts a
/// drag-drop connection that fails validation (e.g. second pipe from the same
/// source). The canvas sets this on invalid drop; a Timer in `graph_canvas`
/// clears it after [_defaultDurationMs].
///
/// The `id` field forces a fresh notification even when the same position
/// fails twice in a row (otherwise Riverpod would dedupe the state change
/// and the second flash would never fire).
class InvalidDropFlash {
  final Offset worldPos;
  final int id;

  const InvalidDropFlash({required this.worldPos, required this.id});
}

const int _defaultDurationMs = 600;

/// Duration the invalid-drop flash stays visible before auto-clearing.
final invalidDropFlashDuration = Duration(milliseconds: _defaultDurationMs);

final invalidDropFlashProvider =
    StateProvider<InvalidDropFlash?>((ref) => null);
