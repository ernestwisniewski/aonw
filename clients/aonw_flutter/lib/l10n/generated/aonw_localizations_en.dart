// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AonwLocalizationsEn extends AonwLocalizations {
  AonwLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get unknownRouteLabel => 'Unknown route';

  @override
  String get pageUnavailable => 'Page unavailable';

  @override
  String unknownRouteMessage(String location) {
    return 'Unknown route: $location';
  }

  @override
  String get missingRouteLocation => '(missing)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Map $mapId, $cols by $rows hexes';
  }

  @override
  String get mapInputHint =>
      'Use the arrow keys or D-pad to move the map cursor and Enter or A to select.';

  @override
  String get noHexSelected => 'No hex selected';

  @override
  String selectedHex(int col, int row) {
    return 'Selected hex $col, $row';
  }

  @override
  String get hideReferenceLayer => 'Hide reference layer';

  @override
  String get showReferenceLayer => 'Show reference layer';

  @override
  String hexLabel(int col, int row) {
    return 'Hex $col, $row';
  }

  @override
  String unitLabel(String unitId) {
    return 'Unit $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Route: $totalCost movement units · $remaining remaining';
  }

  @override
  String get confirmMove => 'Confirm move';

  @override
  String get chooseHighlightedDestination =>
      'Choose a highlighted destination.';

  @override
  String get movingUnit => 'Moving unit';

  @override
  String get loadingMap => 'Loading map';

  @override
  String get mapLoadingFailed => 'Map loading failed';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get retry => 'Retry';
}
