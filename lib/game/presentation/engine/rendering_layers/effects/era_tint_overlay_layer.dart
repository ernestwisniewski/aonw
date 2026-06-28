import 'dart:async';

import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_palette.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class EraTintOverlay extends PositionComponent with HasPaint<String> {
  static final ComponentKey _eraTintEffectKey = ComponentKey.named(
    'era-tint-color-effect',
  );

  MapData _mapData;
  TechnologyEra _era;
  final double hexRadius;
  Rect _bounds = Rect.zero;
  List<Path> _tilePaths = const [];

  EraTintOverlay({
    required MapData mapData,
    required TechnologyEra era,
    this.hexRadius = MapConfig.defaultHexRadius,
  }) : _mapData = mapData,
       _era = era {
    paint
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = BlendMode.srcOver;
    _rebuildGeometry();
    _applyEraTint(animate: false);
  }

  TechnologyEra get era => _era;

  Rect get boundsForTesting => _bounds;

  int get tilePathCountForTesting => _tilePaths.length;

  void syncState({required MapData mapData, required TechnologyEra era}) {
    if (!identical(_mapData, mapData)) {
      _mapData = mapData;
      _rebuildGeometry();
    }
    if (_era == era) return;
    _era = era;
    _applyEraTint();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_tilePaths.isEmpty || _bounds.isEmpty) return;

    final tintColor = colorForEra(_era);
    final alpha = _alphaOf(tintColor);
    if (alpha <= 0) return;

    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HudPaint.color(HudPalette.textBright, alpha: (alpha * 0.35).round()),
        HudPaint.color(HudPalette.textBright, alpha: alpha),
        HudPaint.color(HudPalette.textBright, alpha: (alpha * 0.55).round()),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(_bounds);

    for (final path in _tilePaths) {
      canvas.drawPath(path, paint);
    }
    paint.shader = null;
  }

  void _rebuildGeometry() {
    _bounds = mapBoundsFor(_mapData, hexRadius: hexRadius);
    _tilePaths = [
      for (final tile in _mapData.tiles)
        _hexPath(col: tile.col, row: tile.row, hexRadius: hexRadius),
    ];
    size = Vector2(_bounds.width, _bounds.height);
  }

  void _applyEraTint({bool animate = true}) {
    removeWhere((component) => component.key == _eraTintEffectKey);
    paint.colorFilter = null;

    final color = colorForEra(_era);
    if (_alphaOf(color) <= 0) return;

    final targetTint = HudPaint.color(color, alpha: MapAlpha.full);
    if (!animate) {
      tint(targetTint);
      return;
    }

    unawaited(
      Future<void>.value(
        add(
          ColorEffect(
            targetTint,
            EffectController(duration: 0.65, curve: Curves.easeInOut),
            opacityFrom: 0,
            opacityTo: 1,
            key: _eraTintEffectKey,
          ),
        ),
      ),
    );
  }

  static Color colorForEra(TechnologyEra era) {
    return switch (era) {
      TechnologyEra.foundation => MapPalette.eraFoundationTint,
      TechnologyEra.settlement => MapPalette.eraSettlementTint,
      TechnologyEra.expansion => MapPalette.eraExpansionTint,
      TechnologyEra.specialization => MapPalette.eraSpecializationTint,
      TechnologyEra.industry => MapPalette.eraIndustryTint,
      TechnologyEra.strategy => MapPalette.eraStrategyTint,
    };
  }

  static Rect mapBoundsFor(
    MapData mapData, {
    double hexRadius = MapConfig.defaultHexRadius,
  }) {
    if (mapData.tiles.isEmpty) return Rect.zero;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final tile in mapData.tiles) {
      final center = HexGeometry.tilePosition(
        col: tile.col,
        row: tile.row,
        hexRadius: hexRadius,
      );
      for (final corner in HexGeometry.topFaceCorners(
        center: center,
        radius: hexRadius,
      )) {
        minX = corner.x < minX ? corner.x : minX;
        minY = corner.y < minY ? corner.y : minY;
        maxX = corner.x > maxX ? corner.x : maxX;
        maxY = corner.y > maxY ? corner.y : maxY;
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static Path _hexPath({
    required int col,
    required int row,
    required double hexRadius,
  }) {
    return HexGeometry.tileOverlayPath(
      col: col,
      row: row,
      hexRadius: hexRadius,
    );
  }

  static int _alphaOf(Color color) => (color.toARGB32() >> 24) & 0xFF;
}

class EraTintOverlayLayer extends Component with LayerAttachment {
  EraTintOverlay? _component;

  EraTintOverlayLayer() {
    priority = MapPriority.eraTint;
  }

  void sync({
    required Component parent,
    required MapData mapData,
    required PlayerResearchState playerResearch,
  }) {
    ensureAttachedTo(parent);
    final era = dominantEraFor(playerResearch);
    if (EraTintOverlay.colorForEra(era).toARGB32() == 0) {
      clear();
      return;
    }

    final existing = _component;
    if (existing != null) {
      existing.syncState(mapData: mapData, era: era);
      return;
    }

    final component = EraTintOverlay(mapData: mapData, era: era);
    _component = component;
    unawaited(Future<void>.value(add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  EraTintOverlay? get componentForTesting => _component;

  static TechnologyEra dominantEraFor(PlayerResearchState playerResearch) {
    var dominant = TechnologyEra.foundation;
    for (final technologyId in playerResearch.unlockedTechnologyIds) {
      final era = TechnologyCatalog.standard[technologyId]?.era;
      if (era == null) continue;
      if (era.index > dominant.index) {
        dominant = era;
      }
    }
    return dominant;
  }
}
