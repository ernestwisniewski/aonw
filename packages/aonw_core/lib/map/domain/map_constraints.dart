/// Single source of truth for map dimension limits.
///
/// Used by the map editor to guard creation and resize controls.
abstract final class MapConstraints {
  static const int minCols = 5;
  static const int maxCols = 40;
  static const int minRows = 5;
  static const int maxRows = 30;
}
