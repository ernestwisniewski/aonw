import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ThreatOverlayHex {
  final CityHex hex;
  final int threatCount;
  final bool selectedUnitTile;

  const ThreatOverlayHex({
    required this.hex,
    required this.threatCount,
    this.selectedUnitTile = false,
  });
}

class ThreatOverlay extends Component {
  List<ThreatOverlayHex> _hexes;
  bool _dimmed;

  ThreatOverlay({required List<ThreatOverlayHex> hexes, bool dimmed = false})
    : _hexes = List.unmodifiable(hexes),
      _dimmed = dimmed;

  List<ThreatOverlayHex> get hexes => _hexes;

  bool get dimmed => _dimmed;

  void updateHexes({
    required List<ThreatOverlayHex> hexes,
    required bool dimmed,
  }) {
    _hexes = List.unmodifiable(hexes);
    _dimmed = dimmed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final hex in hexes) {
      final corners = _hexCorners(hex.hex);
      final path = Path()..moveTo(corners.first.dx, corners.first.dy);
      for (var i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();

      final selected = hex.selectedUnitTile;
      final highThreat = hex.threatCount >= 3;
      final color = highThreat ? HudPalette.danger : HudPalette.warning;
      final fillAlpha = fillAlphaForTesting(hex);
      final glowAlpha = glowAlphaForTesting(hex);
      final strokeAlpha = strokeAlphaForTesting(hex);

      if (!selected) {
        canvas.drawPath(path, HudPaint.fill(color, alpha: fillAlpha));
      }

      canvas
        ..drawPath(
          path,
          HudPaint.stroke(
            color,
            alpha: glowAlpha,
            strokeWidth: selected
                ? MapStroke.glow
                : glowStrokeWidthForTesting(hex),
            strokeJoin: StrokeJoin.round,
          ),
        )
        ..drawPath(
          path,
          HudPaint.stroke(
            color,
            alpha: strokeAlpha,
            strokeWidth: strokeWidthForTesting(hex),
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),
        );
    }
  }

  bool get dimmedForTesting => dimmed;

  int fillAlphaForTesting(ThreatOverlayHex hex) {
    final highThreat = hex.threatCount >= 3;
    return _visibleAlpha(highThreat ? MapAlpha.soft : MapAlpha.faint);
  }

  int glowAlphaForTesting(ThreatOverlayHex hex) {
    final highThreat = hex.threatCount >= 3;
    return _visibleAlpha(highThreat ? MapAlpha.regular : MapAlpha.soft);
  }

  int strokeAlphaForTesting(ThreatOverlayHex hex) {
    final highThreat = hex.threatCount >= 3;
    return _visibleAlpha(highThreat ? MapAlpha.solid : MapAlpha.strong);
  }

  double glowStrokeWidthForTesting(ThreatOverlayHex hex) {
    if (hex.selectedUnitTile) return MapStroke.glow;
    return hex.threatCount >= 3 ? MapStroke.bold : MapStroke.regular;
  }

  double strokeWidthForTesting(ThreatOverlayHex hex) {
    if (hex.selectedUnitTile) return MapStroke.bold;
    return hex.threatCount >= 3 ? MapStroke.regular : MapStroke.thin;
  }

  int _visibleAlpha(int alpha) {
    if (!dimmed) return alpha;
    return math.min(alpha, MapAlpha.faint);
  }

  List<Offset> _hexCorners(CityHex hex) {
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
      radius: hexRadius * 0.94,
    );
    return [for (final corner in corners) Offset(corner.x, corner.y)];
  }
}
