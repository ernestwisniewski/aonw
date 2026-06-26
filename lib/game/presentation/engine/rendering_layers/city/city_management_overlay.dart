import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_yield_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_icon_badge.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum CityManagementOverlayHexKind {
  growthCandidate,
  growthRecommended,
  workerImprovementExisting,
  workerImprovementMissingInCity,
  workedManual,
  workedAuto,
  workedIdle,
}

class CityManagementOverlayHex {
  final CityHex hex;
  final CityManagementOverlayHexKind kind;
  final String label;
  final TileYield? tileYield;

  const CityManagementOverlayHex({
    required this.hex,
    required this.kind,
    required this.label,
    this.tileYield,
  });
}

class CityManagementOverlay extends Component {
  List<CityManagementOverlayHex> _hexes;
  bool _dimmed;

  CityManagementOverlay({
    required List<CityManagementOverlayHex> hexes,
    bool dimmed = false,
  }) : _hexes = List.unmodifiable(hexes),
       _dimmed = dimmed;

  List<CityManagementOverlayHex> get hexes => _hexes;

  bool get dimmed => _dimmed;

  void updateHexes({
    required List<CityManagementOverlayHex> hexes,
    required bool dimmed,
  }) {
    _hexes = List.unmodifiable(hexes);
    _dimmed = dimmed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final overlayHex in hexes) {
      final color = _colorFor(overlayHex.kind);
      final corners = _hexCorners(overlayHex.hex);
      final path = Path()..moveTo(corners.first.dx, corners.first.dy);
      for (var i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();

      canvas.drawPath(
        path,
        HudPaint.fill(color, alpha: fillAlphaForTesting(overlayHex.kind)),
      );
      final stroke = HudPaint.stroke(
        color,
        alpha: _visibleAlpha(MapAlpha.opaque),
        strokeWidth: strokeWidthForTesting(overlayHex.kind),
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      );
      canvas.drawPath(path, stroke);

      if (dimmed) continue;
      if (overlayHex.tileYield == null) {
        _drawLabel(canvas, overlayHex, color);
      } else {
        _drawYieldBadges(canvas, overlayHex, color);
      }
    }
  }

  void _drawYieldBadges(
    Canvas canvas,
    CityManagementOverlayHex overlayHex,
    Color outlineColor,
  ) {
    final rows = _badgeRows(_yieldBadges(overlayHex.tileYield!));
    const badgeHeight = 15.0;
    const gap = 2.5;
    const rowGap = 2.0;
    final rowWidths = [
      for (final row in rows)
        row.fold<double>(0, (sum, badge) => sum + _badgeWidthFor(badge)) +
            gap * (row.length - 1),
    ];
    final totalHeight = rows.length * badgeHeight + rowGap * (rows.length - 1);
    final center = _hexCenter(overlayHex.hex);
    var top = center.dy - totalHeight / 2 - 3;

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      var left = center.dx - rowWidths[rowIndex] / 2;
      for (final badge in row) {
        final width = _badgeWidthFor(badge);
        _drawYieldBadgeChip(
          canvas,
          Rect.fromLTWH(left, top, width, badgeHeight),
          badge,
          outlineColor,
        );
        left += width + gap;
      }
      top += badgeHeight + rowGap;
    }
  }

  List<List<_YieldBadge>> _badgeRows(List<_YieldBadge> badges) {
    if (badges.length <= 2) return [badges];
    return [
      badges.take(2).toList(growable: false),
      badges.skip(2).toList(growable: false),
    ];
  }

  double _badgeWidthFor(_YieldBadge badge) =>
      badge.value.length > 1 ? 29.0 : 24.0;

  void _drawYieldBadgeChip(
    Canvas canvas,
    Rect rect,
    _YieldBadge badge,
    Color outlineColor,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final accent = Color.lerp(outlineColor, badge.color, 0.42)!;
    MapIconBadgePainter.paintChip(canvas, rrect, accent: accent);

    _drawPotentialIcon(
      canvas,
      badge.icon,
      center: Offset(rect.left + 8.2, rect.center.dy + 0.1),
      size: GameIconSize.tiny,
      color: HudPaint.color(HudPalette.goldLight, alpha: MapAlpha.opaque),
    );

    final paragraph = _createBadgeValueParagraph(badge.value);
    canvas.drawParagraph(
      paragraph,
      Offset(
        rect.right - 4 - paragraph.maxIntrinsicWidth,
        rect.top + (rect.height - paragraph.height) / 2 - 0.5,
      ),
    );
  }

  void _drawPotentialIcon(
    Canvas canvas,
    GameIconData icon, {
    required Offset center,
    required double size,
    required Color color,
  }) {
    GameIconRenderer.paintIcon(
      canvas,
      icon,
      topLeft: Offset(center.dx - size / 2, center.dy - size / 2),
      size: size,
      color: color,
    );
  }

  void _drawLabel(
    Canvas canvas,
    CityManagementOverlayHex overlayHex,
    Color color,
  ) {
    final center = _hexCenter(overlayHex.hex);
    final paragraph = _createParagraph(overlayHex.label);
    const paddingX = 6.0;
    const paddingY = 3.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 3),
        width: paragraph.maxIntrinsicWidth + paddingX * 2,
        height: paragraph.height + paddingY * 2,
      ),
      const Radius.circular(6),
    );

    canvas
      ..drawRRect(rect, HudPaint.fill(HudPalette.bg, alpha: MapAlpha.solid))
      ..drawRRect(
        rect,
        HudPaint.stroke(
          color,
          alpha: MapAlpha.solid,
          strokeWidth: MapStroke.thin,
        ),
      )
      ..drawParagraph(
        paragraph,
        Offset(rect.left + paddingX, rect.top + paddingY),
      );
  }

  ui.Paragraph _createParagraph(String text) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          )
          ..pushStyle(ui.TextStyle(color: HudPalette.textBright))
          ..addText(text);
    return builder.build()..layout(const ui.ParagraphConstraints(width: 72));
  }

  ui.Paragraph _createBadgeValueParagraph(String text) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          )
          ..pushStyle(ui.TextStyle(color: HudPalette.textBright))
          ..addText(text);
    return builder.build()..layout(const ui.ParagraphConstraints(width: 14));
  }

  List<_YieldBadge> _yieldBadges(TileYield yield) {
    final badges = [
      for (final item in SelectionYieldItem.fromYield(yield))
        if (item.value > 0)
          _YieldBadge(
            value: '${item.value}',
            icon: item.icon,
            color: item.color,
          ),
    ];
    if (badges.isEmpty) {
      return const [
        _YieldBadge(
          value: '0',
          icon: GameIcons.minus,
          color: HudPalette.textTertiary,
        ),
      ];
    }
    return badges;
  }

  bool get dimmedForTesting => dimmed;

  bool get drawsDetailsForTesting => !dimmed;

  Color colorForTesting(CityManagementOverlayHexKind kind) => _colorFor(kind);

  int fillAlphaForTesting(CityManagementOverlayHexKind kind) =>
      _visibleAlpha(_fillAlphaFor(kind));

  double strokeWidthForTesting(CityManagementOverlayHexKind kind) =>
      _strokeWidthFor(kind);

  Color _colorFor(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.growthRecommended => HudPalette.info,
    CityManagementOverlayHexKind.growthCandidate => HudPalette.warning,
    CityManagementOverlayHexKind.workerImprovementExisting => HudPalette.info,
    CityManagementOverlayHexKind.workerImprovementMissingInCity =>
      HudPalette.info,
    CityManagementOverlayHexKind.workedManual => HudPalette.success,
    CityManagementOverlayHexKind.workedAuto => HudPalette.success,
    CityManagementOverlayHexKind.workedIdle => HudPalette.success,
  };

  int _fillAlphaFor(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.growthRecommended => MapAlpha.soft,
    CityManagementOverlayHexKind.growthCandidate => MapAlpha.soft,
    CityManagementOverlayHexKind.workerImprovementExisting => MapAlpha.regular,
    CityManagementOverlayHexKind.workerImprovementMissingInCity =>
      MapAlpha.soft,
    CityManagementOverlayHexKind.workedManual => MapAlpha.regular,
    CityManagementOverlayHexKind.workedAuto => MapAlpha.soft,
    CityManagementOverlayHexKind.workedIdle => MapAlpha.faint,
  };

  double _strokeWidthFor(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.growthRecommended => MapStroke.bold,
    CityManagementOverlayHexKind.workerImprovementExisting => MapStroke.regular,
    CityManagementOverlayHexKind.workerImprovementMissingInCity =>
      MapStroke.regular,
    CityManagementOverlayHexKind.workedManual => MapStroke.bold,
    _ => MapStroke.thin,
  };

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
      radius: hexRadius,
    );
    return [for (final corner in corners) Offset(corner.x, corner.y)];
  }

  Offset _hexCenter(CityHex hex) {
    final corners = _hexCorners(hex);
    final sum = corners.fold(Offset.zero, (total, point) => total + point);
    return Offset(sum.dx / corners.length, sum.dy / corners.length);
  }
}

class _YieldBadge {
  final String value;
  final GameIconData icon;
  final Color color;

  const _YieldBadge({
    required this.value,
    required this.icon,
    required this.color,
  });
}
