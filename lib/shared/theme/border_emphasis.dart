import 'package:flutter/material.dart';

/// Named alpha levels for HUD borders.
///
/// Use these instead of ad-hoc `Border.all(color: color.withAlpha(...))`
/// values so visual weight stays consistent across the game UI.
enum BorderEmphasis {
  subtle(60),
  regular(110),
  strong(160),
  active(220);

  const BorderEmphasis(this.alpha);

  final int alpha;

  Border border(Color color, {double width = 1}) {
    return Border.all(color: color.withAlpha(alpha), width: width);
  }

  BorderSide side(Color color, {double width = 1}) {
    return BorderSide(color: color.withAlpha(alpha), width: width);
  }
}
