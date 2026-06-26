import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloatingTextLayer', () {
    test('stacks rapid floating text spawns in the same hex', () {
      var now = DateTime(2026, 5, 5, 12);
      final layer = FloatingTextLayer(now: () => now);
      final parent = Component();

      final first = layer.spawn(
        parent: parent,
        effect: _effect(text: '-3'),
      );
      now = now.add(const Duration(milliseconds: 120));
      final second = layer.spawn(
        parent: parent,
        effect: _effect(text: '-1'),
      );
      now = now.add(const Duration(milliseconds: 120));
      final third = layer.spawn(
        parent: parent,
        effect: _effect(text: '+2'),
      );

      expect(second.position.x, closeTo(first.position.x, 0.0001));
      expect(second.position.y - first.position.y, closeTo(12, 0.0001));
      expect(third.position.y - first.position.y, closeTo(24, 0.0001));
    });

    test('does not stack different hexes', () {
      final now = DateTime(2026, 5, 5, 12);
      final layer = FloatingTextLayer(now: () => now);
      final parent = Component();

      final first = layer.spawn(
        parent: parent,
        effect: _effect(text: '-3'),
      );
      final second = layer.spawn(
        parent: parent,
        effect: _effect(text: '-1', col: 2, row: 1),
      );

      expect(second.position.y, isNot(closeTo(first.position.y + 12, 0.0001)));
    });

    test('reuses stack slots after the half-second window', () {
      var now = DateTime(2026, 5, 5, 12);
      final layer = FloatingTextLayer(now: () => now);
      final parent = Component();

      final first = layer.spawn(
        parent: parent,
        effect: _effect(text: '-3'),
      );
      now = now.add(const Duration(milliseconds: 520));
      final second = layer.spawn(
        parent: parent,
        effect: _effect(text: '-1'),
      );

      expect(second.position.y, closeTo(first.position.y, 0.0001));
    });

    test('animates movement and opacity by default', () async {
      final layer = FloatingTextLayer();
      final parent = Component();

      final component = layer.spawn(
        parent: parent,
        effect: _effect(text: '-3'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(component.children.whereType<MoveEffect>(), hasLength(1));
      expect(component.children.whereType<OpacityEffect>(), hasLength(1));
      expect(component.children.whereType<RemoveEffect>(), hasLength(1));
    });

    test('preserves bubble presentation for styled city cues', () async {
      final layer = FloatingTextLayer();
      final parent = Component();

      final component = layer.spawn(
        parent: parent,
        effect: _effect(
          text: 'Worker • 3 turns',
          presentation: FloatingTextPresentation.bubble,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(component.presentation, FloatingTextPresentation.bubble);
      expect(component.children.whereType<MoveEffect>(), hasLength(1));
      expect(component.children.whereType<OpacityEffect>(), hasLength(1));
      expect(component.children.whereType<RemoveEffect>(), hasLength(1));
    });

    test('anchors city bubbles above the normal tile floating text origin', () {
      final parent = Component();
      final plain = FloatingTextLayer().spawn(
        parent: parent,
        effect: _effect(text: '+1'),
      );
      final bubble = FloatingTextLayer().spawn(
        parent: parent,
        effect: _effect(
          text: 'Worker • 3 turns',
          presentation: FloatingTextPresentation.bubble,
        ),
      );

      expect(bubble.position.x, closeTo(plain.position.x, 0.0001));
      expect(bubble.position.y, lessThan(plain.position.y));
    });

    test('keeps text static when reduce motion is enabled', () async {
      final layer = FloatingTextLayer(reduceMotion: true);
      final parent = Component();

      final component = layer.spawn(
        parent: parent,
        effect: _effect(text: '-3'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(component.children.whereType<MoveEffect>(), isEmpty);
      expect(component.children.whereType<OpacityEffect>(), isEmpty);
      expect(component.children.whereType<RemoveEffect>(), hasLength(1));
    });

    test('does not attach floating text while hidden by density', () async {
      final layer = FloatingTextLayer(visible: false);
      final parent = Component();

      final component = layer.spawn(
        parent: parent,
        effect: _effect(text: '+1'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(parent.children, isEmpty);
      expect(component.children.whereType<MoveEffect>(), isEmpty);
      expect(component.children.whereType<OpacityEffect>(), isEmpty);
      expect(component.children.whereType<RemoveEffect>(), isEmpty);
    });
  });
}

ShowFloatingTextEffect _effect({
  required String text,
  int col = 1,
  int row = 1,
  FloatingTextPresentation presentation = FloatingTextPresentation.plain,
}) {
  return ShowFloatingTextEffect(
    text: text,
    col: col,
    row: row,
    colorValue: 0xFFFF5555,
    presentation: presentation,
  );
}
