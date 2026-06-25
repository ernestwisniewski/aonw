import 'dart:math' as math;
import 'dart:ui';

import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TextPainter, TextSpan, TextStyle;

enum MapPillTone { gold, warning }

class MapPillComponent extends PositionComponent with TapCallbacks {
  MapPillComponent({
    required String label,
    GameIconData? icon,
    MapPillTone tone = MapPillTone.gold,
    VoidCallback? onTap,
    int priority = MapPriority.movePreviewPill,
  }) : _label = label,
       _icon = icon ?? GameIcons.move,
       _tone = tone,
       _onTap = onTap,
       super(
         anchor: Anchor.bottomCenter,
         priority: priority,
         size: MapPillPainter.measure(label, icon: icon ?? GameIcons.move),
       );

  String _label;
  GameIconData? _icon;
  MapPillTone _tone;
  VoidCallback? _onTap;
  double _elapsed = 0;

  @visibleForTesting
  String get labelForTesting => _label;

  @visibleForTesting
  MapPillTone get toneForTesting => _tone;

  void updatePresentation({
    required String label,
    GameIconData? icon,
    MapPillTone tone = MapPillTone.gold,
    VoidCallback? onTap,
  }) {
    _label = label;
    _icon = icon ?? GameIcons.move;
    _tone = tone;
    _onTap = onTap;
    size = MapPillPainter.measure(_label, icon: _icon);
  }

  @visibleForTesting
  void tapForTesting() {
    _onTap?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    MapPillPainter.paint(
      canvas,
      label: _label,
      icon: _icon,
      tone: _tone,
      size: size,
      elapsed: _elapsed,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    _onTap?.call();
  }
}

abstract final class MapPillPainter {
  static const double minWidth = 58;
  static const double maxWidth = 172;
  static const double height = 42;
  static const double topPadding = 2;
  static const double panelHeight = 28;
  static const double panelRadius = 7;
  static const double pointerHalfWidth = 6;
  static const double iconSize = 12;
  static const double iconGap = 4;
  static const double contentPaddingX = 9;
  static const double fontSize = 9.5;

  static final Paint _shadowPaint = HudPaint.shadow(alpha: 54)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  static Vector2 measure(String label, {GameIconData? icon}) {
    final painter = TextPainter(
      text: TextSpan(
        text: displayTextFor(label),
        style: const TextStyle(
          fontFamily: GameUiTheme.bodyFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final iconWidth = icon == null ? 0 : iconSize + iconGap;
    final width = painter.width + iconWidth + contentPaddingX * 2;
    return Vector2(width.clamp(minWidth, maxWidth).toDouble(), height);
  }

  static void paint(
    Canvas canvas, {
    required String label,
    required Vector2 size,
    GameIconData? icon,
    MapPillTone tone = MapPillTone.gold,
    double elapsed = 0,
  }) {
    final pulse = 0.5 + 0.5 * math.sin(elapsed * math.pi * 2 / 1.45);
    final accent = _accentFor(tone);
    final glowAlpha = 16 + (pulse * 28).round();
    final borderAlpha = 88 + (pulse * 34).round();
    final fillAlpha = 148 + (pulse * 12).round();
    final panelRect = Rect.fromLTWH(0, topPadding, size.x, panelHeight);
    final panelRRect = RRect.fromRectAndRadius(
      panelRect,
      const Radius.circular(panelRadius),
    );
    final pointer = pointerPath(size: size, panelRect: panelRect);
    final glowPaint = HudPaint.fill(accent, alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final surfacePaint = HudPaint.fill(HudPalette.bg, alpha: fillAlpha);
    final borderPaint = HudPaint.border(
      BorderEmphasis.regular,
      color: accent,
      alpha: borderAlpha,
      strokeWidth: 1,
    );

    canvas
      ..drawRRect(panelRRect.shift(const Offset(0, 2)), _shadowPaint)
      ..drawPath(pointer.shift(const Offset(0, 2)), _shadowPaint)
      ..drawRRect(panelRRect.inflate(1.5), glowPaint)
      ..drawPath(pointer, glowPaint)
      ..drawRRect(panelRRect, surfacePaint)
      ..drawPath(pointer, surfacePaint)
      ..drawRRect(panelRRect, borderPaint)
      ..drawPath(pointer, borderPaint);

    _paintContent(canvas, panelRect: panelRect, label: label, icon: icon);
  }

  static void paintAnchored(
    Canvas canvas, {
    required Offset anchor,
    required String label,
    GameIconData? icon,
    MapPillTone tone = MapPillTone.gold,
    double elapsed = 0,
  }) {
    final size = measure(label, icon: icon);
    canvas
      ..save()
      ..translate(anchor.dx - size.x / 2, anchor.dy - size.y);
    paint(
      canvas,
      label: label,
      icon: icon,
      tone: tone,
      size: size,
      elapsed: elapsed,
    );
    canvas.restore();
  }

  static Path pointerPath({required Vector2 size, required Rect panelRect}) {
    final centerX = size.x / 2;
    final baseY = panelRect.bottom - 0.5;
    return Path()
      ..moveTo(centerX - pointerHalfWidth, baseY)
      ..lineTo(centerX + pointerHalfWidth, baseY)
      ..lineTo(centerX, size.y)
      ..close();
  }

  static String displayTextFor(String label) {
    return label
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' · ');
  }

  static Color _accentFor(MapPillTone tone) {
    return switch (tone) {
      MapPillTone.gold => HudPalette.goldLight,
      MapPillTone.warning => HudPalette.warning,
    };
  }

  static void _paintContent(
    Canvas canvas, {
    required Rect panelRect,
    required String label,
    GameIconData? icon,
  }) {
    var textLeft = panelRect.left + contentPaddingX;
    if (icon != null) {
      final iconTop = panelRect.top + (panelRect.height - iconSize) / 2;
      GameIconRenderer.paintIcon(
        canvas,
        icon,
        topLeft: Offset(textLeft, iconTop),
        size: iconSize,
        color: HudPalette.goldLight,
      );
      textLeft += iconSize + iconGap;
    }

    final textWidth = panelRect.right - textLeft - contentPaddingX;
    final textPainter = TextPainter(
      text: TextSpan(
        text: displayTextFor(label),
        style: TextStyle(
          color: HudPaint.color(GameUiTheme.textBright, alpha: 220),
          fontFamily: GameUiTheme.bodyFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);
    final textTop = panelRect.top + (panelRect.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textLeft, textTop));
  }
}
