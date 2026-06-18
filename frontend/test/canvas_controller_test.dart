import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/canvas_controller.dart';

void main() {
  late ProviderContainer container;
  late CanvasController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(canvasControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('zoomAt with negative delta zooms in and keeps cursor anchored', () {
    const cursor = Offset(200, 100);
    final vp0 = controller.state;
    final worldBefore = (cursor - vp0.pan) / vp0.zoom;

    controller.zoomAt(-100, cursor);

    final vp1 = controller.state;
    expect(vp1.zoom, greaterThan(vp0.zoom));
    final worldAfter = (cursor - vp1.pan) / vp1.zoom;
    expect((worldAfter - worldBefore).distance, lessThan(1e-9));
  });

  test('zoomAt with positive delta zooms out and keeps cursor anchored', () {
    const cursor = Offset(0, 0);
    controller.setZoom(1.0);
    final vp0 = controller.state;
    final worldBefore = (cursor - vp0.pan) / vp0.zoom;

    controller.zoomAt(120, cursor);

    final vp1 = controller.state;
    expect(vp1.zoom, lessThan(vp0.zoom));
    final worldAfter = (cursor - vp1.pan) / vp1.zoom;
    expect((worldAfter - worldBefore).distance, lessThan(1e-9));
  });

  test('zoomAt respects clamp at 2.0', () {
    controller.setZoom(1.95);
    controller.zoomAt(-1000, Offset.zero);
    expect(controller.state.zoom, lessThanOrEqualTo(2.0));
  });

  test('zoomAt respects clamp at 0.35', () {
    controller.setZoom(0.4);
    controller.zoomAt(1000, Offset.zero);
    expect(controller.state.zoom, greaterThanOrEqualTo(0.35));
  });

  test('zoomAt is clamped when already at max', () {
    controller.setZoom(2.0);
    controller.zoomAt(-100, const Offset(0, 0));
    expect(controller.state.zoom, 2.0);
  });
}
