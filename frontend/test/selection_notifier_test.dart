import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/selection_notifier.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  SelectionNotifier get() => container.read(selectionProvider.notifier);
  SelectionState state() => container.read(selectionProvider);

  test('initial state is empty', () {
    expect(state().current, isEmpty);
    expect(state().active, isFalse);
  });

  test('selectOne replaces selection', () {
    get().selectOne('a');
    expect(state().current, {'a'});
    get().selectOne('b');
    expect(state().current, {'b'});
  });

  test('toggleOne adds then removes', () {
    get().toggleOne('a');
    expect(state().current, {'a'});
    get().toggleOne('a');
    expect(state().current, isEmpty);
  });

  test('toggleOne on top of existing selection adds', () {
    get().selectOne('a');
    get().toggleOne('b');
    expect(state().current, {'a', 'b'});
  });

  test('clear empties everything', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b', 'c'});
    get().clear();
    expect(state().current, isEmpty);
    expect(state().live, isEmpty);
    expect(state().base, isEmpty);
  });

  test('beginMarquee freezes base, clears live', () {
    get().selectOne('a');
    get().beginMarquee();
    expect(state().base, {'a'});
    expect(state().live, isEmpty);
    expect(state().active, isFalse);
  });

  test('updateMarqueeLive overwrites live only', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b', 'c'});
    expect(state().live, {'b', 'c'});
    expect(state().base, {'a'});
    expect(state().current, {'a', 'b', 'c'});
    expect(state().active, isTrue);
  });

  test('updateMarqueeLive shrinking removes from live', () {
    get().beginMarquee();
    get().updateMarqueeLive({'a', 'b', 'c'});
    get().updateMarqueeLive({'b'});
    expect(state().current, {'b'});
    expect(state().live, {'b'});
  });

  test('commitMarquee unions live into base and clears live', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b', 'c'});
    get().commitMarquee();
    expect(state().base, {'a', 'b', 'c'});
    expect(state().live, isEmpty);
    expect(state().active, isFalse);
  });

  test('cancelMarquee discards live, keeps base', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    get().cancelMarquee();
    expect(state().base, {'a'});
    expect(state().live, isEmpty);
    expect(state().current, {'a'});
  });

  test('multiple marquees accumulate via commit', () {
    get().beginMarquee();
    get().updateMarqueeLive({'a'});
    get().commitMarquee();
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    get().commitMarquee();
    expect(state().current, {'a', 'b'});
  });

  test('removeIds removes from base only', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    get().removeIds({'a'});
    expect(state().base, isEmpty);
    expect(state().live, {'b'});
  });

  test('beginMarquee when live already non-empty folds live into base', () {
    get().beginMarquee();
    get().updateMarqueeLive({'a'});
    get().beginMarquee();
    expect(state().base, {'a'});
    expect(state().live, isEmpty);
  });

  test('commitMarquee without beginMarquee is a no-op-safe (live empty)', () {
    get().selectOne('a');
    get().commitMarquee();
    expect(state().current, {'a'});
    expect(state().live, isEmpty);
  });

  test('cancelMarquee without beginMarquee is a no-op', () {
    get().selectOne('a');
    get().cancelMarquee();
    expect(state().current, {'a'});
  });

  test('contains checks both base and live', () {
    get().selectOne('a');
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    expect(state().contains('a'), isTrue);
    expect(state().contains('b'), isTrue);
    expect(state().contains('c'), isFalse);
  });

  test('active reflects live only', () {
    expect(state().active, isFalse);
    get().selectOne('a');
    expect(state().active, isFalse);
    get().beginMarquee();
    get().updateMarqueeLive({'b'});
    expect(state().active, isTrue);
    get().commitMarquee();
    expect(state().active, isFalse);
  });
}
