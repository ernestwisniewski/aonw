import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CombatHexAlertLayer extends Component with LayerAttachment {
  final Map<String, CombatHexAlertOverlay> _overlays = {};

  void show({
    required Component parent,
    required ShowCombatHexAlertEffect effect,
    bool reduceMotion = false,
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final existing = _overlays[effect.id];
    if (existing != null) {
      existing
        ..refresh(
          ownerPlayerId: effect.ownerPlayerId,
          unitId: effect.unitId,
          cityId: effect.cityId,
          hex: CityHex(col: effect.col, row: effect.row),
          kind: effect.kind,
          reduceMotion: reduceMotion,
          ownerSubmittedAtAttack: effect.ownerSubmittedAtAttack,
        )
        ..priority = _priorityFor(effect.col, effect.row, effect.kind);
      return;
    }

    final created = CombatHexAlertOverlay(
      id: effect.id,
      unitId: effect.unitId,
      cityId: effect.cityId,
      ownerPlayerId: effect.ownerPlayerId,
      hex: CityHex(col: effect.col, row: effect.row),
      kind: effect.kind,
      reduceMotion: reduceMotion,
      ownerSubmittedAtAttack: effect.ownerSubmittedAtAttack,
    )..priority = _priorityFor(effect.col, effect.row, effect.kind);
    _overlays[effect.id] = created;
    unawaited(Future<void>.value(owner.add(created)));
  }

  void syncState({
    required Component parent,
    required GameState state,
    bool reduceMotion = false,
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    for (final entry in _overlays.entries.toList()) {
      final overlay = entry.value;
      final cityId = overlay.cityId;
      final unitId = overlay.unitId;
      GameCity? city;
      GameUnit? unit;
      if (cityId != null) {
        city = _knownCityById(state, cityId);
        if (city == null || city.ownerPlayerId != overlay.ownerPlayerId) {
          overlay.removeFromParent();
          _overlays.remove(entry.key);
          continue;
        }
      }
      if (unitId != null) {
        unit = _unitById(state, unitId);
        if (unit == null || unit.ownerPlayerId != overlay.ownerPlayerId) {
          overlay.removeFromParent();
          _overlays.remove(entry.key);
          continue;
        }
      }
      final ownerSubmitted = state.submittedPlayerIds.contains(
        overlay.ownerPlayerId,
      );
      if (overlay.shouldExpireForOwnerSubmission(ownerSubmitted)) {
        overlay.removeFromParent();
        _overlays.remove(entry.key);
        continue;
      }
      if (city != null) {
        overlay.hex = city.center;
      } else if (unit != null) {
        overlay.hex = CityHex(col: unit.col, row: unit.row);
      }
      overlay
        ..reduceMotion = reduceMotion
        ..priority = _priorityFor(
          overlay.hex.col,
          overlay.hex.row,
          overlay.kind,
        );
      if (!overlay.isMounted && overlay.parent == null) {
        unawaited(Future<void>.value(owner.add(overlay)));
      }
    }
  }

  void clear() {
    for (final overlay in _overlays.values) {
      overlay.removeFromParent();
    }
    _overlays.clear();
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  bool hasAlertForTesting(String id) =>
      _overlays.containsKey(id) || _overlays.containsKey('city:$id');

  CityHex? alertHexForTesting(String id) =>
      (_overlays[id] ?? _overlays['city:$id'])?.hex;

  double alertPulseForTesting(String id) =>
      (_overlays[id] ?? _overlays['city:$id'])?.pulseForTesting ?? 0;

  int alertCountForTesting() => _overlays.length;

  int alertCountAtHexForTesting(CityHex hex) {
    return _overlays.values.where((overlay) {
      return overlay.hex.col == hex.col && overlay.hex.row == hex.row;
    }).length;
  }

  Set<CombatHexAlertKind> alertKindsAtHexForTesting(CityHex hex) {
    return {
      for (final overlay in _overlays.values)
        if (overlay.hex.col == hex.col && overlay.hex.row == hex.row)
          overlay.kind,
    };
  }

  static int _priorityFor(int col, int row, CombatHexAlertKind kind) {
    final kindLayer = switch (kind) {
      CombatHexAlertKind.attacker => 0,
      CombatHexAlertKind.attacked => 2,
    };
    return MapPriority.perTile(
          MapPriority.combatIntentOverlay,
          col: col,
          row: row,
        ) +
        kindLayer;
  }

  GameCity? _knownCityById(GameState state, String cityId) {
    for (final city in state.citiesKnownToActivePlayer) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  GameUnit? _unitById(GameState state, String unitId) {
    for (final unit in state.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }
}

class CombatHexAlertOverlay extends Component {
  final String id;
  String? unitId;
  String? cityId;
  String ownerPlayerId;
  CityHex hex;
  CombatHexAlertKind kind;
  bool reduceMotion;
  bool _lastOwnerSubmitted;
  int _submissionsRemaining;

  double _elapsed = 0;

  CombatHexAlertOverlay({
    required this.id,
    required this.unitId,
    required this.cityId,
    required this.ownerPlayerId,
    required this.hex,
    required this.kind,
    this.reduceMotion = false,
    bool ownerSubmittedAtAttack = false,
  }) : _lastOwnerSubmitted = ownerSubmittedAtAttack,
       _submissionsRemaining = ownerSubmittedAtAttack ? 1 : 2;

  void refresh({
    required String ownerPlayerId,
    required String? unitId,
    required String? cityId,
    required CityHex hex,
    required CombatHexAlertKind kind,
    required bool reduceMotion,
    required bool ownerSubmittedAtAttack,
  }) {
    this.ownerPlayerId = ownerPlayerId;
    this.unitId = unitId;
    this.cityId = cityId;
    this.hex = hex;
    this.kind = kind;
    this.reduceMotion = reduceMotion;
    _lastOwnerSubmitted = ownerSubmittedAtAttack;
    _submissionsRemaining = ownerSubmittedAtAttack ? 1 : 2;
    restartPulse();
  }

  bool shouldExpireForOwnerSubmission(bool ownerSubmitted) {
    if (!_lastOwnerSubmitted && ownerSubmitted) {
      _submissionsRemaining -= 1;
    }
    _lastOwnerSubmitted = ownerSubmitted;
    return _submissionsRemaining <= 0;
  }

  void restartPulse() {
    _elapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (reduceMotion) return;
    _elapsed = (_elapsed + dt) % _pulsePeriod;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final path = _hexPath(hex);
    final pulse = pulseForTesting;

    if (kind == CombatHexAlertKind.attacker) {
      _renderAttackerGlow(canvas, path, pulse);
      return;
    }

    _renderAttackedBorder(canvas, path, pulse);
  }

  void _renderAttackedBorder(Canvas canvas, Path path, double pulse) {
    final glowAlpha = reduceMotion
        ? MapAlpha.soft
        : (MapAlpha.faint + pulse * MapAlpha.regular).round();
    final strokeAlpha = reduceMotion
        ? MapAlpha.strong
        : (MapAlpha.regular + pulse * (MapAlpha.full - MapAlpha.regular))
              .round();
    final strokeWidth = reduceMotion
        ? MapStroke.regular
        : MapStroke.bold + pulse * 1.15;

    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = MapStroke.glow + 1.2 + pulse * 2.0
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2)
          ..color = HudPalette.danger.withAlpha(glowAlpha),
      )
      ..drawPath(
        path,
        HudPaint.stroke(
          HudPalette.danger,
          alpha: strokeAlpha,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
  }

  void _renderAttackerGlow(Canvas canvas, Path boundaryPath, double pulse) {
    final coreAlpha = reduceMotion
        ? MapAlpha.faint
        : (MapAlpha.faint + pulse * 26).round();
    final innerAlpha = reduceMotion
        ? MapAlpha.whisper
        : (MapAlpha.whisper + pulse * 24).round();
    final glowAlpha = reduceMotion
        ? MapAlpha.faint
        : (MapAlpha.whisper + pulse * 28).round();
    final innerPath = _hexPath(hex, radiusScale: 0.68);
    final bloomPath = _hexPath(hex, radiusScale: 0.78);
    final bounds = boundaryPath.getBounds();

    canvas
      ..save()
      ..clipPath(boundaryPath)
      ..drawPath(
        boundaryPath,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [
              HudPalette.danger.withAlpha(coreAlpha),
              HudPalette.danger.withAlpha(innerAlpha),
              HudPalette.danger.withAlpha(0),
            ],
            stops: const [0.0, 0.48, 1.0],
          ).createShader(bounds),
      )
      ..drawPath(
        bloomPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = MapStroke.glow + 6.0 + pulse * 2.8
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.4)
          ..color = HudPalette.danger.withAlpha(glowAlpha),
      )
      ..drawPath(
        innerPath,
        Paint()
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2)
          ..color = HudPalette.danger.withAlpha(innerAlpha),
      )
      ..restore();
  }

  double get pulseForTesting {
    if (reduceMotion) return 0.55;
    final radians = (_elapsed / _pulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }

  static const double _pulsePeriod = 0.92;

  Path _hexPath(CityHex hex, {double radiusScale = 0.98}) {
    final corners = _hexCorners(hex, radiusScale: radiusScale);
    return Path()
      ..moveTo(corners.first.dx, corners.first.dy)
      ..addPolygon(corners, true);
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
    return [for (final corner in corners) Offset(corner.x, corner.y)];
  }
}
