import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/selection_notifier.dart';

void main() {
  test('marquee union across two simulated drags accumulates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    // Simulate first marquee: covers nodes A, B
    n.beginMarquee();
    n.updateMarqueeLive({'A', 'B'});
    expect(container.read(selectionProvider).current, {'A', 'B'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A', 'B'});

    // Second marquee covers C only (A, B no longer in rect)
    n.beginMarquee();
    n.updateMarqueeLive({'C'});
    expect(container.read(selectionProvider).current, {'A', 'B', 'C'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A', 'B', 'C'});
  });

  test('marquee shrink within single drag removes from live', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    n.beginMarquee();
    n.updateMarqueeLive({'A', 'B', 'C'});
    n.updateMarqueeLive({'A', 'B'});
    n.updateMarqueeLive({'A'});
    expect(container.read(selectionProvider).current, {'A'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A'});
  });

  test('marquee cancel discards live but keeps base', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    n.selectOne('A');
    n.beginMarquee();
    n.updateMarqueeLive({'B', 'C'});
    n.cancelMarquee();
    expect(container.read(selectionProvider).current, {'A'});
  });

  test('marquee over already-selected nodes keeps them via union', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    // Pre-select A via tap
    n.selectOne('A');
    // Marquee over A and B
    n.beginMarquee();
    n.updateMarqueeLive({'A', 'B'});
    expect(container.read(selectionProvider).current, {'A', 'B'});
    // Marquee shrinks past A
    n.updateMarqueeLive({'B'});
    // A still selected via base
    expect(container.read(selectionProvider).current, {'A', 'B'});
    n.commitMarquee();
    expect(container.read(selectionProvider).current, {'A', 'B'});
  });

  test('removeIds after marquee commit cleans up selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final n = container.read(selectionProvider.notifier);

    n.beginMarquee();
    n.updateMarqueeLive({'A', 'B', 'C'});
    n.commitMarquee();
    n.removeIds(['B']);
    expect(container.read(selectionProvider).current, {'A', 'C'});
  });
}
