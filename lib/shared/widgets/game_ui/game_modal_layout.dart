import 'dart:math' as math;

class GameModalLayout {
  const GameModalLayout._();

  static const double regularDetailsMaxHeight = 640;
  static const double compactDetailsMaxHeight = 560;

  static double detailsMaxHeight(double? requested, {bool compact = false}) {
    final cap = compact ? compactDetailsMaxHeight : regularDetailsMaxHeight;
    if (requested == null || !requested.isFinite) return cap;
    return math.min(requested, cap);
  }

  static double inlineDetailsMaxHeight({
    required double availableHeight,
    required double padding,
    required bool compact,
  }) {
    if (!availableHeight.isFinite) {
      return detailsMaxHeight(null, compact: compact);
    }
    return detailsMaxHeight(
      math.max(0, availableHeight - padding * 2),
      compact: compact,
    );
  }
}
