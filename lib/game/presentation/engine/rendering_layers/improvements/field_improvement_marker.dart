import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw/shared/assets/sprite_frame_repository.dart';
import 'package:aonw/shared/assets/sprite_frames.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FieldImprovementMarker extends PositionComponent with HasPaint<String> {
  FieldImprovementType _type;
  int _eraColumn;
  bool _selected;
  AnimationFrameAdjustmentCatalog _adjustments =
      const AnimationFrameAdjustmentCatalog.empty();
  SpriteFrame? _spriteFrame;

  static const BoardAssetCapStyle _capStyle = BoardAssetCapStyles.improvement;
  static const Color _selectedRimColor = Color(0xFFF1F4F8);
  static const Color _selectedRimShadowColor = Color(0xFF9AA2AE);
  static const double _sizeScale = 0.70;
  static final double _hexWidth = MapConfig.defaultConfig.hexRadius * 2;
  static final double _hexHeight =
      MapConfig.defaultConfig.hexRadius * math.sqrt(3) * HexGrid.perspectiveY;
  static final double _width = _hexWidth * _sizeScale;
  static final double _height = _hexHeight * _sizeScale;
  static final double _spriteWidth = _capStyle.topSize.width;
  static final double _spriteHeight = _capStyle.topSize.height;
  static const double _sourceInset = 0;

  FieldImprovementMarker({
    required Vector2 position,
    required FieldImprovementType type,
    required int eraColumn,
    bool selected = false,
  }) : _type = type,
       _eraColumn = _clampedEraColumn(eraColumn),
       _selected = selected,
       super(
         position: position,
         size: Vector2(_width, _height),
         anchor: Anchor.center,
       ) {
    paint.filterQuality = FilterQuality.medium;
  }

  FieldImprovementType get type => _type;

  set type(FieldImprovementType value) {
    if (_type == value) return;
    _type = value;
    if (isLoaded) {
      unawaited(_loadSprite());
    }
  }

  int get eraColumn => _eraColumn;

  set eraColumn(int value) {
    final next = _clampedEraColumn(value);
    if (_eraColumn == next) return;
    _eraColumn = next;
    if (isLoaded) unawaited(_loadSprite());
  }

  bool get selected => _selected;

  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
  }

  Color get effectiveRimColor =>
      _selected ? _selectedRimColor : _capStyle.rimColor;

  Color get effectiveRimShadowColor =>
      _selected ? _selectedRimShadowColor : _capStyle.rimShadowColor;

  void setWorldPosition(Vector2 value) {
    if (position.x == value.x && position.y == value.y) return;
    position = value;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprite();
    _adjustments = await AnimationFrameAdjustmentCatalogCache.load();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = ui.Offset(_width / 2, _height / 2);
    _paintImprovementSprite(canvas, center);
  }

  bool _paintImprovementSprite(Canvas canvas, ui.Offset center) {
    final spriteBounds = _spriteBoundsFor(center);
    final spriteClipPath = _improvementMarkerClipPathFor(spriteBounds);
    final imagePaint = Paint()..filterQuality = FilterQuality.medium;

    canvas
      ..save()
      ..clipPath(spriteClipPath)
      ..drawRect(
        spriteBounds,
        HudPaint.fill(HudPalette.surface, alpha: MapAlpha.whisper),
      );

    final frame = _spriteFrame;
    if (frame == null) {
      _paintFallbackIcon(canvas, center);
      canvas.restore();
      _paintRim(canvas, spriteClipPath);
      return false;
    }

    final baseSource = ui.Offset.zero & frame.originalSize;
    final adjustment = _frameAdjustment();
    final source = adjustment.croppedSourceFor(baseSource);
    final baseDestination = spriteBounds;
    final offset = adjustment.scaledOffset(
      baseSize: ui.Size(_spriteWidth, _spriteHeight),
      targetSize: baseDestination.size,
    );
    final destination = adjustment
        .adjustedDestinationFor(
          baseSource: baseSource,
          baseDestination: baseDestination,
        )
        .shift(offset);

    final geometry = frame.geometryFor(
      logicalSource: source,
      destination: destination,
    );
    canvas
      ..drawImageRect(
        frame.image,
        geometry.source,
        geometry.destination,
        imagePaint,
      )
      ..restore();
    _paintRim(canvas, spriteClipPath);
    return true;
  }

  void _paintRim(Canvas canvas, Path spriteClipPath) {
    if (_selected) {
      canvas
        ..drawPath(
          spriteClipPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = MapStroke.glow + 2
            ..color = effectiveRimShadowColor.withAlpha(MapAlpha.regular)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.0),
        )
        ..drawPath(
          spriteClipPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = MapStroke.glow
            ..color = effectiveRimShadowColor.withAlpha(MapAlpha.soft)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.6),
        );
    }
    canvas.drawPath(
      spriteClipPath,
      HudPaint.stroke(
        effectiveRimColor,
        alpha: MapAlpha.solid,
        strokeWidth: MapStroke.thin,
      ),
    );
  }

  void _paintFallbackIcon(Canvas canvas, ui.Offset center) {
    const double iconSize = 30;
    GameIconRenderer.paintIcon(
      canvas,
      GameIcons.improvement,
      topLeft: ui.Offset(center.dx - iconSize / 2, center.dy - iconSize / 2),
      size: iconSize,
      color: HudPalette.goldLight,
    );
  }

  Path _improvementMarkerClipPathFor(ui.Rect spriteBounds) {
    return HexGeometry.projectedTopFacePath(
      bounds: spriteBounds,
      perspectiveY: HexGrid.perspectiveY,
    );
  }

  AnimationFrameAdjustment _frameAdjustment() {
    return _adjustments.adjustmentFor(
      sequenceId: FieldImprovementSpriteCatalog.sequenceIdFor(
        type: _type,
        eraColumn: _eraColumn,
      ),
      frameIndex: 0,
    );
  }

  ui.Rect _spriteBoundsFor(ui.Offset center) {
    return ui.Rect.fromCenter(center: center, width: _width, height: _height);
  }

  static int _clampedEraColumn(int value) {
    return value.clamp(0, FieldImprovementSpriteCatalog.columns - 1).toInt();
  }

  Future<void> _loadSprite() async {
    final id = FieldImprovementSpriteCatalog.frameIdFor(
      type: _type,
      eraColumn: _eraColumn,
    );
    final frame = await SpriteFrames.load(id);
    final currentId = FieldImprovementSpriteCatalog.frameIdFor(
      type: _type,
      eraColumn: _eraColumn,
    );
    if (id == currentId) _spriteFrame = frame;
  }

  @visibleForTesting
  ui.Rect get sourceRectForTesting => _spriteFrame?.source ?? ui.Rect.zero;

  @visibleForTesting
  ui.Rect get spriteBoundsForTesting =>
      _spriteBoundsFor(ui.Offset(_width / 2, _height / 2));

  @visibleForTesting
  Vector2 get markerSizeForTesting => size.clone();

  @visibleForTesting
  FieldImprovementType get improvementTypeForTesting => _type;

  @visibleForTesting
  int get eraColumnForTesting => _eraColumn;

  @visibleForTesting
  SpriteFrameId get frameIdForTesting =>
      FieldImprovementSpriteCatalog.frameIdFor(
        type: _type,
        eraColumn: _eraColumn,
      );

  @visibleForTesting
  bool get selectedForTesting => _selected;

  @visibleForTesting
  Color get rimColorForTesting => effectiveRimColor;

  @visibleForTesting
  Color get rimShadowColorForTesting => effectiveRimShadowColor;

  @visibleForTesting
  SpriteSequenceId get adjustmentIdForTesting =>
      FieldImprovementSpriteCatalog.sequenceIdFor(
        type: _type,
        eraColumn: _eraColumn,
      );

  @visibleForTesting
  double get sourceInsetForTesting => _sourceInset;

  @visibleForTesting
  Path get spriteClipPathForTesting =>
      _improvementMarkerClipPathFor(spriteBoundsForTesting);

  @visibleForTesting
  BoardAssetCapStyle get boardCapStyleForTesting => _capStyle;
}
