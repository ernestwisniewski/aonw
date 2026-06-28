import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/shared/math/scale_clamp.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class MapObjectiveMarker extends PositionComponent with TapCallbacks {
  static const double _baseWidth = 38;
  static const double _baseHeight = 36;
  static const double _pulsePeriod = 1.4;

  MapObjectiveType _type;
  String? _controllingPlayerId;
  int? _controlColorValue;
  bool _contested;
  bool _completed;
  int _holdTurns;
  int _requiredHoldTurns;
  double _markerWorldScale;
  double _elapsed = 0;
  VoidCallback? onTap;

  MapObjectiveMarker({
    required Vector2 position,
    required MapObjectiveType type,
    String? controllingPlayerId,
    int? controlColorValue,
    bool contested = false,
    bool completed = false,
    int holdTurns = 0,
    int requiredHoldTurns = 1,
    double markerWorldScale = 1.0,
    this.onTap,
  }) : _type = type,
       _controllingPlayerId = controllingPlayerId,
       _controlColorValue = controlColorValue,
       _contested = contested,
       _completed = completed,
       _holdTurns = math.max(0, holdTurns),
       _requiredHoldTurns = math.max(1, requiredHoldTurns),
       _markerWorldScale = clampMarkerScale(markerWorldScale),
       super(
         position: position,
         size: Vector2(_baseWidth, _baseHeight),
         anchor: Anchor.center,
       );

  MapObjectiveType get type => _type;

  set type(MapObjectiveType value) {
    if (_type == value) return;
    _type = value;
  }

  String? get controllingPlayerId => _controllingPlayerId;

  set controllingPlayerId(String? value) {
    if (_controllingPlayerId == value) return;
    _controllingPlayerId = value;
  }

  int? get controlColorValue => _controlColorValue;

  set controlColorValue(int? value) {
    if (_controlColorValue == value) return;
    _controlColorValue = value;
  }

  bool get contested => _contested;

  set contested(bool value) {
    if (_contested == value) return;
    _contested = value;
  }

  bool get completed => _completed;

  set completed(bool value) {
    if (_completed == value) return;
    _completed = value;
  }

  int get holdTurns => _holdTurns;

  set holdTurns(int value) {
    final next = math.max(0, value);
    if (_holdTurns == next) return;
    _holdTurns = next;
  }

  int get requiredHoldTurns => _requiredHoldTurns;

  set requiredHoldTurns(int value) {
    final next = math.max(1, value);
    if (_requiredHoldTurns == next) return;
    _requiredHoldTurns = next;
  }

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = clampMarkerScale(value);
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    scale = Vector2.all(next);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    scale = Vector2.all(_markerWorldScale);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!dt.isFinite || dt <= 0) return;
    _elapsed = (_elapsed + dt) % _pulsePeriod;
  }

  void setWorldPosition(Vector2 value) {
    if (position.x == value.x && position.y == value.y) return;
    position = value;
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final center = ui.Offset(size.x / 2, size.y / 2);
    final pulse = glowPulseForTesting;
    final accent = statusColorForTesting;
    final body = _trianglePath(center);
    final shadow = _trianglePath(center.translate(0, 2.7));

    canvas
      ..drawOval(
        ui.Rect.fromCenter(
          center: center.translate(0, 8),
          width: 34 + pulse * 13,
          height: 22 + pulse * 8,
        ),
        Paint()
          ..color = accent.withAlpha((72 + pulse * 88).round())
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            5.5 + pulse * 3.5,
          ),
      )
      ..drawOval(
        ui.Rect.fromCenter(
          center: center.translate(0, 12),
          width: 24,
          height: 6,
        ),
        Paint()
          ..color = HudPalette.bg.withAlpha(112)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
      )
      ..drawPath(shadow, Paint()..color = HudPalette.goldDark.withAlpha(210))
      ..drawPath(
        body,
        Paint()
          ..shader = ui.Gradient.linear(
            center.translate(-10, -14),
            center.translate(10, 17),
            [accent.withAlpha(236), HudPalette.gold, HudPalette.goldDark],
            const [0, 0.5, 1],
          ),
      )
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15
          ..color = HudPalette.bg.withAlpha(150),
      );

    final badge = _innerTrianglePath(center);
    canvas
      ..drawPath(
        badge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..color = HudPalette.goldDark,
      )
      ..drawPath(
        badge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1
          ..color = accent,
      )
      ..drawPath(badge, Paint()..color = HudPalette.surface.withAlpha(232));

    _drawGlyph(canvas, center.translate(0, 1), HudPalette.textBright);
    _drawProgress(canvas, body, accent);
  }

  Path _trianglePath(ui.Offset c) => Path()
    ..moveTo(c.dx, c.dy - 16)
    ..lineTo(c.dx + 16.5, c.dy + 15)
    ..lineTo(c.dx - 16.5, c.dy + 15)
    ..close();

  Path _innerTrianglePath(ui.Offset c) => Path()
    ..moveTo(c.dx, c.dy - 8.8)
    ..lineTo(c.dx + 9.3, c.dy + 8.4)
    ..lineTo(c.dx - 9.3, c.dy + 8.4)
    ..close();

  void _drawGlyph(ui.Canvas canvas, ui.Offset c, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = switch (_type) {
      MapObjectiveType.ruins => _ruinsGlyph(c),
      MapObjectiveType.strategicPass => _passGlyph(c),
      MapObjectiveType.holySite => _holySiteGlyph(c),
      MapObjectiveType.legendaryResource => _legendaryGlyph(c),
    };
    canvas.drawPath(path, paint);
  }

  void _drawProgress(ui.Canvas canvas, Path body, Color accent) {
    if (_controllingPlayerId == null) return;
    final fraction = (_holdTurns / _requiredHoldTurns).clamp(0.0, 1.0);
    final metric = body.computeMetrics().first;
    final progressPath = metric.extractPath(0, metric.length * fraction);
    canvas.drawPath(
      progressPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _completed ? 2.3 : 1.65
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
  }

  Path _ruinsGlyph(ui.Offset c) => Path()
    ..moveTo(c.dx - 5.8, c.dy + 5.5)
    ..lineTo(c.dx + 5.8, c.dy + 5.5)
    ..moveTo(c.dx - 4.8, c.dy + 2.4)
    ..lineTo(c.dx - 4.8, c.dy - 4.8)
    ..moveTo(c.dx, c.dy + 2.4)
    ..lineTo(c.dx, c.dy - 5.8)
    ..moveTo(c.dx + 4.8, c.dy + 2.4)
    ..lineTo(c.dx + 4.8, c.dy - 3.8)
    ..moveTo(c.dx - 6.2, c.dy - 5.8)
    ..lineTo(c.dx + 5.1, c.dy - 5.8);

  Path _passGlyph(ui.Offset c) => Path()
    ..moveTo(c.dx - 6.4, c.dy + 5.4)
    ..lineTo(c.dx - 2.2, c.dy - 5.4)
    ..lineTo(c.dx + 0.2, c.dy + 1.6)
    ..lineTo(c.dx + 3.1, c.dy - 4.8)
    ..lineTo(c.dx + 6.4, c.dy + 5.4);

  Path _holySiteGlyph(ui.Offset c) => Path()
    ..addOval(ui.Rect.fromCircle(center: c, radius: 5.6))
    ..moveTo(c.dx, c.dy - 7.2)
    ..lineTo(c.dx, c.dy + 7.2)
    ..moveTo(c.dx - 4.8, c.dy - 1.7)
    ..lineTo(c.dx + 4.8, c.dy - 1.7);

  Path _legendaryGlyph(ui.Offset c) => Path()
    ..moveTo(c.dx, c.dy - 6.8)
    ..lineTo(c.dx + 2.0, c.dy - 2.0)
    ..lineTo(c.dx + 6.8, c.dy)
    ..lineTo(c.dx + 2.0, c.dy + 2.0)
    ..lineTo(c.dx, c.dy + 6.8)
    ..lineTo(c.dx - 2.0, c.dy + 2.0)
    ..lineTo(c.dx - 6.8, c.dy)
    ..lineTo(c.dx - 2.0, c.dy - 2.0)
    ..close();

  Color _statusColor() {
    if (_contested) return HudPalette.warning;
    if (_completed) return HudPalette.successLight;
    final colorValue = _controlColorValue;
    if (colorValue != null) return Color(colorValue);
    return HudPalette.goldLight;
  }

  @visibleForTesting
  Color get statusColorForTesting => _statusColor();

  @visibleForTesting
  int get outlineVertexCountForTesting => 3;

  @visibleForTesting
  double get glowPulseForTesting {
    final radians = (_elapsed / _pulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }
}
