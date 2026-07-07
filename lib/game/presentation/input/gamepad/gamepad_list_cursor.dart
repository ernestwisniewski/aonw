import 'package:aonw/game/presentation/input/gamepad/gamepad_input_snapshot.dart';

typedef GamepadCursorKeyOf<T, K> = K Function(T item);
typedef GamepadCursorPreference<T> = bool Function(T item);

abstract final class GamepadListCursor {
  static K? selectedKeyFor<T, K>(
    List<T> items,
    K? selectedKey, {
    required GamepadCursorKeyOf<T, K> keyOf,
    GamepadCursorPreference<T>? prefer,
  }) {
    if (selectedKey != null &&
        items.any((item) => keyOf(item) == selectedKey)) {
      return selectedKey;
    }
    if (prefer != null) {
      for (final item in items) {
        if (prefer(item)) return keyOf(item);
      }
    }
    return items.isEmpty ? null : keyOf(items.first);
  }

  static T? selectedItemFor<T, K>(
    List<T> items,
    K? selectedKey, {
    required GamepadCursorKeyOf<T, K> keyOf,
    GamepadCursorPreference<T>? prefer,
  }) {
    final effectiveKey = selectedKeyFor(
      items,
      selectedKey,
      keyOf: keyOf,
      prefer: prefer,
    );
    if (effectiveKey == null) return null;
    for (final item in items) {
      if (keyOf(item) == effectiveKey) return item;
    }
    return null;
  }

  static K? nextKey<T, K>({
    required List<T> items,
    required K? selectedKey,
    required GamepadMapDirection direction,
    required GamepadCursorKeyOf<T, K> keyOf,
    GamepadCursorPreference<T>? prefer,
  }) {
    final next = nextItem(
      items: items,
      selectedKey: selectedKey,
      delta: deltaForDirection(direction),
      keyOf: keyOf,
      prefer: prefer,
    );
    return next == null ? null : keyOf(next);
  }

  static T? nextItem<T, K>({
    required List<T> items,
    required K? selectedKey,
    required int delta,
    required GamepadCursorKeyOf<T, K> keyOf,
    GamepadCursorPreference<T>? prefer,
  }) {
    if (items.isEmpty) return null;
    final effectiveKey = selectedKeyFor(
      items,
      selectedKey,
      keyOf: keyOf,
      prefer: prefer,
    );
    final selectedIndex = items.indexWhere(
      (item) => keyOf(item) == effectiveKey,
    );
    final currentIndex = selectedIndex < 0 ? 0 : selectedIndex;
    return items[_wrappedIndex(currentIndex + delta, items.length)];
  }

  static T? nextValue<T>({
    required List<T> items,
    required T? selected,
    required int delta,
  }) {
    if (items.isEmpty) return null;
    final selectedIndex = selected == null ? -1 : items.indexOf(selected);
    final currentIndex = selectedIndex < 0 ? 0 : selectedIndex;
    return items[_wrappedIndex(currentIndex + delta, items.length)];
  }

  static int deltaForDirection(GamepadMapDirection direction) {
    return switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.left => -1,
      GamepadMapDirection.down || GamepadMapDirection.right => 1,
    };
  }

  static int _wrappedIndex(int index, int length) {
    final wrapped = index % length;
    return wrapped < 0 ? wrapped + length : wrapped;
  }
}
