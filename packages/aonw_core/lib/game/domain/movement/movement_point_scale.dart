/// Deterministic fixed-point representation used by movement rules.
///
/// Domain state stores movement in integer units so half-point road costs do
/// not introduce floating-point drift into saves, replays, AI, or multiplayer.
abstract final class MovementPointScale {
  static const int unitsPerPoint = 2;

  static int unitsFromWholePoints(int points) => points * unitsPerPoint;

  static double pointsFromUnits(int units) => units / unitsPerPoint;

  static num displayPointsFromUnits(int units) =>
      units.isEven ? wholePointsFromUnits(units) : pointsFromUnits(units);

  static int wholePointsFromUnits(int units) => units ~/ unitsPerPoint;

  static String formatUnits(int units) {
    final whole = wholePointsFromUnits(units);
    return units.isEven ? '$whole' : '$whole.5';
  }
}
