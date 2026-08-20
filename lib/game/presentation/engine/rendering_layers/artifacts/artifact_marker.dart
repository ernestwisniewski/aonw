import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/widgets/theme/artifact_type_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/math/scale_clamp.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class ArtifactMarker extends PositionComponent with TapCallbacks {
  static const double _baseWidth = 34;
  static const double _baseHeight = 36;
  static const double _pulsePeriod = 1.25;
  static const Color _rimColor = HudPalette.gold;
  static const Color _rimShadowColor = HudPalette.goldDark;
  static const Color _surfaceColor = HudPalette.bg;
  static const Color _selectedRimColor = HudPalette.goldLight;

  WorldArtifactType _type;
  VoidCallback? onTap;
  bool _selected;
  double _markerWorldScale;
  double _elapsed = 0;

  ArtifactMarker({
    required Vector2 position,
    required WorldArtifactType type,
    this.onTap,
    bool selected = false,
    double markerWorldScale = 1.0,
  }) : _type = type,
       _selected = selected,
       _markerWorldScale = clampMarkerScale(markerWorldScale),
       super(
         position: position,
         size: Vector2(_baseWidth, _baseHeight),
         anchor: Anchor.center,
       );

  WorldArtifactType get type => _type;

  set type(WorldArtifactType value) {
    if (_type == value) return;
    _type = value;
  }

  bool get selected => _selected;

  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
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
  void render(Canvas canvas) {
    super.render(canvas);
    final center = ui.Offset(size.x / 2, size.y / 2);
    final pulse = glowPulseForTesting;
    final stone = _markerPath(center);
    final shadow = _markerPath(center.translate(0, 2.5));
    final rimColor = _selected ? _selectedRimColor : _rimColor;
    final typeGlow = Color.lerp(_typeColor(_type), HudPalette.goldLight, 0.68)!;

    canvas
      ..drawOval(
        ui.Rect.fromCenter(
          center: center,
          width: 48 + pulse * 18,
          height: 39 + pulse * 15,
        ),
        Paint()
          ..color = typeGlow.withAlpha((68 + pulse * 92).round())
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            7.5 + pulse * 4.4,
          ),
      )
      ..drawOval(
        ui.Rect.fromCenter(
          center: center,
          width: 36 + pulse * 12,
          height: 30 + pulse * 10,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 + pulse * 1.0
          ..color = HudPalette.goldLight.withAlpha((88 + pulse * 96).round())
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            2.6 + pulse * 1.8,
          ),
      )
      ..drawOval(
        ui.Rect.fromCenter(
          center: center.translate(0, 9),
          width: 23,
          height: 7,
        ),
        Paint()
          ..color = Colors.black.withAlpha(64)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.5),
      )
      ..drawPath(shadow, Paint()..color = _rimShadowColor.withAlpha(218))
      ..drawPath(
        stone,
        Paint()
          ..shader = ui.Gradient.linear(
            center.translate(-12, -14),
            center.translate(12, 14),
            [HudPalette.goldLight, rimColor, _rimShadowColor],
            const [0, 0.48, 1],
          ),
      )
      ..drawPath(
        stone,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35
          ..color = Colors.black.withAlpha(112),
      );

    final inset = ui.Rect.fromCenter(center: center, width: 19, height: 19);
    canvas
      ..drawOval(inset.inflate(1.8), Paint()..color = _rimShadowColor)
      ..drawOval(inset.inflate(0.9), Paint()..color = rimColor)
      ..drawOval(inset, Paint()..color = _surfaceColor)
      ..drawOval(
        inset.deflate(2.7),
        Paint()
          ..shader = ui.Gradient.radial(inset.center.translate(-2, -3), 11, [
            typeGlow.withAlpha(232),
            HudPalette.goldDark.withAlpha(150),
          ]),
      );

    _drawGlyph(canvas, inset.center, HudPalette.textBright);
    _drawGlint(canvas, center.translate(7, -11));
  }

  Path _markerPath(ui.Offset center) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final radius = i.isEven ? 14.5 : 12.4;
      final point = center.translate(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawGlyph(Canvas canvas, ui.Offset center, Color color) {
    GameIconRenderer.paintIcon(
      canvas,
      gameIconForArtifactType(_type),
      topLeft: center - const ui.Offset(12, 12),
      size: 24,
      color: color,
    );
  }

  void _drawGlint(Canvas canvas, ui.Offset center) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(156)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(center.translate(-2.8, 0), center.translate(2.8, 0), paint)
      ..drawLine(center.translate(0, -2.8), center.translate(0, 2.8), paint);
  }

  static Color _typeColor(WorldArtifactType type) => switch (type) {
    WorldArtifactType.ancientImperialCrown => const Color(0xFF8B2F22),
    WorldArtifactType.astronomersTablets => const Color(0xFF235D8E),
    WorldArtifactType.prophetMask => const Color(0xFF6F3B8B),
    WorldArtifactType.heroSword => const Color(0xFF7A7F88),
    WorldArtifactType.merchantsSeal => const Color(0xFF9A6A1B),
    WorldArtifactType.firstPeoplesChronicle => const Color(0xFF2E6E4F),
    WorldArtifactType.templeReliquary => const Color(0xFF8A3A56),
    WorldArtifactType.queensMirror => const Color(0xFF31706E),
  };

  @visibleForTesting
  Color get rimColorForTesting => _selected ? _selectedRimColor : _rimColor;

  @visibleForTesting
  Color get typeColorForTesting => _typeColor(_type);

  @visibleForTesting
  GameIconData get glyphForTesting => gameIconForArtifactType(_type);

  @visibleForTesting
  int get outlineVertexCountForTesting => 6;

  @visibleForTesting
  double get glowPulseForTesting {
    final radians = (_elapsed / _pulsePeriod) * math.pi * 2;
    return (0.5 + math.sin(radians) * 0.5).clamp(0.0, 1.0).toDouble();
  }
}
