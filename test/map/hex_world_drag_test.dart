import 'package:aonw/map/rendering/hex_world.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

// Minimal concrete HexWorld for testing.
class _TestHexWorld extends HexWorld {
  @override
  Future<void> buildWorld() async {}
}

void main() {
  group('HexWorld drag threshold', () {
    late _TestHexWorld game;

    setUp(() {
      game = _TestHexWorld();
    });

    test('isDragging is false before any drag', () {
      expect(game.isDragging, isFalse);
    });

    test('isDragging becomes true after 8px travel', () {
      game
        ..processDragStart()
        ..processDragUpdate(Vector2(8, 0));
      expect(game.isDragging, isTrue);
    });

    test('isDragging stays false below 8px travel', () {
      game
        ..processDragStart()
        ..processDragUpdate(Vector2(3, 0));
      expect(game.isDragging, isFalse);
    });

    test('isDragging becomes true after cumulative 8px travel', () {
      game
        ..processDragStart()
        ..processDragUpdate(Vector2(4, 0))
        ..processDragUpdate(Vector2(4, 0));
      expect(game.isDragging, isTrue);
    });

    test('isDragging resets to false after drag ends', () {
      game
        ..processDragStart()
        ..processDragUpdate(Vector2(10, 0));
      expect(game.isDragging, isTrue);
      game.processDragEnd();
      expect(game.isDragging, isFalse);
    });

    test('travel accumulates across multiple updates', () {
      game
        ..processDragStart()
        ..processDragUpdate(Vector2(3, 0));
      expect(game.isDragging, isFalse);
      game.processDragUpdate(Vector2(3, 0));
      expect(game.isDragging, isFalse);
      game.processDragUpdate(Vector2(3, 0)); // total = 9 >= 8
      expect(game.isDragging, isTrue);
    });

    test('travel resets on new drag start', () {
      game
        ..processDragStart()
        ..processDragUpdate(Vector2(10, 0));
      expect(game.isDragging, isTrue);
      game
        ..processDragEnd()
        ..processDragStart()
        ..processDragUpdate(Vector2(3, 0));
      expect(game.isDragging, isFalse);
    });

    test('viewport one-finger drag pans camera after threshold', () {
      game.camera.viewfinder.zoom = 1;
      game.camera.viewfinder.position = Vector2.zero();

      game
        ..handleViewportPointerDown(1, Vector2.zero())
        ..handleViewportPointerMove(1, Vector2(3, 0));
      expect(game.camera.viewfinder.position.x, 0);

      game.handleViewportPointerMove(1, Vector2(10, 0));
      expect(game.isDragging, isTrue);
      expect(game.hasQueuedViewportCameraInput, isTrue);
      expect(game.camera.viewfinder.position.x, 0);

      game.update(0);

      expect(game.camera.viewfinder.position.x, -7);

      game.handleViewportPointerUp(1);
      expect(game.isDragging, isFalse);
    });

    test(
      'viewport drag coalesces multiple move events into one camera update',
      () {
        game.camera.viewfinder.zoom = 1;
        game.camera.viewfinder.position = Vector2.zero();

        game
          ..handleViewportPointerDown(1, Vector2.zero())
          ..handleViewportPointerMove(1, Vector2(10, 0))
          ..handleViewportPointerMove(1, Vector2(18, 0))
          ..handleViewportPointerMove(1, Vector2(24, 0));

        expect(game.camera.viewfinder.position.x, 0);
        expect(game.hasQueuedViewportCameraInput, isTrue);

        game.update(0);

        expect(game.camera.viewfinder.position.x, -24);
        expect(game.hasQueuedViewportCameraInput, isFalse);
      },
    );

    test('viewport two-finger pinch zooms camera', () {
      game.camera.viewfinder.zoom = 1;

      game
        ..handleViewportPointerDown(1, Vector2(0, 0))
        ..handleViewportPointerDown(2, Vector2(10, 0))
        ..handleViewportPointerMove(2, Vector2(20, 0));

      expect(game.hasQueuedViewportCameraInput, isTrue);
      expect(game.camera.viewfinder.zoom, 1);

      game.update(0);

      expect(game.camera.viewfinder.zoom, 2);
    });

    test('zooming around a viewport point keeps that world point fixed', () {
      game.camera.viewfinder
        ..zoom = 1
        ..position = Vector2(10, 20);
      final focalPoint = Vector2(40, 30);
      final worldBefore = game.viewportToWorld(focalPoint);

      game.setZoomAround(2, focalPoint);

      expect(game.camera.viewfinder.zoom, 2);
      expect(game.viewportToWorld(focalPoint).x, closeTo(worldBefore.x, 0.001));
      expect(game.viewportToWorld(focalPoint).y, closeTo(worldBefore.y, 0.001));
    });

    test('viewport pinch zooms around the gesture midpoint', () {
      game.camera.viewfinder
        ..zoom = 1
        ..position = Vector2.zero();

      game
        ..handleViewportPointerDown(1, Vector2(0, 0))
        ..handleViewportPointerDown(2, Vector2(10, 0))
        ..handleViewportPointerMove(1, Vector2(-5, 0))
        ..handleViewportPointerMove(2, Vector2(15, 0));

      expect(game.hasQueuedViewportCameraInput, isTrue);
      expect(game.camera.viewfinder.zoom, 1);

      game.update(0);

      expect(game.camera.viewfinder.zoom, 2);
      expect(game.viewportToWorld(Vector2(5, 0)).x, closeTo(5, 0.001));
      expect(game.camera.viewfinder.position.x, closeTo(2.5, 0.001));
    });

    test('trackpad pan zoom scales around the gesture focal point', () {
      game.camera.viewfinder
        ..zoom = 1
        ..position = Vector2.zero();
      final focalPoint = Vector2(50, 40);
      final worldBefore = game.viewportToWorld(focalPoint);

      game
        ..handleViewportPanZoomStart(focalPoint)
        ..handleViewportPanZoomUpdate(
          panDelta: Vector2.zero(),
          scale: 2,
          focalPoint: focalPoint,
        );

      expect(game.hasQueuedViewportCameraInput, isTrue);
      expect(game.camera.viewfinder.zoom, 1);

      game.update(0);

      expect(game.camera.viewfinder.zoom, 2);
      expect(game.viewportToWorld(focalPoint).x, closeTo(worldBefore.x, 0.001));
      expect(game.viewportToWorld(focalPoint).y, closeTo(worldBefore.y, 0.001));
    });

    test('trackpad pan zoom keeps only the latest zoom for a frame', () {
      game.camera.viewfinder
        ..zoom = 1
        ..position = Vector2.zero();
      final focalPoint = Vector2(50, 40);

      game
        ..handleViewportPanZoomStart(focalPoint)
        ..handleViewportPanZoomUpdate(
          panDelta: Vector2(2, 0),
          scale: 1.2,
          focalPoint: focalPoint,
        )
        ..handleViewportPanZoomUpdate(
          panDelta: Vector2(3, 0),
          scale: 1.5,
          focalPoint: focalPoint,
        );

      expect(game.camera.viewfinder.zoom, 1);

      game.update(0);

      expect(game.camera.viewfinder.zoom, 1.5);
      expect(
        game.camera.viewfinder.position.x,
        closeTo(50 - 50 / 1.5 - 5 / 1.5, 0.001),
      );
    });
  });
}
