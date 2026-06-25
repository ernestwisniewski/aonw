import 'package:flutter/material.dart';

abstract final class MapPalette {
  static Color player(int colorValue) => Color(colorValue);

  static const Color fogHidden = Color(0xFF000000);
  static const Color fogDiscovered = Color(0x80000000);
  static const Color worldBackground = fogHidden;
  static const Color defaultWallTint = Color(0xFF111820);

  static const Color eraFoundationTint = Color(0x22F6C365);
  static const Color eraSettlementTint = Color(0x14B9D88C);
  static const Color eraExpansionTint = Color(0x00000000);
  static const Color eraSpecializationTint = Color(0x1C78B7FF);
  static const Color eraIndustryTint = Color(0x286D747C);
  static const Color eraStrategyTint = Color(0x24F0A24F);

  static const Color overlayShadow = Color(0xD4060B11);
}
