import 'dart:async';
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_cache.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_catalog.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FieldImprovementMarker extends PositionComponent with HasPaint<String> {
  FieldImprovementType _type;
  int _eraColumn;
  bool _selected;
  AnimationFrameAdjustmentCatalog _adjustments =
      const AnimationFrameAdjustmentCatalog.empty();

  static const BoardAssetCapStyle _capStyle = BoardAssetCapStyles.improvement;
  static const Color _selectedRimColor = Color(0xFFF1F4F8);
  static const Color _selectedRimShadowColor = Color(0xFF9AA2AE);
  static final double _width = _capStyle.componentSize.width;
  static final double _height = _capStyle.componentSize.height;
  static final double _spriteWidth = _capStyle.topSize.width;
  static final double _spriteHeight = _capStyle.topSize.height;
  static const double _sourceInset = FieldImprovementSpriteCatalog.sourceInset;

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
      unawaited(_loadSpriteFor(value));
    }
  }

  int get eraColumn => _eraColumn;

  set eraColumn(int value) {
    final next = _clampedEraColumn(value);
    if (_eraColumn == next) return;
    _eraColumn = next;
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
    await _loadSpriteFor(_type);
    _adjustments = await AnimationFrameAdjustmentCatalogCache.load();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final spritePath = FieldImprovementSpriteCatalog.assetPathFor(_type);
    final image = FieldImprovementSpriteCache.imageFor(spritePath);
    if (image == null) return;

    final baseSource = FieldImprovementSpriteCatalog.sourceRectFor(
      imageWidth: image.width,
      imageHeight: image.height,
      type: _type,
      eraColumn: _eraColumn,
    );
    final adjustment = _frameAdjustment();
    final source = adjustment.croppedSourceFor(baseSource);
    final baseDestination = _spriteBoundsFor(
      ui.Offset(_width / 2, _height / 2),
    );
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

    BoardAssetCapPainter.paint(
      canvas: canvas,
      style: _capStyle,
      image: image,
      sourceRect: source,
      topRect: destination,
      imagePaint: Paint()..filterQuality = FilterQuality.medium,
      rimColor: effectiveRimColor,
      rimShadowColor: effectiveRimShadowColor,
    );
  }

  AnimationFrameAdjustment _frameAdjustment() {
    return _adjustments.adjustmentFor(
      assetPath: FieldImprovementSpriteCatalog.assetPathFor(_type),
      animationId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
        type: _type,
        eraColumn: _eraColumn,
      ),
      frameIndex: 0,
    );
  }

  ui.Rect _spriteBoundsFor(ui.Offset center) {
    return _capStyle.topRectFor(center);
  }

  static int _clampedEraColumn(int value) {
    return value.clamp(0, FieldImprovementSpriteCatalog.columns - 1).toInt();
  }

  Future<void> _loadSpriteFor(FieldImprovementType type) {
    return FieldImprovementSpriteCache.load(
      FieldImprovementSpriteCatalog.assetPathFor(type),
    );
  }

  @visibleForTesting
  ui.Rect sourceRectForTesting(ui.Image image) {
    return FieldImprovementSpriteCatalog.sourceRectFor(
      imageWidth: image.width,
      imageHeight: image.height,
      type: _type,
      eraColumn: _eraColumn,
    );
  }

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
  String get assetPathForTesting =>
      FieldImprovementSpriteCatalog.assetPathFor(_type);

  @visibleForTesting
  bool get selectedForTesting => _selected;

  @visibleForTesting
  Color get rimColorForTesting => effectiveRimColor;

  @visibleForTesting
  Color get rimShadowColorForTesting => effectiveRimShadowColor;

  @visibleForTesting
  String get adjustmentIdForTesting =>
      FieldImprovementSpriteCatalog.adjustmentIdForVariant(
        type: _type,
        eraColumn: _eraColumn,
      );

  @visibleForTesting
  double get sourceInsetForTesting => _sourceInset;

  @visibleForTesting
  Path get spriteClipPathForTesting =>
      BoardAssetCapPainter.clipPathFor(spriteBoundsForTesting);

  @visibleForTesting
  BoardAssetCapStyle get boardCapStyleForTesting => _capStyle;
}
