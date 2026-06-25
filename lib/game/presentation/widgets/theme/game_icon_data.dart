part of 'game_icon.dart';

class GameIconData {
  final List<String> paths;
  final bool filled;
  final double strokeWidth;

  const GameIconData({
    required this.paths,
    this.filled = false,
    this.strokeWidth = 2.0,
  });
}

abstract final class GameIconSize {
  static const double tiny = 12;
  static const double small = 16;
  static const double regular = 20;
  static const double large = 28;
  static const double hero = 36;
}
