import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';

abstract final class PlayerColorTheme {
  static const List<int> palette = Player.palette;

  static int resolveValue(int colorValue) => colorValue;

  static Color resolve(int colorValue) => Color(resolveValue(colorValue));
}
