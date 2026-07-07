import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GamepadListCursor', () {
    const items = [
      _CursorItem('disabled', false),
      _CursorItem('first', true),
      _CursorItem('second', true),
    ];

    test('keeps a valid selected key', () {
      expect(
        GamepadListCursor.selectedKeyFor(
          items,
          'second',
          keyOf: (item) => item.key,
          prefer: (item) => item.preferred,
        ),
        'second',
      );
    });

    test('falls back to the first preferred item', () {
      expect(
        GamepadListCursor.selectedKeyFor(
          items,
          'missing',
          keyOf: (item) => item.key,
          prefer: (item) => item.preferred,
        ),
        'first',
      );
    });

    test('wraps navigation in both directions', () {
      expect(
        GamepadListCursor.nextKey(
          items: items,
          selectedKey: 'second',
          direction: GamepadMapDirection.down,
          keyOf: (item) => item.key,
          prefer: (item) => item.preferred,
        ),
        'disabled',
      );
      expect(
        GamepadListCursor.nextKey(
          items: items,
          selectedKey: 'disabled',
          direction: GamepadMapDirection.up,
          keyOf: (item) => item.key,
          prefer: (item) => item.preferred,
        ),
        'second',
      );
    });

    test('returns null for empty lists', () {
      expect(
        GamepadListCursor.selectedKeyFor<_CursorItem, String>(
          const <_CursorItem>[],
          null,
          keyOf: (item) => item.key,
        ),
        isNull,
      );
      expect(
        GamepadListCursor.nextKey<_CursorItem, String>(
          items: const <_CursorItem>[],
          selectedKey: null,
          direction: GamepadMapDirection.down,
          keyOf: (item) => item.key,
        ),
        isNull,
      );
    });
  });
}

final class _CursorItem {
  const _CursorItem(this.key, this.preferred);

  final String key;
  final bool preferred;
}
