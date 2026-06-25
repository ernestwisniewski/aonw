abstract final class HudSideMenuMetrics {
  static const double topOffset = 70;
  static const double compactTopOffset = 86;
  static const double compactBreakpoint = 620;

  static bool useCompactTop({required double width, required double height}) {
    return width < compactBreakpoint && height >= width;
  }
}
