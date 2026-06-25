import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_intent_marker.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum HoverIntentKind {
  move,
  attack,
  founding,
  workedHex,
  worker,
  trade,
  inspect,
}

class HoverIntentMarkerSpec {
  final CityHex hex;
  final HoverIntentKind kind;
  final Color color;
  final bool blocked;
  final bool reduceMotion;

  const HoverIntentMarkerSpec({
    required this.hex,
    required this.kind,
    required this.color,
    this.blocked = false,
    this.reduceMotion = false,
  });
}

class HoverIntentMarker extends Component {
  final CityHex hex;
  final HoverIntentKind kind;
  final Color color;
  final bool blocked;
  final bool reduceMotion;

  double _elapsed = 0;

  HoverIntentMarker({
    required this.hex,
    required this.kind,
    required this.color,
    this.blocked = false,
    this.reduceMotion = false,
  });

  @override
  void update(double dt) {
    super.update(dt);
    if (kind != HoverIntentKind.inspect || reduceMotion) return;
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final corners = _hexCorners(hex);
    final hexPath = Path()..moveTo(corners.first.dx, corners.first.dy);
    for (var i = 1; i < corners.length; i++) {
      hexPath.lineTo(corners[i].dx, corners[i].dy);
    }
    hexPath.close();

    final center = _hexCenter(hex);
    if (kind != HoverIntentKind.inspect) {
      canvas.drawPath(
        hexPath,
        HudPaint.fill(color, alpha: fillAlphaForTesting),
      );
    }

    canvas
      ..drawPath(
        hexPath,
        HudPaint.stroke(
          color,
          alpha: glowAlphaForTesting,
          strokeWidth: MapStroke.glow,
          strokeJoin: StrokeJoin.round,
        ),
      )
      ..drawPath(
        hexPath,
        HudPaint.stroke(
          color,
          alpha: strokeAlphaForTesting,
          strokeWidth: MapStroke.bold,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );

    switch (kind) {
      case HoverIntentKind.move:
        blocked
            ? _paintBlockedMoveGlyph(canvas, center)
            : _paintMoveGlyph(canvas, center);
      case HoverIntentKind.attack:
        _paintAttackGlyph(canvas, center);
      case HoverIntentKind.founding:
        _paintPlusGlyph(canvas, center);
      case HoverIntentKind.workedHex:
        _paintWorkedHexGlyph(canvas, center);
      case HoverIntentKind.worker:
        _paintWorkerGlyph(canvas, center);
      case HoverIntentKind.trade:
        _paintWorkerGlyph(canvas, center);
      case HoverIntentKind.inspect:
        _paintInspectGlyph(canvas, center);
    }
  }

  CityHex get hexForTesting => hex;
  HoverIntentKind get kindForTesting => kind;
  Color get colorForTesting => color;
  bool get blockedForTesting => blocked;

  int get fillAlphaForTesting {
    return switch (kind) {
      HoverIntentKind.attack => MapAlpha.faint,
      HoverIntentKind.inspect => MapAlpha.whisper,
      _ => MapAlpha.soft,
    };
  }

  int get glowAlphaForTesting {
    return switch (kind) {
      HoverIntentKind.inspect => MapAlpha.faint,
      _ => MapAlpha.soft,
    };
  }

  int get strokeAlphaForTesting {
    return switch (kind) {
      HoverIntentKind.inspect => MapAlpha.strong,
      _ => MapAlpha.solid,
    };
  }

  void _paintMoveGlyph(Canvas canvas, Offset center) {
    MapIntentMarker.paintMoveBadge(canvas, center);
  }

  void _paintBlockedMoveGlyph(Canvas canvas, Offset center) {
    _paintIntentBadge(canvas, center, MapIntentGlyph.unavailable);
  }

  void _paintAttackGlyph(Canvas canvas, Offset center) {
    _paintIntentBadge(canvas, center, MapIntentGlyph.attack);
  }

  void _paintPlusGlyph(Canvas canvas, Offset center) {
    _paintIntentBadge(canvas, center, MapIntentGlyph.city);
  }

  void _paintWorkedHexGlyph(Canvas canvas, Offset center) {
    _paintIntentBadge(canvas, center, MapIntentGlyph.workedHex);
  }

  void _paintWorkerGlyph(Canvas canvas, Offset center) {
    _paintIntentBadge(canvas, center, MapIntentGlyph.improve);
  }

  void _paintInspectGlyph(Canvas canvas, Offset center) {
    final pulse = reduceMotion ? 0.0 : (math.sin(_elapsed * 4.2) + 1) / 2;
    MapIntentMarker.paintBadge(
      canvas,
      center,
      color: color,
      glow: color,
      glyph: MapIntentGlyph.inspect,
      size: MapIntentMarker.touchBadgeSize + pulse * 2.0,
    );
  }

  void _paintIntentBadge(Canvas canvas, Offset center, MapIntentGlyph glyph) {
    MapIntentMarker.paintBadge(
      canvas,
      center,
      color: color,
      glow: color,
      glyph: glyph,
      size: MapIntentMarker.touchBadgeSize,
    );
  }

  Offset _hexCenter(CityHex hex) {
    final hexRadius = MapConfig.defaultConfig.hexRadius;
    final center = HexGeometry.tilePosition(
      col: hex.col,
      row: hex.row,
      hexRadius: hexRadius,
    );
    return Offset(
      center.x,
      center.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius),
    );
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
      radius: hexRadius * 0.9,
    );
    return [for (final corner in corners) Offset(corner.x, corner.y)];
  }
}

class HoverIntentMarkerLayer extends Component with LayerAttachment {
  HoverIntentMarker? _component;
  HoverIntentMarkerSpec? _spec;

  HoverIntentMarkerLayer() {
    priority = MapPriority.hoverIntentOverlay;
  }

  HoverIntentKind? get activeKind => _spec?.kind;
  HoverIntentKind? get kindForTesting => _spec?.kind;
  CityHex? get hexForTesting => _spec?.hex;
  Color? get colorForTesting => _spec?.color;
  bool? get blockedForTesting => _spec?.blocked;
  HoverIntentMarker? get markerForTesting => _component;

  void sync({
    required Component parent,
    required HoverIntentMarkerSpec? intent,
  }) {
    ensureAttachedTo(parent);
    if (intent == null) {
      clear();
      return;
    }

    if (_matches(intent)) return;

    clear();
    final component = HoverIntentMarker(
      hex: intent.hex,
      kind: intent.kind,
      color: intent.color,
      blocked: intent.blocked,
      reduceMotion: intent.reduceMotion,
    )..priority = MapPriority.hoverIntentOverlay;
    _spec = intent;
    _component = component;
    unawaited(Future<void>.value(add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
    _spec = null;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  bool _matches(HoverIntentMarkerSpec intent) {
    final current = _spec;
    if (current == null) return false;
    return current.hex == intent.hex &&
        current.kind == intent.kind &&
        current.color == intent.color &&
        current.blocked == intent.blocked &&
        current.reduceMotion == intent.reduceMotion;
  }
}
