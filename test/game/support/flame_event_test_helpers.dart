import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';

/// Dispatches a complete Flame tap sequence at a component-local position.
void dispatchTapAtLocalPosition(
  FlameGame game,
  PositionComponent component,
  Offset localPosition,
) {
  final canvasPosition = component.absolutePositionOf(
    Vector2(localPosition.dx, localPosition.dy),
  );
  final eventPosition = Offset(canvasPosition.x, canvasPosition.y);
  game.firstChild<MultiTapDispatcher>()!
    ..onTapDown(
      createTapDownEvents(
        game: game,
        globalPosition: eventPosition,
        localPosition: eventPosition,
      ),
    )
    ..onTapUp(
      createTapUpEvents(
        game: game,
        globalPosition: eventPosition,
        localPosition: eventPosition,
      ),
    );
}
