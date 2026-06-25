abstract final class MultiplayerAvatarsRailMetrics {
  static const double itemWidth = 140;
  static const double itemHeight = 32;
  static const double itemGap = 6;
  static const double compactItemSize = 40;
  static const double compactItemGap = 6;
  static const double compactBreakpoint = 620;
  static const double landscapePhoneHeight = 520;

  static bool useCompactLayout({
    required double width,
    required double height,
  }) {
    final landscapePhone = height < landscapePhoneHeight && width > height;
    return landscapePhone || width < compactBreakpoint;
  }
}
