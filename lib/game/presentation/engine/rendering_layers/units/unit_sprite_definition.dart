import 'dart:math' as math;

import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:flame/components.dart';

enum UnitSpriteAction { idle, walk, attack, work, die }

enum UnitSpriteDirection {
  s,
  sw,
  w,
  nw,
  n,
  ne,
  e,
  se;

  static UnitSpriteDirection fromDelta(Vector2 delta) {
    if (delta.length2 == 0) return sw;
    final degrees = (math.atan2(delta.y, delta.x) * 180 / math.pi + 360) % 360;
    if (degrees >= 22.5 && degrees < 67.5) return se;
    if (degrees >= 67.5 && degrees < 112.5) return s;
    if (degrees >= 112.5 && degrees < 157.5) return sw;
    if (degrees >= 157.5 && degrees < 202.5) return w;
    if (degrees >= 202.5 && degrees < 247.5) return nw;
    if (degrees >= 247.5 && degrees < 292.5) return n;
    if (degrees >= 292.5 && degrees < 337.5) return ne;
    return e;
  }
}

class UnitSpriteSize {
  const UnitSpriteSize({required this.width, required this.height});

  final double width;
  final double height;
}

class UnitSpriteActionDefinition {
  const UnitSpriteActionDefinition({
    required this.frameDuration,
    this.loops = true,
    this.frameCount = 6,
  });

  final double frameDuration;
  final bool loops;
  final int frameCount;
}

class UnitSpriteDefinition {
  const UnitSpriteDefinition({
    required this.spriteName,
    required this.normalSize,
    required this.smallSize,
    required this.actions,
    this.defaultDirection = UnitSpriteDirection.se,
  });

  final String spriteName;
  final UnitSpriteSize normalSize;
  final UnitSpriteSize smallSize;
  final UnitSpriteDirection defaultDirection;
  final Map<UnitSpriteAction, UnitSpriteActionDefinition> actions;

  UnitSpriteActionDefinition actionDefinition(UnitSpriteAction action) {
    return actions[action] ?? actions[UnitSpriteAction.idle]!;
  }

  UnitSpriteAction supportedAction(UnitSpriteAction action) {
    return actions.containsKey(action) ? action : UnitSpriteAction.idle;
  }

  UnitSpriteSize sizeFor({required bool onCity}) =>
      onCity ? smallSize : normalSize;

  SpriteSequenceId sequenceIdFor(UnitSpriteAction action) {
    final supported = supportedAction(action);
    return SpriteSequenceId('unit.$spriteName.${supported.name}');
  }

  Iterable<SpriteFrameId> get allFrameIds sync* {
    for (final action in actions.keys) {
      final sequence = sequenceIdFor(action);
      final count = actionDefinition(action).frameCount;
      for (var index = 0; index < count; index++) {
        yield sequence.frame(index);
      }
    }
  }
}
