import 'package:aonw/map/rendering/hex_world.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

typedef ViewportTapCallback = void Function(Vector2 position);

class ViewportGestureLayer extends StatelessWidget {
  final Widget child;
  final HexWorld? game;
  final ViewportTapCallback? onTap;

  const ViewportGestureLayer({
    required this.child,
    this.game,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: game == null
          ? null
          : (event) => game!.handleViewportPointerDown(
              event.pointer,
              Vector2(event.localPosition.dx, event.localPosition.dy),
            ),
      onPointerMove: game == null
          ? null
          : (event) => game!.handleViewportPointerMove(
              event.pointer,
              Vector2(event.localPosition.dx, event.localPosition.dy),
            ),
      onPointerUp: game == null
          ? null
          : (event) => game!.handleViewportPointerUp(event.pointer),
      onPointerCancel: game == null
          ? null
          : (event) => game!.handleViewportPointerCancel(event.pointer),
      onPointerPanZoomStart: game == null
          ? null
          : (event) => game!.handleViewportPanZoomStart(
              Vector2(event.localPosition.dx, event.localPosition.dy),
            ),
      onPointerPanZoomUpdate: game == null
          ? null
          : (event) => game!.handleViewportPanZoomUpdate(
              panDelta: Vector2(event.localPanDelta.dx, event.localPanDelta.dy),
              scale: event.scale,
              focalPoint: Vector2(
                event.localPosition.dx,
                event.localPosition.dy,
              ),
            ),
      onPointerPanZoomEnd: game == null
          ? null
          : (_) => game!.handleViewportPanZoomEnd(),
      child: child,
    );

    if (onTap != null || game != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: onTap == null
            ? null
            : (details) => onTap!(
                Vector2(details.localPosition.dx, details.localPosition.dy),
              ),
        onLongPressStart: game == null
            ? null
            : (details) => game!.handleViewportLongPressStart(
                Vector2(details.localPosition.dx, details.localPosition.dy),
              ),
        onLongPressMoveUpdate: game == null
            ? null
            : (details) => game!.handleViewportLongPressMoveUpdate(
                Vector2(details.localPosition.dx, details.localPosition.dy),
              ),
        onLongPressUp: game == null
            ? null
            : () => game!.handleViewportLongPressUp(),
        onLongPressEnd: game == null
            ? null
            : (details) => game!.handleViewportLongPressEnd(
                Vector2(details.localPosition.dx, details.localPosition.dy),
              ),
        onLongPressCancel: game == null
            ? null
            : () => game!.handleViewportLongPressCancel(),
        child: result,
      );
    }

    if (game != null) {
      result = MouseRegion(
        onHover: (event) => game!.handleViewportPointerHover(
          Vector2(event.localPosition.dx, event.localPosition.dy),
        ),
        onExit: (_) => game!.handleViewportPointerExit(),
        child: result,
      );
    }

    return result;
  }
}
