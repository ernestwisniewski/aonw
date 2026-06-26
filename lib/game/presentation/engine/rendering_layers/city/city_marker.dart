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

  int get colorValue => _colorValue;

  set colorValue(int value) {
    if (_colorValue == value) return;
    _colorValue = value;
  }

  bool get reduceMotion => _reduceMotion;

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = _normalizeMarkerWorldScale(value);
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    scale = Vector2.all(next);
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _labelPulseElapsed = 0;
    _syncSelectionEffects();
  }

  void setWorldPosition(Vector2 value) {
    if (_samePosition(_restingPosition, value)) return;
    _restingPosition = value.clone();
    position = _restingPosition.clone();
  }

  String get name => _name;

  set name(String value) {
    if (_name == value) return;
    _name = value;
    _cachedNamePainter = null;
  }

  int get population => _population;

  set population(int value) {
    final next = math.max(1, value);
    if (_population == next) return;
    _population = next;
    _cachedPopulationPainter = null;
    // Population width affects nameMaxWidth, so the name layout has to be
    // recomputed when population digits change (1 → 10, 99 → 100, …).
    _cachedNamePainter = null;
  }

  bool get showLabel => _showLabel;

  set showLabel(bool value) {
    if (_showLabel == value) return;
    _showLabel = value;
  }

  bool get showHealthBar => _showHealthBar;

  set showHealthBar(bool value) {
    if (_showHealthBar == value) return;
    _showHealthBar = value;
  }

  bool get isCapital => _isCapital;

  set isCapital(bool value) {
    if (_isCapital == value) return;
    _isCapital = value;
    // Capital star reserves horizontal space, shrinking the name's max width.
    _cachedNamePainter = null;
  }

  double get healthFraction => _healthFraction;

  set healthFraction(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (_healthFraction == next) return;
    _healthFraction = next;
  }

  bool get hasStoredArtifact => _hasStoredArtifact;

  set hasStoredArtifact(bool value) {
    if (_hasStoredArtifact == value) return;
    _hasStoredArtifact = value;
  }

  bool get selected => _selected;

  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
    _labelPulseElapsed = 0;
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

  bool _paintCitySprite(Canvas canvas, Offset center) {
    final image = HexIconCache.imageFor(_citySpritePath);
    if (image == null) {
      _paintFallbackIcon(canvas, center);
      return false;
    }

    final row = _spriteRow;
    final column = _spriteColumn;
    final destination = _spriteBoundsFor(center);
    _drawCityFrame(
      canvas,
      image: image,
      row: row,
      column: column,
      destination: destination,
    );
    return true;
  }

  void _paintCityHealthBar(
    Canvas canvas, {
    required Offset center,
    required double statusTop,
    required Rect spriteBounds,
  }) {
    if (!paintsCityHealthBarForTesting) return;
    MarkerHealthBar.paint(
      canvas,
      center: center,
      top: statusTop,
      width: _healthBarWidthFor(spriteBounds),
      fraction: _healthFraction,
    );
  }

  void _paintStoredArtifactBadge(Canvas canvas, {required Rect spriteBounds}) {
    if (!_hasStoredArtifact) return;
    final center = Offset(
      spriteBounds.left - _artifactBadgeRadius - 2,
      spriteBounds.top + _artifactBadgeRadius + 4,
    );
    final outer = Rect.fromCircle(center: center, radius: _artifactBadgeRadius);
    final inner = outer.deflate(1.5);
    canvas
      ..drawCircle(
        center.translate(0, 1.2),
        _artifactBadgeRadius + 1.6,
        HudPaint.shadow(alpha: MapAlpha.regular),
      )
      ..drawOval(outer, HudPaint.fill(HudPalette.bg, alpha: MapAlpha.solid))
      ..drawOval(outer, HudPaint.stroke(HudPalette.goldLight, strokeWidth: 1.1))
      ..drawOval(inner, HudPaint.fill(HudPalette.gold, alpha: MapAlpha.opaque));
    GameIconRenderer.paintIcon(
      canvas,
      GameIcons.artifact,
      topLeft: Offset(center.dx - 4.8, center.dy - 4.8),
      size: 9.6,
      color: HudPalette.bg,
    );
  }

  void _drawCityFrame(
    Canvas canvas, {
    required ui.Image image,
    required int row,
    required int column,
    required Rect destination,
  }) {
    final baseSourceRect = CitySpriteCatalog.sourceRectFor(
      imageWidth: image.width,
      imageHeight: image.height,
      column: column,
      row: row,
    );
    BoardAssetCapPainter.paint(
      canvas: canvas,
      style: _capStyle,
      image: image,
      sourceRect: baseSourceRect,
      topRect: destination,
      imagePaint: Paint()..filterQuality = FilterQuality.medium,
      rimColor: effectiveRimColor,
      rimShadowColor: effectiveRimShadowColor,
    );
  }

  Color get effectiveRimColor =>
      _selected ? _selectedRimColor : _capStyle.rimColor;

  Color get effectiveRimShadowColor =>
      _selected ? _selectedRimShadowColor : _capStyle.rimShadowColor;

  void _paintFallbackIcon(Canvas canvas, Offset center) {
    const iconSize = 34.0;
    GameIconRenderer.paintIcon(
      canvas,
      GameIcons.cityFilled,
      topLeft: Offset(center.dx - iconSize / 2, center.dy - iconSize / 2),
      size: iconSize,
      color: HudPalette.goldLight,
    );
  }

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

  Rect _spriteBoundsFor(Offset center) {
    return _capStyle.topRectFor(center);
  }

  bool get _shouldPaintLabel => _showLabel || _selected;

  String get _labelName {
    final trimmed = _name.trim();
    return trimmed.isEmpty ? 'City' : trimmed;
  }

  Rect _labelRectFor({
    required Offset center,
    required double statusTop,
    required double width,
  }) {
    return Rect.fromLTWH(
      center.dx - width / 2,
      statusTop - _labelHeight - _labelTopGap - _cityLabelHealthBarOffset,
      width,
      _labelHeight,
    );
  }

  double get _cityLabelHealthBarOffset =>
      paintsCityHealthBarForTesting ? MarkerHealthBar.verticalFootprint : 0;

  void _paintCapitalStar(Canvas canvas, Offset center) {
    final path = _starPath(
      center: center,
      outerRadius: _labelCapitalStarRadius,
      innerRadius: _labelCapitalStarRadius * 0.47,
    );
    canvas
      ..drawPath(path, HudPaint.fill(HudPalette.goldLight))
      ..drawPath(
        path,
        HudPaint.stroke(
          Colors.black,
          alpha: MapAlpha.regular,
          strokeWidth: 0.55,
        ),
      );
  }

  Path _starPath({
    required Offset center,
    required double outerRadius,
    required double innerRadius,
  }) {
    final path = Path();
    const points = 5;
    for (var index = 0; index < points * 2; index++) {
      final radius = index.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + index * math.pi / points;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  int get _spriteRow => visualLevel.clamp(0, _frameRows - 1).toInt();

  int get _spriteColumn => technologyProfile.index.clamp(0, _frameColumns - 1);

  double _statusTopFor(Rect spriteBounds) => spriteBounds.top;

  void _syncSelectionEffects() {
    paint.colorFilter = null;
  }

  bool _samePosition(Vector2 a, Vector2 b) =>
      (a.x - b.x).abs() < 0.0001 && (a.y - b.y).abs() < 0.0001;

  double get healthFractionForTesting => _healthFraction;

  int get visualLevelForTesting => visualLevel;

  CitySpriteTechnologyProfile get technologyProfileForTesting =>
      technologyProfile;

  String get cityNameForTesting => _name;

  int get populationForTesting => _population;

  bool get isCapitalForTesting => _isCapital;

  bool get labelEnabledForTesting => _showLabel;

  bool get paintsCityLabelForTesting => _shouldPaintLabel;

  bool get paintsCityLabelOwnerDotForTesting => false;

  bool get showHealthBarForTesting => _showHealthBar;

  bool get paintsCityHealthBarForTesting =>
      _showHealthBar || _selected || _healthFraction < 0.995;

  bool get paintsStoredArtifactBadgeForTesting => _hasStoredArtifact;

  bool get paintsCityOwnerIndicatorForTesting => false;

  bool get paintsCityTokenForTesting => true;

  double get labelMaxWidthForTesting => _labelMaxWidth;

  double get labelOwnerDotRadiusForTesting => 0;

  double get labelOwnerDotGapForTesting => 0;

  bool get paintsCapitalStarForTesting => _shouldPaintLabel && _isCapital;

  double get labelCapitalStarRadiusForTesting => _labelCapitalStarRadius;

  bool get usesTypeIconBadgeForTesting => false;

  bool get hasSelectionTintForTesting => false;

  bool get hasSelectionRingForTesting => false;

  Rect get selectionRingRectForTesting => Rect.zero;

  double get selectionRingStrokeWidthForTesting => 0;

  Color get rimColorForTesting => effectiveRimColor;

  Color get rimShadowColorForTesting => effectiveRimShadowColor;

  int get colorValueForTesting => _colorValue;

  bool get hasAmbientFloatForTesting => false;

  Vector2 get restingPositionForTesting => _restingPosition.clone();

  bool get reduceMotionForTesting => _reduceMotion;

  double get markerWorldScaleForTesting => _markerWorldScale;

  int get frameIndexForTesting => _spriteColumn;

  Rect get typeIconRectForTesting => _typeIconRect;

  double get typeIconPulseForTesting => _typeIconPulse;

  Rect get cityLabelHitRectForTesting => _labelHitRectForTesting;

  Rect get cityHealthBarRectForTesting {
    if (!paintsCityHealthBarForTesting) return Rect.zero;
    final center = Offset(_width / 2, _height / 2);
    final spriteBounds = _spriteBoundsFor(center);
    return MarkerHealthBar.healthRect(
      center: center,
      top: _statusTopFor(spriteBounds),
      width: _healthBarWidthFor(spriteBounds),
    );
  }

  double get cityLabelPulseForTesting => _labelPulse;

  bool get paintsSelectedCityLabelBorderForTesting =>
      _selected && _shouldPaintLabel;

  Rect get _labelHitRectForTesting {
    if (!_shouldPaintLabel) return Rect.zero;
    final center = Offset(_width / 2, _height / 2);
    final spriteBounds = _spriteBoundsFor(center);
    return _labelRectFor(
      center: center,
      statusTop: _statusTopFor(spriteBounds),
      width: _labelMaxWidth,
    ).inflate(4);
  }

  double get _labelPulse {
    if (!_selected || _reduceMotion) return 0;
    final radians = (_labelPulseElapsed / _labelPulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }

  double get _typeIconPulse => 0;

  Rect get _typeIconRect => Rect.zero;

  Vector2 get markerSizeForTesting => size.clone();

  Rect get spriteBoundsForTesting =>
      _spriteBoundsFor(Offset(_width / 2, _height / 2));

  Path get spriteClipPathForTesting =>
      BoardAssetCapPainter.clipPathFor(spriteBoundsForTesting);

  BoardAssetCapStyle get boardCapStyleForTesting => _capStyle;

  double get sourceInsetForTesting => _sourceInset;

  double get statusTopForTesting {
    final center = Offset(_width / 2, _height / 2);
    return _statusTopFor(_spriteBoundsFor(center));
  }

  static double _healthBarWidthFor(Rect spriteBounds) =>
      math.max(34.0, math.min(62.0, spriteBounds.width * 0.68));

  static double _normalizeMarkerWorldScale(double value) =>
      value.isFinite ? value.clamp(1.0, 3.0).toDouble() : 1.0;
}
