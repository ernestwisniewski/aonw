import 'package:flutter/material.dart';

abstract final class AonwTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB78B47),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
