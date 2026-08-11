part of '../game_renderer_keyboard_test.dart';

void _registerKeyboardPanScenarios() {
  group('GameRenderer keyboard pan', () {
    late GameRenderer game;

    setUp(() {
      game = GameRenderer(mapData: kbMinimalMap(), onCommand: (_) async {});
    });

    test('keyboardPanDelta is zero when no keys pressed', () {
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, equals(0.0));
      expect(delta.y, equals(0.0));
    });

    test('W key produces upward pan delta (negative Y)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyW,
          logicalKey: LogicalKeyboardKey.keyW,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyW},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, lessThan(0));
      expect(delta.x, equals(0.0));
    });

    test('S key produces downward pan delta (positive Y)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyS,
          logicalKey: LogicalKeyboardKey.keyS,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyS},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, greaterThan(0));
      expect(delta.x, equals(0.0));
    });

    test('A key produces leftward pan delta (negative X)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyA,
          logicalKey: LogicalKeyboardKey.keyA,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyA},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, lessThan(0));
      expect(delta.y, equals(0.0));
    });

    test('D key produces rightward pan delta (positive X)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyD,
          logicalKey: LogicalKeyboardKey.keyD,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyD},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, greaterThan(0));
      expect(delta.y, equals(0.0));
    });

    test('key released clears direction', () {
      game
        ..onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.keyW},
        )
        ..onKeyEvent(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
          {},
        );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, equals(0.0));
      expect(delta.y, equals(0.0));
    });

    test('diagonal: W+D produces both negative Y and positive X', () {
      game
        ..onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD},
        )
        ..onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyD,
            logicalKey: LogicalKeyboardKey.keyD,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD},
        );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, lessThan(0));
      expect(delta.x, greaterThan(0));
    });

    test('arrow keys work the same as WASD', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowUp,
          logicalKey: LogicalKeyboardKey.arrowUp,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.arrowUp},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, lessThan(0));
    });
  });
}
