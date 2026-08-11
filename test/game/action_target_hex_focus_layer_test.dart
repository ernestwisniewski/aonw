import 'dart:ui';

import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/action_target_hex_focus_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_outline_painter.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionTargetHexFocusLayer', () {
    test('marks the complete map hex with the shared dashed outline', () {
      final layer = ActionTargetHexFocusLayer();
      final parent = Component();

      layer.show(
        parent: parent,
        effect: const ShowActionTargetFocusEffect(col: 2, row: 3),
        reduceMotion: false,
      );

      expect(layer.activeForTesting, isTrue);
      expect(layer.visibleForTesting, isTrue);
      expect(layer.colForTesting, 2);
      expect(layer.rowForTesting, 3);
      expect(layer.colorForTesting, HudPalette.goldLight);
      expect(layer.patternForTesting, HexOutlinePattern.dashed);
      expect(layer.dashLengthForTesting, 6);
      expect(layer.gapLengthForTesting, 4);
      expect(
        layer.position,
        HexGeometry.tilePosition(
          col: 2,
          row: 3,
          hexRadius: MapConfig.defaultHexRadius,
        ),
      );
      expect(
        layer.outlineBoundsForTesting.width,
        closeTo(MapConfig.defaultHexRadius * 2, 0.001),
      );
      expect(layer.outlineBoundsForTesting.width, greaterThan(100));

      final recorder = PictureRecorder();
      layer.render(Canvas(recorder));
      final picture = recorder.endRecording();
      addTearDown(picture.dispose);
      expect(picture.approximateBytesUsed, greaterThan(0));
    });

    test('blinks for two seconds and then disappears', () {
      final layer = ActionTargetHexFocusLayer()
        ..show(
          parent: Component(),
          effect: const ShowActionTargetFocusEffect(col: 2, row: 3),
          reduceMotion: false,
        )
        ..update(0.35);
      expect(layer.visibleForTesting, isFalse);
      layer.update(0.15);
      expect(layer.visibleForTesting, isTrue);
      layer.update(1.49);
      expect(layer.activeForTesting, isTrue);
      layer.update(0.01);
      expect(layer.activeForTesting, isFalse);
      expect(layer.visibleForTesting, isFalse);
    });

    test('tracks the live world position of a focused unit', () {
      Vector2? unitPosition = UnitMarkerLayer.worldPositionFor(2, 3);
      final layer =
          ActionTargetHexFocusLayer(
            unitPositionFor: (unitId) {
              expect(unitId, 'unit_7');
              return unitPosition?.clone();
            },
          )..show(
            parent: Component(),
            effect: const ShowActionTargetFocusEffect(
              unitId: 'unit_7',
              col: 2,
              row: 3,
            ),
            reduceMotion: false,
          );

      expect(layer.unitIdForTesting, 'unit_7');
      final initialPosition = HexGeometry.tilePosition(
        col: 2,
        row: 3,
        hexRadius: MapConfig.defaultHexRadius,
      );
      expect(layer.position, initialPosition);

      unitPosition = UnitMarkerLayer.worldPositionFor(3, 3);
      layer.update(0.1);

      expect(
        layer.position,
        HexGeometry.tilePosition(
          col: 3,
          row: 3,
          hexRadius: MapConfig.defaultHexRadius,
        ),
      );

      final lastTrackedPosition = layer.position.clone();
      unitPosition = null;
      layer.update(0.1);

      expect(layer.position, lastTrackedPosition);
    });

    test('keeps a city target anchored to its map hex', () {
      final layer =
          ActionTargetHexFocusLayer(
            unitPositionFor: (_) => throw StateError('unexpected unit lookup'),
          )..show(
            parent: Component(),
            effect: const ShowActionTargetFocusEffect(col: 2, row: 3),
            reduceMotion: false,
          );
      final initialPosition = layer.position.clone();

      layer.update(0.1);

      expect(layer.unitIdForTesting, isNull);
      expect(layer.position, initialPosition);
    });

    test('refocuses one cue and stays visible with reduced motion', () {
      final layer = ActionTargetHexFocusLayer();
      final parent = Component();
      layer
        ..show(
          parent: parent,
          effect: const ShowActionTargetFocusEffect(col: 1, row: 1),
          reduceMotion: false,
        )
        ..update(1)
        ..show(
          parent: parent,
          effect: const ShowActionTargetFocusEffect(col: 4, row: 5),
          reduceMotion: true,
        )
        ..update(1.5);

      expect(layer.colForTesting, 4);
      expect(layer.rowForTesting, 5);
      expect(layer.activeForTesting, isTrue);
      expect(layer.visibleForTesting, isTrue);

      layer.update(0.5);
      expect(layer.activeForTesting, isFalse);
      expect(layer.visibleForTesting, isFalse);
    });
  });
}
