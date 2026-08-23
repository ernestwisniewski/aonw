// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'aonw_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AonwLocalizationsPl extends AonwLocalizations {
  AonwLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Age of New Worlds';

  @override
  String get unknownRouteLabel => 'Nieznana trasa';

  @override
  String get pageUnavailable => 'Strona niedostępna';

  @override
  String unknownRouteMessage(String location) {
    return 'Nieznana trasa: $location';
  }

  @override
  String get missingRouteLocation => '(brak)';

  @override
  String mapSemanticsLabel(String mapId, int cols, int rows) {
    return 'Mapa $mapId, $cols na $rows heksów';
  }

  @override
  String get mapInputHint =>
      'Użyj strzałek lub krzyżaka, aby przesunąć kursor mapy, oraz Enter lub A, aby wybrać.';

  @override
  String get noHexSelected => 'Nie wybrano heksa';

  @override
  String selectedHex(int col, int row) {
    return 'Wybrany heks $col, $row';
  }

  @override
  String get hideReferenceLayer => 'Ukryj warstwę referencyjną';

  @override
  String get showReferenceLayer => 'Pokaż warstwę referencyjną';

  @override
  String hexLabel(int col, int row) {
    return 'Heks $col, $row';
  }

  @override
  String unitLabel(String unitId) {
    return 'Jednostka $unitId';
  }

  @override
  String routeSummary(int totalCost, int remaining) {
    return 'Trasa: $totalCost punktów ruchu · pozostało $remaining';
  }

  @override
  String get confirmMove => 'Potwierdź ruch';

  @override
  String get chooseHighlightedDestination =>
      'Wybierz podświetlone pole docelowe.';

  @override
  String get movingUnit => 'Przemieszczanie jednostki';

  @override
  String get loadingMap => 'Wczytywanie mapy';

  @override
  String get mapLoadingFailed => 'Nie udało się wczytać mapy';

  @override
  String get mapUnavailable => 'Mapa jest niedostępna';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get audioSettings => 'Dźwięk';

  @override
  String get masterVolume => 'Głośność główna';

  @override
  String get cameraSettings => 'Kamera';

  @override
  String get cameraSensitivity => 'Czułość przybliżenia';

  @override
  String get accessibilitySettings => 'Dostępność';

  @override
  String get reducedMotion => 'Ogranicz ruch';

  @override
  String get reducedMotionDescription => 'Wyłącz zbędne animacje i przejścia.';

  @override
  String get highContrast => 'Wysoki kontrast';

  @override
  String get highContrastDescription =>
      'Zwiększ kontrast interfejsu aplikacji.';

  @override
  String get resetSettings => 'Przywróć domyślne';
}
