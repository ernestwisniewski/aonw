import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_sprite_catalog.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/marker_health_bar.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

part 'city_marker_label_support.dart';
part 'city_marker_mutable_state.dart';
part 'city_marker_sprite_rendering.dart';
part 'city_marker_test_view.dart';

class CityMarker extends PositionComponent with HasPaint<String>, TapCallbacks {
  int _colorValue;
  VoidCallback? onTap;
  bool _selected;
  String _name;
  int _population;
  bool _showLabel;
  bool _showHealthBar;
  bool _isCapital;
  int visualLevel;
  CitySpriteTechnologyProfile technologyProfile;
  double _healthFraction;
  bool _hasStoredArtifact;
  bool _reduceMotion;
  Vector2 _restingPosition;
  double _markerWorldScale;
  // Reused across frames; rebuilt only when the label's source data changes.
  // TextPainter.layout() is the dominant CPU cost in render() for cities.
  TextPainter? _cachedPopulationPainter;
  TextPainter? _cachedNamePainter;
  double? _cachedNameMaxWidth;

  static const BoardAssetCapStyle _capStyle = BoardAssetCapStyles.city;
  static const Color _selectedRimColor = Color(0xFFF2DFA4);
  static const Color _selectedRimShadowColor = Color(0xFFA47C35);
  static const String _citySpritePath = CitySpriteCatalog.assetPath;
  static final double _width = _capStyle.componentSize.width;
  static final double _height = _capStyle.componentSize.height;
  static const int _frameColumns = CitySpriteCatalog.technologyProfileCount;
  static const int _frameRows = CitySpriteCatalog.visualLevelCount;
  static const double _sourceInset = CitySpriteCatalog.sourceInset;
  static const double _labelMaxWidth = 116;
  static const double _labelHeight = 18;
  static const double _labelGap = 5;
  static const double _labelHorizontalPadding = 6;
  static const double _labelTopGap = 4;
  static const double _labelCapitalStarRadius = 4.2;
  static const double _labelCapitalStarGap = 4.0;
  static const double _labelPulsePeriod = 1.15;
  static const double _artifactBadgeRadius = 7.0;
  double _labelPulseElapsed = 0;

  CityMarker({
    required Vector2 position,
    required int colorValue,
    this.onTap,
    String name = '',
    int population = 1,
    bool showLabel = true,
    bool showHealthBar = true,
    bool isCapital = false,
    bool selected = false,
    this.visualLevel = 0,
    this.technologyProfile = CitySpriteTechnologyProfile.growthCivic,
    double healthFraction = 1.0,
    bool hasStoredArtifact = false,
    double markerWorldScale = 1.0,
    bool reduceMotion = false,
  }) : _colorValue = colorValue,
       _name = name,
       _population = math.max(1, population),
       _showLabel = showLabel,
       _showHealthBar = showHealthBar,
       _isCapital = isCapital,
       _selected = selected,
       _healthFraction = healthFraction.clamp(0.0, 1.0).toDouble(),
       _hasStoredArtifact = hasStoredArtifact,
       _reduceMotion = reduceMotion,
       _restingPosition = position.clone(),
       _markerWorldScale = _normalizeMarkerWorldScale(markerWorldScale),
       super(
         position: position,
         size: Vector2(_width, _height),
         anchor: Anchor.center,
         priority: 18,
       ) {
    paint.filterQuality = FilterQuality.medium;
    scale = Vector2.all(_markerWorldScale);
    _syncSelectionEffects();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await HexIconCache.load(_citySpritePath);
    _syncSelectionEffects();
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_reduceMotion || !_selected || !_shouldPaintLabel) {
      if (_labelPulseElapsed != 0) {
        _labelPulseElapsed = 0;
      }
      return;
    }
    _labelPulseElapsed = (_labelPulseElapsed + dt) % _labelPulsePeriod;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final offset = Offset(point.x, point.y);
    if (BoardAssetCapPainter.clipPathFor(
      spriteBoundsForTesting,
    ).contains(offset)) {
      return true;
    }
    return _labelHitRectForTesting.contains(offset);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final playerColor = Color(_colorValue);
    final center = Offset(_width / 2, _height / 2);

    final spriteBounds = _spriteBoundsFor(center);
    final statusTop = _statusTopFor(spriteBounds);

    _paintCitySprite(canvas, center);
    _paintCityHealthBar(
      canvas,
      center: center,
      statusTop: statusTop,
      spriteBounds: spriteBounds,
    );
    _paintStoredArtifactBadge(canvas, spriteBounds: spriteBounds);
    _paintCityLabel(
      canvas,
      center: center,
      statusTop: statusTop,
      playerColor: playerColor,
    );
  }

  Color get effectiveRimColor =>
      _selected ? _selectedRimColor : _capStyle.rimColor;

  Color get effectiveRimShadowColor =>
      _selected ? _selectedRimShadowColor : _capStyle.rimShadowColor;

  void _paintCityLabel(
    Canvas canvas, {
    required Offset center,
    required double statusTop,
    required Color playerColor,
  }) {
    if (!_shouldPaintLabel) return;

    final populationPainter = _cachedPopulationPainter ??= TextPainter(
      text: TextSpan(
        text: _population.toString(),
        style: const TextStyle(
          color: HudPalette.bg,
          fontFamily: 'Lato',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          fontFeatures: GameUiTheme.tabularFigures,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final populationBadgeWidth = math.max(18.0, populationPainter.width + 8);
    final capitalStarWidth = _isCapital
        ? _labelCapitalStarRadius * 2 + _labelCapitalStarGap
        : 0.0;
    final nameMaxWidth =
        _labelMaxWidth -
        _labelHorizontalPadding * 2 -
        capitalStarWidth -
        populationBadgeWidth -
        _labelGap;
    if (_cachedNamePainter == null || _cachedNameMaxWidth != nameMaxWidth) {
      _cachedNamePainter = TextPainter(
        text: TextSpan(
          text: _labelName,
          style: const TextStyle(
            color: HudPalette.goldLight,
            fontFamily: 'Cinzel',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: nameMaxWidth);
      _cachedNameMaxWidth = nameMaxWidth;
    }
    final namePainter = _cachedNamePainter!;

    final labelWidth = math.min(
      _labelMaxWidth,
      _labelHorizontalPadding * 2 +
          capitalStarWidth +
          namePainter.width +
          _labelGap +
          populationBadgeWidth,
    );
    final labelRect = _labelRectFor(
      center: center,
      statusTop: statusTop,
      width: labelWidth,
    );
    const radius = Radius.circular(_labelHeight / 2);
    final pulse = _labelPulse;

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(labelRect.shift(const Offset(0, 1.5)), radius),
        HudPaint.shadow(alpha: MapAlpha.regular),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(labelRect, radius),
        HudPaint.fill(HudPalette.bg, alpha: MapAlpha.solid),
      );
    if (_selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          labelRect.inflate(1.3 + pulse),
          Radius.circular(_labelHeight / 2 + 1.3 + pulse),
        ),
        HudPaint.stroke(
          playerColor,
          alpha: MapAlpha.whisper + (MapAlpha.faint * pulse).round(),
          strokeWidth: 1.0 + pulse * 0.55,
        ),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect.deflate(0.5), radius),
      HudPaint.stroke(
        _selected ? HudPalette.textBright : playerColor,
        alpha: _selected
            ? MapAlpha.solid + (27 * pulse).round()
            : MapAlpha.solid,
        strokeWidth: _selected ? 1.05 + pulse * 0.35 : 1,
      ),
    );

    final populationRect = Rect.fromLTWH(
      labelRect.right - _labelHorizontalPadding - populationBadgeWidth,
      labelRect.top + 3,
      populationBadgeWidth,
      _labelHeight - 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(populationRect, const Radius.circular(6)),
      HudPaint.fill(playerColor, alpha: MapAlpha.opaque),
    );

    final nameLeft =
        labelRect.left + _labelHorizontalPadding + capitalStarWidth;
    if (_isCapital) {
      final starCenter = Offset(
        labelRect.left + _labelHorizontalPadding + _labelCapitalStarRadius,
        labelRect.center.dy,
      );
      _paintCapitalStar(canvas, starCenter);
    }

    namePainter.paint(
      canvas,
      Offset(nameLeft, labelRect.top + (_labelHeight - namePainter.height) / 2),
    );
    populationPainter.paint(
      canvas,
      Offset(
        populationRect.left +
            (populationRect.width - populationPainter.width) / 2,
        populationRect.top +
            (populationRect.height - populationPainter.height) / 2,
      ),
    );
  }
}
