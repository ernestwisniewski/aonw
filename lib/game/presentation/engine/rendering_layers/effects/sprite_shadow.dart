import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:flutter/material.dart';

abstract final class SpriteShadow {
  static const int _unitAlpha = 80;
  static const int _improvementAlpha = 90;
  static const int _cityAlpha = 102;
  static final Color unitColor = HudPaint.color(
    Colors.black,
    alpha: _unitAlpha,
  );
  static final Color improvementColor = HudPaint.color(
    Colors.black,
    alpha: _improvementAlpha,
  );
  static final Color cityColor = HudPaint.color(
    Colors.black,
    alpha: _cityAlpha,
  );
  static const double _castWidthFactor = 1.42;
  static const double _castHeightFactor = 1.28;
  static const double _castOffsetXFactor = 0.16;
  static const double _castOffsetYFactor = 0.22;
  static const double _ambientInflateFactor = 0.16;
  static const double _contactWidthFactor = 0.62;
  static const double _contactHeightFactor = 0.45;
  static const double _contactOffsetYFactor = 0.14;
  static const double _castAlphaFactor = 0.42;
  static const double _ambientAlphaFactor = 0.68;
  static const double _contactAlphaFactor = 1.18;

  static Rect unitRect({required Offset center, required bool onCity}) {
    final width = onCity ? 18.0 : 24.0;
    final height = onCity ? 6.0 : 8.0;
    return Rect.fromCenter(
      center: center.translate(0, onCity ? 7 : 9),
      width: width,
      height: height,
    );
  }

  static Rect cityRect({required Offset spriteBottomCenter}) {
    return Rect.fromCenter(
      center: spriteBottomCenter.translate(0, 2),
      width: 60,
      height: 14,
    );
  }

  static Rect improvementRect({required Offset spriteBottomCenter}) {
    return Rect.fromCenter(
      center: spriteBottomCenter.translate(0, 2),
      width: 38,
      height: 10,
    );
  }

  static void paint(
    Canvas canvas,
    Rect rect, {
    required Color color,
    double blurSigma = 4,
  }) {
    _paintOval(canvas, rect, color: color, blurSigma: blurSigma);
  }

  static void paint3d(
    Canvas canvas,
    Rect rect, {
    required Color color,
    double blurSigma = 4,
  }) {
    _paintOval(
      canvas,
      _castRect(rect),
      color: _castColor(color),
      blurSigma: blurSigma * 1.85,
    );
    _paintOval(
      canvas,
      _ambientRect(rect),
      color: _ambientColor(color),
      blurSigma: blurSigma * 1.15,
    );
    _paintOval(
      canvas,
      _contactRect(rect),
      color: _contactColor(color),
      blurSigma: (blurSigma * 0.42).clamp(1.0, blurSigma),
    );
  }

  static Rect castRectForTesting(Rect rect) {
    return _castRect(rect);
  }

  static Rect ambientRectForTesting(Rect rect) {
    return _ambientRect(rect);
  }

  static Rect contactRectForTesting(Rect rect) {
    return _contactRect(rect);
  }

  static Color castColorForTesting(Color color) {
    return _castColor(color);
  }

  static Color ambientColorForTesting(Color color) {
    return _ambientColor(color);
  }

  static Color contactColorForTesting(Color color) {
    return _contactColor(color);
  }

  static Rect _castRect(Rect rect) {
    return Rect.fromCenter(
      center: rect.center.translate(
        rect.width * _castOffsetXFactor,
        rect.height * _castOffsetYFactor,
      ),
      width: rect.width * _castWidthFactor,
      height: rect.height * _castHeightFactor,
    );
  }

  static Rect _ambientRect(Rect rect) {
    return rect.inflate(rect.height * _ambientInflateFactor);
  }

  static Rect _contactRect(Rect rect) {
    return Rect.fromCenter(
      center: rect.center.translate(0, rect.height * _contactOffsetYFactor),
      width: rect.width * _contactWidthFactor,
      height: rect.height * _contactHeightFactor,
    );
  }

  static Color _castColor(Color color) {
    return _scaleAlpha(color, _castAlphaFactor);
  }

  static Color _ambientColor(Color color) {
    return _scaleAlpha(color, _ambientAlphaFactor);
  }

  static Color _contactColor(Color color) {
    return _scaleAlpha(color, _contactAlphaFactor);
  }

  static void _paintOval(
    Canvas canvas,
    Rect rect, {
    required Color color,
    required double blurSigma,
  }) {
    canvas.drawOval(
      rect,
      HudPaint.fill(color)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
    );
  }

  static Color _scaleAlpha(Color color, double factor) {
    final alpha = (color.toARGB32() >> 24) & 0xFF;
    final scaled = (alpha * factor).round().clamp(0, 255).toInt();
    return HudPaint.color(color, alpha: scaled);
  }
}
