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
  Offset? _scaleStartFocal;
  bool _isScaling = false;

  bool get isScaling => _isScaling;

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

  void fitToBounds(Rect bounds, Size canvasSize, {double margin = 24.0}) {
    final boundsWidth = bounds.width;
    final boundsHeight = bounds.height;
    if (boundsWidth <= 0 || boundsHeight <= 0 || canvasSize.isEmpty) {
      reset();
      return;
    }
    final availableWidth = canvasSize.width - margin * 2;
    final availableHeight = canvasSize.height - margin * 2;
    if (availableWidth <= 0 || availableHeight <= 0) {
      reset();
      return;
    }
    final zoomX = availableWidth / boundsWidth;
    final zoomY = availableHeight / boundsHeight;
    final zoom = (zoomX < zoomY ? zoomX : zoomY).clamp(0.35, 2.0);
    final center = bounds.center;
    final panX = canvasSize.width / 2 - center.dx * zoom;
    final panY = canvasSize.height / 2 - center.dy * zoom;
    state = CanvasViewport(zoom: zoom, pan: Offset(panX, panY));
  }

  void beginScale(Offset focalPoint) {
    _scaleStartZoom = state.zoom;
    _scaleStartPan = state.pan;
    _scaleStartFocal = focalPoint;
    _isScaling = true;
  }

  void updateScale(double cumulativeScale, Offset focalPoint) {
    if (_scaleStartZoom == null) return;
    final newZoom = (_scaleStartZoom! * cumulativeScale).clamp(0.35, 2.0);
    final scaleChange = newZoom / _scaleStartZoom!;
    final newPan = focalPoint - (_scaleStartFocal! - _scaleStartPan!) * scaleChange;
    state = CanvasViewport(zoom: newZoom, pan: newPan);
  }

  void endScale() {
    _scaleStartZoom = null;
    _scaleStartPan = null;
    _scaleStartFocal = null;
    _isScaling = false;
  }

  /// Zoom by a scroll-delta amount anchored to a screen cursor position.
  /// Negative delta zooms in (wheel scroll up); positive zooms out.
  void zoomAt(double scrollDelta, Offset screenCursor) {
    final factor = scrollDelta < 0 ? 1.15 : 1 / 1.15;
    zoomBy(factor, focal: screenCursor);
  }
}

final canvasControllerProvider =
    StateNotifierProvider<CanvasController, CanvasViewport>(
  (ref) => CanvasController(),
);
