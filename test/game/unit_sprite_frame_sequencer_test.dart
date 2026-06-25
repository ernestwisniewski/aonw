import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite_catalog.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite_frame_sequencer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitSpriteFrameSequencer', () {
    test('advances idle frames without requiring a loaded image', () {
      final sequencer = UnitSpriteFrameSequencer(UnitSpriteCatalog.commander);

      expect(sequencer.currentColumn(), 0);

      sequencer.update(0.55);
      expect(sequencer.currentColumn(), 0);

      sequencer.update(0.20);
      expect(sequencer.currentColumn(), 0);

      sequencer.update(0.15);
      expect(sequencer.currentColumn(), 1);

      sequencer.update(0.90);
      expect(sequencer.currentColumn(), 2);
    });

    test('pauses idle after a full loop before restarting animation', () {
      final sequencer = UnitSpriteFrameSequencer(
        UnitSpriteCatalog.commander,
        idlePauseDurationFactory: () => 0.75,
      );

      for (var i = 0; i < 5; i++) {
        sequencer.update(0.9);
      }
      expect(sequencer.currentColumn(), 5);

      sequencer.update(0.9);

      expect(sequencer.currentColumn(), 0);
      expect(sequencer.idlePauseRemainingForTesting, closeTo(0.75, 0.0001));

      sequencer.update(0.5);

      expect(sequencer.currentColumn(), 0);
      expect(sequencer.idlePauseRemainingForTesting, closeTo(0.25, 0.0001));

      sequencer
        ..update(0.25)
        ..update(0.89);

      expect(sequencer.currentColumn(), 0);

      sequencer.update(0.01);

      expect(sequencer.currentColumn(), 1);
    });

    test('caps idle pause duration at one second', () {
      final sequencer = UnitSpriteFrameSequencer(
        UnitSpriteCatalog.commander,
        idlePauseDurationFactory: () => 1.25,
      );

      for (var i = 0; i < 6; i++) {
        sequencer.update(0.9);
      }

      expect(
        sequencer.idlePauseRemainingForTesting,
        UnitSpriteFrameSequencer.maxIdlePauseSeconds,
      );
    });

    test('can disable idle pauses for focused units', () {
      final sequencer = UnitSpriteFrameSequencer(
        UnitSpriteCatalog.commander,
        idlePauseDurationFactory: () => 1.25,
      )..idlePausesEnabled = false;

      for (var i = 0; i < 6; i++) {
        sequencer.update(0.9);
      }

      expect(sequencer.currentColumn(), 0);
      expect(sequencer.idlePauseRemainingForTesting, 0);

      sequencer.update(0.9);

      expect(sequencer.currentColumn(), 1);
      expect(sequencer.idlePauseRemainingForTesting, 0);
    });

    test('mirrors walk animation when moving left', () {
      final sequencer = UnitSpriteFrameSequencer(UnitSpriteCatalog.commander);

      expect(
        sequencer.playWalkToward(from: Vector2.zero(), to: Vector2(10, 0)),
        isTrue,
      );
      expect(sequencer.currentColumn(), 0);
      expect(sequencer.mirrored, isFalse);

      expect(
        sequencer.playWalkToward(from: Vector2.zero(), to: Vector2(-10, 0)),
        isTrue,
      );
      expect(sequencer.currentColumn(), 0);
      expect(sequencer.mirrored, isTrue);
    });

    test('stops non-looping sequences on the final logical frame', () {
      final sequencer = UnitSpriteFrameSequencer(UnitSpriteCatalog.commander);

      expect(sequencer.playAction(UnitSpriteAction.attack), isTrue);

      for (var i = 0; i < 10; i++) {
        sequencer.update(0.09);
      }

      expect(sequencer.logicalFrameIndex, 5);
      expect(sequencer.currentColumn(), 5);
    });

    test('falls back to idle for unsupported civilian attack animation', () {
      final sequencer = UnitSpriteFrameSequencer(UnitSpriteCatalog.settler);

      expect(sequencer.playAction(UnitSpriteAction.attack), isFalse);
      expect(sequencer.action, UnitSpriteAction.idle);
    });
  });
}
