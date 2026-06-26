import 'package:flutter/material.dart';

abstract final class HudSelectionContextMetrics {
  static const double lineHeight = 42;
  static const double iconGap = 8;
  static const double verticalPadding = 8;
  static const double chipsGap = 16;

  static double lineHeightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final extraHeight = ((scale - 1) * 18).clamp(0, 14).toDouble();
    return lineHeight + extraHeight;
  }

  static double assetIconSizeFor(BuildContext context) {
    return lineHeightFor(context);
  }
}
