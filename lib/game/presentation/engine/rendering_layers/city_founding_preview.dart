import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CityFoundingCandidateHex {
  final CityHex hex;
  final bool recommended;

  const CityFoundingCandidateHex({
    required this.hex,
    required this.recommended,
  });
}

class CityFoundingPreview extends Component {
  final CityFoundingDraft draft;
  final List<CityFoundingCandidateHex> candidateHexes;
  final List<CityHex> controlledHexes;
  final Color cityColor;

  CityFoundingPreview({
    required this.draft,
    required List<CityFoundingCandidateHex> candidateHexes,
    required List<CityHex> controlledHexes,
    required this.cityColor,
  }) : candidateHexes = List.unmodifiable(candidateHexes),
       controlledHexes = List.unmodifiable(controlledHexes);

  static const double _dashLength = 13.0;
  static const double _gapLength = 7.0;
  static const double _dashPattern = _dashLength + _gapLength;
  static const double _dashSpeed = 22.0;
  static const double _overlayRadiusScale = 0.92;

  double _dashPhase = 0;

  late final Paint _centerPaint = HudPaint.fill(
    cityColor,
    alpha: MapAlpha.soft,
  );
  late final Paint _centerBorderPaint = HudPaint.stroke(
    HudPalette.textBright,
    alpha: MapAlpha.solid,
    strokeWidth: MapStroke.regular,
  );
  late final Paint _controlledPaint = HudPaint.fill(
    cityColor,
    alpha: MapAlpha.regular,
  );
  late final Paint _controlledBorderPaint = HudPaint.stroke(
    HudPalette.textBright,
    alpha: MapAlpha.opaque,
    strokeWidth: MapStroke.bold,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  late final Paint _candidatePaint = HudPaint.fill(
    cityColor,
    alpha: MapAlpha.whisper,
  );
  late final Paint _candidateBorderPaint = HudPaint.stroke(
    cityColor,
    alpha: MapAlpha.solid,
    strokeWidth: MapStroke.regular,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  final Paint _recommendedPaint = HudPaint.fill(
    HudPalette.info,
    alpha: MapAlpha.soft,
  );
  final Paint _recommendedBorderPaint = HudPaint.stroke(
    HudPalette.info,
    alpha: MapAlpha.opaque,
    strokeWidth: MapStroke.bold,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  final Paint _recommendedGlowPaint = HudPaint.stroke(
    HudPalette.info,
    alpha: MapAlpha.soft,
    strokeWidth: MapStroke.glow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  final Paint _controlledGlowPaint = HudPaint.stroke(
    HudPalette.textBright,
    alpha: MapAlpha.faint,
    strokeWidth: MapStroke.glow,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  final Paint _labelBgPaint = HudPaint.fill(
    HudPalette.bg,
    alpha: MapAlpha.solid,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _dashPhase = (_dashPhase + dt * _dashSpeed) % _dashPattern;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final candidate in candidateHexes) {
      final path = _hexPath(candidate.hex);
      canvas.drawPath(
        path,
        candidate.recommended ? _recommendedPaint : _candidatePaint,
      );
      if (candidate.recommended) {
        _drawDashedPath(canvas, path, _recommendedGlowPaint);
        _drawDashedPath(canvas, path, _recommendedBorderPaint);
        _drawRecommendedBadge(canvas, _hexCenter(candidate.hex));
      } else {
        _drawDashedPath(canvas, path, _candidateBorderPaint);
      }
    }

    for (final hex in controlledHexes) {
      final path = _hexPath(hex);
      canvas.drawPath(path, _controlledPaint);
      _drawDashedPath(canvas, path, _controlledGlowPaint);
      _drawDashedPath(canvas, path, _controlledBorderPaint);
    }

    final centerPath = _hexPath(draft.center, radiusScale: 0.84);
    canvas
      ..drawPath(centerPath, _centerPaint)
      ..drawPath(centerPath, _centerBorderPaint);

    _drawLabel(canvas);
  }

  void _drawRecommendedBadge(Canvas canvas, Offset center) {
    MapIntentMarker.paintBadge(
      canvas,
      center,
      color: HudPalette.info,
      glow: HudPalette.info,
      glyph: MapIntentGlyph.city,
    );
  }

  void _drawLabel(Canvas canvas) {
    final label =
        '${draft.controlledHexes.length}/${CityFoundingDraft.requiredControlledHexes}';
    final paragraph = _createParagraph(label);
    const paddingX = 7.0;
    const paddingY = 4.0;
    final centerPoint = _hexCenter(draft.center);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerPoint.dx + 14,
        centerPoint.dy - 32,
        paragraph.maxIntrinsicWidth + paddingX * 2,
        paragraph.height + paddingY * 2,
      ),
      const Radius.circular(6),
    );

    canvas
      ..drawRRect(rect, _labelBgPaint)
      ..drawParagraph(
        paragraph,
        Offset(rect.left + paddingX, rect.top + paddingY),
      );
  }

  ui.Paragraph _createParagraph(String text) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              maxLines: 1,
            ),
          )
          ..pushStyle(ui.TextStyle(color: HudPalette.textBright))
          ..addText(text);
    return builder.build()..layout(const ui.ParagraphConstraints(width: 52));
  }

  Path _hexPath(CityHex hex, {double radiusScale = _overlayRadiusScale}) {
    final corners = _hexCorners(hex, radiusScale: radiusScale);
    final path = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (var i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    return path..close();
  }

  List<Offset> _hexCorners(CityHex hex, {required double radiusScale}) {
    final hexRadius = MapConfig.defaultConfig.hexRadius;
    final center = HexGeometry.tilePosition(
      col: hex.col,
      row: hex.row,
      hexRadius: hexRadius,
    );
    final topFaceCenter = Vector2(
      center.x,
      center.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius),
    );
    final corners = HexGeometry.topFaceCorners(
      center: topFaceCenter,
      radius: hexRadius * radiusScale,
    );
    return [
      for (final corner in corners)
        Offset(corner.x, corner.y * HexGrid.perspectiveY),
    ];
  }

  Offset _hexCenter(CityHex hex) {
    final corners = _hexCorners(hex, radiusScale: _overlayRadiusScale);
    final sum = corners.fold(Offset.zero, (total, point) => total + point);
    return Offset(sum.dx / corners.length, sum.dy / corners.length);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = -_dashPhase;
      while (distance < metric.length) {
        final start = math.max(0.0, distance);
        final end = math.min(metric.length, distance + _dashLength);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += _dashPattern;
      }
    }
  }
}
