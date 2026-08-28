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
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Akcje jednostki',
      'fortify': 'Ufortyfikuj',
      'skip': 'Pomiń',
      'cancel': 'Anuluj akcję',
      'executing': 'Wykonywanie akcji jednostki',
      'other': 'Akcja jednostki',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'Nie udało się wykonać żądania akcji jednostki.',
      'responseIncompatible':
          'Odpowiedź akcji jednostki jest niezgodna z tym klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'stale': 'Stan gry uległ zmianie. Sprawdź jednostkę i spróbuj ponownie.',
      'matchFinished': 'Rozgrywka już się zakończyła.',
      'unitUnavailable':
          'Ta jednostka nie jest już dostępna do wydawania rozkazów.',
      'unitBusy':
          'Ta jednostka jest zajęta i nie może teraz wykonać tej akcji.',
      'internal': 'Nie udało się zastosować akcji jednostki. Spróbuj ponownie.',
      'other': 'Nie udało się wykonać akcji jednostki.',
    });
    return '$_temp0';
  }

  @override
  String turnLabel(int turn) {
    return 'TURA $turn';
  }

  @override
  String turnSubmissionProgress(int submitted, int required) {
    return 'Gotowi: $submitted z $required';
  }

  @override
  String get turnActive => 'Twoja tura';

  @override
  String get turnFinished => 'Tura zakończona';

  @override
  String get turnSubmitted => 'Tura zgłoszona';

  @override
  String get turnWaiting => 'Oczekiwanie';

  @override
  String get turnPendingAction => 'Wymagana akcja';

  @override
  String get endTurn => 'Zakończ turę';

  @override
  String get endingTurn => 'Kończenie tury';

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'Nie udało się wykonać żądania zakończenia tury.',
      'responseIncompatible': 'Odpowiedź tury jest niezgodna z tym klientem.',
      'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
      'stale_revision':
          'Stan gry uległ zmianie. Sprawdź go i spróbuj ponownie.',
      'match_finished': 'Rozgrywka już się zakończyła.',
      'turn_player_not_controlled':
          'Ten gracz nie może zakończyć bieżącej tury.',
      'turn_player_not_active': 'Ten gracz nie jest aktywny.',
      'turn_scope_invalid': 'Zakres bieżącej tury jest nieprawidłowy.',
      'turn_processor_unsupported': 'Wymagany procesor tury jest niedostępny.',
      'turn_number_overflow': 'Nie można zapisać numeru następnej tury.',
      'state_revision_overflow': 'Nie można zwiększyć rewizji gry.',
      'other': 'Nie udało się zakończyć tury.',
    });
    return '$_temp0';
  }

  @override
  String gameOutcome(String condition) {
    String _temp0 = intl.Intl.selectLogic(condition, {
      'conquest': 'Zwycięstwo przez podbój',
      'domination': 'Zwycięstwo przez dominację',
      'cultural': 'Zwycięstwo kulturowe',
      'score': 'Zwycięstwo punktowe',
      'resignation': 'Rozgrywka zakończona rezygnacją',
      'draw': 'Remis',
      'ongoing': 'Rozgrywka trwa',
      'other': 'Rozgrywka zakończona',
    });
    return '$_temp0';
  }

  @override
  String get activityLog => 'Aktywność';

  @override
  String activityEvent(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'artifact': 'Aktywność artefaktu',
      'city': 'Aktywność miasta',
      'research': 'Postęp badań',
      'objective': 'Aktualizacja celu strategicznego',
      'outcome': 'Zaktualizowano wynik rozgrywki',
      'combat': 'Aktywność bojowa',
      'diplomacy': 'Aktywność dyplomatyczna',
      'unit': 'Aktywność jednostki',
      'turn': 'Zaktualizowano turę',
      'worker': 'Robotnik ukończył zadanie',
      'other': 'Aktywność w grze',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Wczytywanie mapy';

  @override
  String get mapLoadingFailed => 'Nie udało się wczytać mapy';

  @override
  String get mapUnavailable => 'Mapa jest niedostępna';

  @override
  String get mapAdapterUnavailable =>
      'Natywny adapter gry jest niedostępny na tej platformie.';

  @override
  String get mapClientIncompatible =>
      'Natywny adapter gry jest niezgodny z tym klientem.';

  @override
  String get mapLoadSuperseded => 'Nowsze żądanie mapy zastąpiło to żądanie.';

  @override
  String get mapLoadFailure => 'Nie udało się wczytać mapy.';

  @override
  String get movementRequestFailed => 'Nie udało się wykonać żądania ruchu.';

  @override
  String get movementResponseIncompatible =>
      'Odpowiedź ruchu jest niezgodna z tym klientem.';

  @override
  String get movementSessionUnavailable =>
      'Lokalna sesja gry jest niedostępna.';

  @override
  String get moveRejectedStale =>
      'Stan gry uległ zmianie. Sprawdź aktualną pozycję i spróbuj ponownie.';

  @override
  String get moveRejectedUnitUnavailable =>
      'Ta jednostka nie jest już dostępna do ruchu.';

  @override
  String get moveRejectedUnitBusy =>
      'Ta jednostka jest zajęta i nie może się teraz ruszyć.';

  @override
  String get moveRejectedTargetUnavailable =>
      'To pole docelowe jest niedostępne.';

  @override
  String get moveRejectedMovementInsufficient =>
      'Jednostka nie ma wystarczającej liczby punktów ruchu.';

  @override
  String get moveRejectedPathUnavailable =>
      'Brak dostępnej prawidłowej trasy do tego celu.';

  @override
  String get moveRejectedInternal =>
      'Nie udało się zastosować ruchu. Spróbuj ponownie.';

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
