import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/shared/widgets/viewport_gesture_layer.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _GestureWorld extends HexWorld {
  final events = <String>[];

  @override
  Future<void> buildWorld() async {}

  @override
  void handleViewportLongPressStart(Vector2 position) {
    events.add('start:${position.x.round()},${position.y.round()}');
  }

  @override
  void handleViewportLongPressUp() {
    events.add('up');
  }

  @override
  void handleViewportLongPressEnd(Vector2 position) {
    events.add('end:${position.x.round()},${position.y.round()}');
  }
}

void main() {
  testWidgets('forwards long press gestures to the hex world', (tester) async {
    final world = _GestureWorld();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: ViewportGestureLayer(
            game: world,
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );

    await tester.longPressAt(const Offset(40, 50));
    await tester.pump();

    expect(world.events.first, 'start:40,50');
    expect(world.events, contains('up'));
  });
}
