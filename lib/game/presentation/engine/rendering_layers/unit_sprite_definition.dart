import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/shared/assets/sprite_atlas_geometry.dart';
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
  final double width;
  final double height;

  const UnitSpriteSize({required this.width, required this.height});
}

class UnitSpriteActionDefinition {
  final int row;
  final double frameDuration;
  final bool loops;
  final int frameCount;

  const UnitSpriteActionDefinition({
    required this.row,
    required this.frameDuration,
    this.loops = true,
    this.frameCount = 6,
  });
}

class UnitSpriteDefinition {
  final String assetPath;
  final int columns;
  final int rows;
  final UnitSpriteSize normalSize;
  final UnitSpriteSize smallSize;
  final UnitSpriteDirection defaultDirection;
  final Map<UnitSpriteAction, UnitSpriteActionDefinition> actions;
  final double sourceInset;

  const UnitSpriteDefinition({
    required this.assetPath,
    this.columns = 6,
    this.rows = 4,
    required this.normalSize,
    required this.smallSize,
    required this.actions,
    this.defaultDirection = UnitSpriteDirection.se,
    this.sourceInset = 2.0,
  });

  UnitSpriteActionDefinition actionDefinition(UnitSpriteAction action) {
    return actions[action] ?? actions[UnitSpriteAction.idle]!;
  }

  UnitSpriteAction supportedAction(UnitSpriteAction action) {
    return actions.containsKey(action) ? action : UnitSpriteAction.idle;
  }

  UnitSpriteSize sizeFor({required bool onCity}) =>
      onCity ? smallSize : normalSize;

  Vector2 sourcePositionFor({
    required Vector2 imageSize,
    required UnitSpriteActionDefinition action,
    required int column,
  }) {
    final source = sourceRectFor(
      imageSize: imageSize,
      action: action,
      column: column,
    );
    return Vector2(source.left, source.top);
  }

  Vector2 sourceSizeFor(Vector2 imageSize) {
    final source = SpriteAtlasGeometry.sourceRectFor(
      imageWidth: imageSize.x.round(),
      imageHeight: imageSize.y.round(),
      columns: columns,
      rows: rows,
      column: 0,
      row: 0,
      sourceInset: sourceInset,
    );
    return Vector2(source.width, source.height);
  }

  ui.Rect sourceRectFor({
    required Vector2 imageSize,
    required UnitSpriteActionDefinition action,
    required int column,
  }) {
    return SpriteAtlasGeometry.sourceRectFor(
      imageWidth: imageSize.x.round(),
      imageHeight: imageSize.y.round(),
      columns: columns,
      rows: rows,
      column: column,
      row: action.row,
      sourceInset: sourceInset,
    );
  }

  double sourceFrameWidthFor(Vector2 imageSize) => imageSize.x / columns;

  double sourceFrameHeightFor(Vector2 imageSize) => imageSize.y / rows;
}
