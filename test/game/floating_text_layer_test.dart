import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
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

    test('anchors unit bubbles above the resolved unit asset', () {
      final parent = Component();
      final layer = FloatingTextLayer(
        unitPositionFor: (unitId) {
          expect(unitId, 'unit_1');
          return Vector2(140, 220);
        },
      );
      final bubble = layer.spawn(
        parent: parent,
        effect: _effect(
          text: 'Artifact carried',
          presentation: FloatingTextPresentation.bubble,
          anchor: const FloatingTextAnchor.unit('unit_1'),
        ),
      );

      expect(bubble.position.x, closeTo(140, 0.0001));
      expect(bubble.position.y, lessThan(220));
    });

    test('anchors city bubbles above the city asset', () {
      final parent = Component();
      final layer = FloatingTextLayer();
      final bubble = layer.spawn(
        parent: parent,
        effect: _effect(
          text: 'Artifact stored',
          presentation: FloatingTextPresentation.bubble,
          anchor: const FloatingTextAnchor.city('city_1'),
        ),
      );

      final cityPosition = CityMarkerLayer.worldPositionFor(1, 1);
      expect(bubble.position.x, closeTo(cityPosition.x, 0.0001));
      expect(bubble.position.y, lessThan(cityPosition.y));
    });

    test('stacks independent entity anchors separately on the same hex', () {
      final parent = Component();
      final layer = FloatingTextLayer(
        unitPositionFor: (_) => Vector2(100, 200),
      );

      final unitBubble = layer.spawn(
        parent: parent,
        effect: _effect(
          text: 'Artifact carried',
          presentation: FloatingTextPresentation.bubble,
          anchor: const FloatingTextAnchor.unit('unit_1'),
        ),
      );
      final cityBubble = layer.spawn(
        parent: parent,
        effect: _effect(
          text: 'Artifact stored',
          presentation: FloatingTextPresentation.bubble,
          anchor: const FloatingTextAnchor.city('city_1'),
        ),
      );

      expect(unitBubble.position.x, closeTo(100, 0.0001));
      expect(
        cityBubble.position.x,
        closeTo(CityMarkerLayer.worldPositionFor(1, 1).x, 0.0001),
      );
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
  FloatingTextAnchor anchor = const FloatingTextAnchor.tile(),
}) {
  return ShowFloatingTextEffect(
    text: text,
    col: col,
    row: row,
    colorValue: 0xFFFF5555,
    presentation: presentation,
    anchor: anchor,
  );
}
