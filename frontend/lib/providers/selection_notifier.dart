import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionState {
  final Set<String> base;
  final Set<String> live;

  SelectionState({
    Set<String>? base,
    Set<String>? live,
  })  : base = Set.unmodifiable(base ?? const {}),
        live = Set.unmodifiable(live ?? const {});

  Set<String> get current => base.union(live);

  bool get active => live.isNotEmpty;

  bool contains(String id) => base.contains(id) || live.contains(id);

  SelectionState copyWith({Set<String>? base, Set<String>? live}) {
    return SelectionState(
      base: base ?? this.base,
      live: live ?? this.live,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionState &&
          setEquals(base, other.base) &&
          setEquals(live, other.live);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(base),
        Object.hashAllUnordered(live),
      );
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(SelectionState());

  void selectOne(String id) {
    state = SelectionState(base: {id}, live: const {});
  }

  void toggleOne(String id) {
    final next = Set<String>.from(state.base);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = SelectionState(base: next, live: const {});
  }

  void clear() {
    state = SelectionState();
  }

  void beginMarquee() {
    state =
        SelectionState(base: Set<String>.from(state.current), live: const {});
  }

  void updateMarqueeLive(Set<String> hits) {
    state = state.copyWith(live: Set<String>.from(hits));
  }

  void commitMarquee() {
    state = SelectionState(base: state.current, live: const {});
  }

  void cancelMarquee() {
    state = state.copyWith(live: const {});
  }

  void removeIds(Iterable<String> ids) {
    final next = Set<String>.from(state.base)..removeAll(ids);
    state = state.copyWith(base: next);
  }
}

final selectionProvider =
    StateNotifierProvider<SelectionNotifier, SelectionState>(
  (ref) => SelectionNotifier(),
);
