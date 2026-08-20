import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/hex_selection/hex_selection_target.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

typedef HexSelectionTargetCallback = void Function(HexSelectionTarget target);

/// Map-space radial HUD used to disambiguate the selectable entities on one
/// hex. The terrain target remains at the center of the fan; contextual
/// targets alternate around it.
final class HexSelectionPaletteComponent extends PositionComponent
    with TapCallbacks {
  HexSelectionPaletteComponent({
    required List<HexSelectionTarget> targets,
    required this.directionAngle,
    required this.onSelected,
    required this.onCanceled,
  }) : targets = List.unmodifiable(targets),
       super(
         anchor: Anchor.center,
         priority: MapPriority.actionPalette + 20,
         size: Vector2.all(_extent),
       ) {
    assert(targets.isNotEmpty, 'A hex selection palette needs a target');
  }

  static const double _extent = 276;
  static const double _orbitRadius = 92;
  static const double _buttonRadius = 24;
  static const double _angleStep = math.pi / 6;

  static final Paint _connectorPaint = HudPaint.border(
    BorderEmphasis.regular,
    color: HudPalette.gold,
    alpha: 116,
    strokeWidth: 2,
  );
  static final Paint _haloPaint = HudPaint.fill(HudPalette.gold, alpha: 34);
  static final Paint _buttonPaint = HudPaint.fill(
    HudPalette.surfaceDeep,
    alpha: 244,
  );
  static final Paint _buttonBorderPaint = HudPaint.border(
    BorderEmphasis.active,
    color: HudPalette.gold,
    alpha: 238,
    strokeWidth: 2.5,
  );
  static final Paint _buttonShadowPaint = HudPaint.shadow(alpha: 104);

  final List<HexSelectionTarget> targets;
  final double directionAngle;
  final HexSelectionTargetCallback onSelected;
  final VoidCallback onCanceled;

  @visibleForTesting
  List<Rect> get targetRectsForTesting => _targetRects();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    _paintHexHalo(canvas, center);
    final rects = _targetRects();
    for (var index = 0; index < targets.length; index++) {
      final rect = rects[index];
      canvas.drawLine(
        center,
        Offset.lerp(center, rect.center, 0.72)!,
        _connectorPaint,
      );
    }
    for (var index = 0; index < targets.length; index++) {
      _paintTarget(canvas, targets[index], rects[index]);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    final local = Offset(event.localPosition.x, event.localPosition.y);
    final rects = _targetRects();
    for (var index = 0; index < rects.length; index++) {
      if (rects[index].contains(local)) {
        onSelected(targets[index]);
        return;
      }
    }
    onCanceled();
  }

  @visibleForTesting
  void selectForTesting(String key) {
    for (final target in targets) {
      if (target.key == key) {
        onSelected(target);
        return;
      }
    }
  }

  List<Rect> _targetRects() {
    final center = Offset(size.x / 2, size.y / 2);
    return [
      for (var index = 0; index < targets.length; index++)
        Rect.fromCircle(
          center:
              center +
              Offset.fromDirection(
                directionAngle + _angularOffset(index),
                _orbitRadius,
              ),
          radius: _buttonRadius,
        ),
    ];
  }

  double _angularOffset(int index) {
    if (index == 0) return 0;
    final distance = (index + 1) ~/ 2;
    return (index.isOdd ? -distance : distance) * _angleStep;
  }

  void _paintHexHalo(Canvas canvas, Offset center) {
    final bounds = Rect.fromCenter(center: center, width: 62, height: 48);
    final path = HexGeometry.projectedTopFacePath(
      bounds: bounds,
      perspectiveY: HexGrid.perspectiveY,
    );
    canvas
      ..drawPath(path, _haloPaint)
      ..drawPath(path, _buttonBorderPaint);
  }

  void _paintTarget(Canvas canvas, HexSelectionTarget target, Rect rect) {
    canvas
      ..drawCircle(
        rect.center + const Offset(0, 3),
        _buttonRadius + 2,
        _buttonShadowPaint,
      )
      ..drawCircle(rect.center, _buttonRadius, _buttonPaint)
      ..drawCircle(rect.center, _buttonRadius, _buttonBorderPaint);
    const iconSize = 25.0;
    GameIconRenderer.paintIcon(
      canvas,
      target.icon,
      topLeft: Offset(
        rect.center.dx - iconSize / 2,
        rect.center.dy - iconSize / 2,
      ),
      size: iconSize,
      color: GameUiTheme.goldLight,
    );
  }
}
