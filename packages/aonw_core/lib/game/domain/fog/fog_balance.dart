abstract final class FogBalance {
  static const int unitVisionRange = 2;
  static const int cityCenterVisionRange = 2;
  static const int controlledHexVisionRange = 0;

  static const int baseSightCost = 1;
  static const int forestSightCost = 1;
  static const int jungleSightCost = 1;
  static const int hillsSightCost = 1;

  static const int maxVisionRange = 3;

  /// Vision range bonus granted per 2 height levels above ground (floor(height/2) * this).
  static const int elevationBonusPerLevel = 1;
  static const int elevationBlockingThreshold = 1;
}
