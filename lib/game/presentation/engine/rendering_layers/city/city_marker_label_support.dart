part of 'city_marker.dart';

extension _CityMarkerLabelSupport on CityMarker {
  Rect _spriteBoundsFor(Offset center) => Rect.fromCenter(
    center: center,
    width: CityMarker._width,
    height: CityMarker._height,
  );

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
      statusTop -
          CityMarker._labelHeight -
          CityMarker._labelTopGap -
          _cityLabelHealthBarOffset,
      width,
      CityMarker._labelHeight,
    );
  }

  double get _cityLabelHealthBarOffset =>
      _paintsCityHealthBar ? MarkerHealthBar.verticalFootprint : 0;

  void _paintCapitalStar(Canvas canvas, Offset center) {
    final path = _starPath(
      center: center,
      outerRadius: CityMarker._labelCapitalStarRadius,
      innerRadius: CityMarker._labelCapitalStarRadius * 0.47,
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

  int get _spriteColumn =>
      _technologyProfile.index.clamp(0, CityMarker._frameColumns - 1);

  double _statusTopFor(Rect spriteBounds) => spriteBounds.top;

  void _syncSelectionEffects() {
    paint.colorFilter = null;
  }

  bool get _paintsCityHealthBar =>
      _showHealthBar || _selected || _healthFraction < 0.995;

  Rect get _labelHitRect {
    if (!_shouldPaintLabel) return Rect.zero;
    final center = Offset(CityMarker._width / 2, CityMarker._height / 2);
    final spriteBounds = _spriteBoundsFor(center);
    return _labelRectFor(
      center: center,
      statusTop: _statusTopFor(spriteBounds),
      width: CityMarker._labelMaxWidth,
    ).inflate(4);
  }

  double get _labelPulse {
    if (!_selected || _reduceMotion) return 0;
    final radians =
        (_labelPulseElapsed / CityMarker._labelPulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }

  double get _typeIconPulse => 0;

  Rect get _typeIconRect => Rect.zero;
}

double _healthBarWidthFor(Rect spriteBounds) =>
    math.max(34.0, math.min(62.0, spriteBounds.width * 0.68));
