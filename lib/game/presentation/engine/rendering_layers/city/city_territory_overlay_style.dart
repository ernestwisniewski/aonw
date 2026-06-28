part of 'city_territory_overlay.dart';

class _TerritoryRenderStyleKey {
  const _TerritoryRenderStyleKey(this.color, this.strategicView);

  final Color color;
  final bool strategicView;

  @override
  bool operator ==(Object other) {
    return other is _TerritoryRenderStyleKey &&
        other.color == color &&
        other.strategicView == strategicView;
  }

  @override
  int get hashCode => Object.hash(color, strategicView);
}

class _TerritoryRenderStyle {
  _TerritoryRenderStyle(this.color, {required this.strategicView});

  final Color color;
  final bool strategicView;

  late final Color fillColor = strategicView
      ? Color.lerp(color, HudPalette.goldLight, 0.18)!
      : color;
  late final Color insetWashColor = Color.lerp(
    fillColor,
    HudPalette.goldLight,
    0.12,
  )!;
  late final Color edgeBandColor = Color.lerp(color, HudPalette.copper, 0.18)!;
  late final Color strategicCenterColor = Color.lerp(
    color,
    HudPalette.goldLight,
    0.22,
  )!;
  late final Color _borderShadowColor = Color.lerp(color, HudPalette.bg, 0.72)!;
  late final Color _solidBorderColor = Color.lerp(
    color,
    HudPalette.bg,
    strategicView ? _strategicBorderPlayerDarken : _solidBorderPlayerDarken,
  )!;
  late final Color _atlasInkBorderColor = Color.lerp(
    HudPalette.bg,
    color,
    0.1,
  )!;
  late final Color _borderGlowColor = Color.lerp(
    color,
    HudPalette.goldLight,
    0.34,
  )!;
  late final Color _innerBorderHighlightColor = Color.lerp(
    color,
    HudPalette.textBright,
    0.26,
  )!;
  late final Color _selectedBorderGlowColor = Color.lerp(
    color,
    HudPalette.goldLight,
    0.18,
  )!;
  late final Color _selectedBorderHighlightColor = Color.lerp(
    color,
    HudPalette.textBright,
    0.34,
  )!;

  late final Paint outerBorderPaint = HudPaint.stroke(
    _borderShadowColor,
    alpha: strategicView ? MapAlpha.strong : MapAlpha.solid,
    strokeWidth: strategicView ? _strategicOuterBorderWidth : _outerBorderWidth,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint solidBorderPaint = HudPaint.stroke(
    _solidBorderColor,
    alpha: strategicView ? MapAlpha.opaque : MapAlpha.full,
    strokeWidth: strategicView ? _strategicSolidBorderWidth : _solidBorderWidth,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint atlasInkBorderPaint = HudPaint.stroke(
    _atlasInkBorderColor,
    alpha: strategicView ? MapAlpha.regular : _atlasInkBorderAlpha,
    strokeWidth: strategicView ? MapStroke.hairline : _atlasInkBorderWidth,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint borderGlowPaint = HudPaint.stroke(
    _borderGlowColor,
    alpha: MapAlpha.regular,
    strokeWidth: MapStroke.glow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  late final Paint strategicCenterGlowPaint = HudPaint.stroke(
    strategicCenterColor,
    alpha: MapAlpha.strong,
    strokeWidth: MapStroke.glow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  late final Paint strategicCenterInnerPaint = HudPaint.stroke(
    strategicCenterColor,
    alpha: MapAlpha.solid,
    strokeWidth: MapStroke.hairline,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );

  late final Paint _insetWashPaint = _createInsetWashPaint(
    selected: false,
    blurred: false,
  );
  late final Paint _insetWashBlurPaint = _createInsetWashPaint(
    selected: false,
    blurred: true,
  );
  late final Paint _selectedInsetWashPaint = _createInsetWashPaint(
    selected: true,
    blurred: false,
  );
  late final Paint _selectedInsetWashBlurPaint = _createInsetWashPaint(
    selected: true,
    blurred: true,
  );

  Paint insetWashPaint({required bool selected, required bool blurred}) {
    if (selected) {
      return blurred ? _selectedInsetWashBlurPaint : _selectedInsetWashPaint;
    }
    return blurred ? _insetWashBlurPaint : _insetWashPaint;
  }

  Paint innerBorderHighlightPaint(int alpha) {
    return HudPaint.stroke(
      _innerBorderHighlightColor,
      alpha: alpha,
      strokeWidth: strategicView
          ? _strategicInnerBorderWidth
          : _innerBorderWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  Paint selectedBorderGlowPaint(int alpha) {
    return HudPaint.stroke(
      _selectedBorderGlowColor,
      alpha: alpha,
      strokeWidth: _selectedBorderGlowWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.6);
  }

  Paint selectedBorderHighlightPaint(int alpha) {
    return HudPaint.stroke(
      _selectedBorderHighlightColor,
      alpha: alpha,
      strokeWidth: _selectedBorderHighlightWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
  }

  Paint _createInsetWashPaint({required bool selected, required bool blurred}) {
    final paint = HudPaint.stroke(
      insetWashColor,
      alpha: selected
          ? _selectedTerritoryInsetWashAlpha
          : _territoryInsetWashAlpha,
      strokeWidth: selected
          ? _selectedTerritoryInsetWashWidth
          : _territoryInsetWashWidth,
      strokeCap: StrokeCap.round,
      strokeJoin: StrokeJoin.round,
    );
    if (blurred) {
      paint.maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        _territoryInsetWashBlur,
      );
    }
    return paint;
  }
}

final Paint _strategicCenterFillPaint = HudPaint.fill(
  HudPalette.bg,
  alpha: MapAlpha.regular,
);
final Paint _strategicCenterBorderPaint = HudPaint.stroke(
  HudPalette.goldLight,
  alpha: MapAlpha.opaque,
  strokeWidth: MapStroke.regular,
  strokeCap: StrokeCap.round,
  strokeJoin: StrokeJoin.round,
);
final Paint _mapDimmingPaint = HudPaint.fill(
  HudPalette.bg,
  alpha: MapAlpha.regular,
);
