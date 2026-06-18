import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasViewport {
  final double zoom;
  final Offset pan;

  const CanvasViewport({this.zoom = 1.0, this.pan = Offset.zero});

  CanvasViewport copyWith({double? zoom, Offset? pan}) {
    return CanvasViewport(
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
    );
  }
}

class CanvasController extends StateNotifier<CanvasViewport> {
  CanvasController() : super(const CanvasViewport());

  double? _scaleStartZoom;
  Offset? _scaleStartPan;

  void pan(Offset delta) {
    state = state.copyWith(pan: state.pan + delta);
  }

  void setZoom(double value) {
    state = state.copyWith(zoom: value.clamp(0.35, 2.0));
  }

  void zoomBy(double factor, {Offset? focal}) {
    final newZoom = (state.zoom * factor).clamp(0.35, 2.0);
    if (focal == null) {
      state = state.copyWith(zoom: newZoom);
      return;
    }
    final scaleChange = newZoom / state.zoom;
    final newPan = focal - (focal - state.pan) * scaleChange;
    state = CanvasViewport(zoom: newZoom, pan: newPan);
  }

  void reset() {
    state = const CanvasViewport();
  }

  void setViewport(CanvasViewport value) {
    state = value;
  }

  void beginScale() {
    _scaleStartZoom = state.zoom;
    _scaleStartPan = state.pan;
  }

  void updateScale(double cumulativeScale, Offset focalPoint) {
    if (_scaleStartZoom == null) return;
    final newZoom = (_scaleStartZoom! * cumulativeScale).clamp(0.35, 2.0);
    final scaleChange = newZoom / _scaleStartZoom!;
    final newPan = focalPoint - (focalPoint - _scaleStartPan!) * scaleChange;
    state = CanvasViewport(zoom: newZoom, pan: newPan);
  }

  void endScale() {
    _scaleStartZoom = null;
    _scaleStartPan = null;
  }
}

final canvasControllerProvider =
    StateNotifierProvider<CanvasController, CanvasViewport>(
  (ref) => CanvasController(),
);
