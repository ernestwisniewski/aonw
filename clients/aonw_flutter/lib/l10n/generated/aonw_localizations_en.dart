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
  String unitActionLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'title': 'Unit actions',
      'fortify': 'Fortify',
      'skip': 'Skip',
      'cancel': 'Cancel action',
      'executing': 'Executing unit action',
      'other': 'Unit action',
    });
    return '$_temp0';
  }

  @override
  String unitActionFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'The unit action request could not be completed.',
      'responseIncompatible':
          'The unit action response is incompatible with this client.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'stale': 'The game state changed. Review the unit and try again.',
      'matchFinished': 'The match has already finished.',
      'unitUnavailable': 'That unit is no longer available to command.',
      'unitBusy': 'That unit is busy and cannot perform this action now.',
      'internal': 'The unit action could not be applied. Try again.',
      'other': 'The unit action could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String turnSummary(String kind, int turn, int submitted, int required) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'label': 'TURN $turn',
      'progress': 'Ready: $submitted of $required',
      'other': 'TURN $turn',
    });
    return '$_temp0';
  }

  @override
  String turnText(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'statusActive': 'Your turn',
      'statusFinished': 'Turn finished',
      'statusSubmitted': 'Turn submitted',
      'statusWaiting': 'Waiting',
      'statusPendingAction': 'Action required',
      'actionEnd': 'End turn',
      'actionEnding': 'Ending turn',
      'outcomeConquest': 'Conquest victory',
      'outcomeDomination': 'Domination victory',
      'outcomeCultural': 'Cultural victory',
      'outcomeScore': 'Score victory',
      'outcomeResignation': 'Match ended by resignation',
      'outcomeDraw': 'Draw',
      'outcomeOngoing': 'Match in progress',
      'activityTitle': 'Activity',
      'activityArtifact': 'Artifact activity',
      'activityCity': 'City activity',
      'activityResearch': 'Research progress',
      'activityObjective': 'Strategic objective update',
      'activityOutcome': 'Match outcome updated',
      'activityCombat': 'Combat activity',
      'activityDiplomacy': 'Diplomatic activity',
      'activityUnit': 'Unit activity',
      'activityTurn': 'Turn updated',
      'activityWorker': 'Worker job completed',
      'other': 'Game activity',
    });
    return '$_temp0';
  }

  @override
  String turnFailure(String failure) {
    String _temp0 = intl.Intl.selectLogic(failure, {
      'requestFailed': 'The turn request could not be completed.',
      'responseIncompatible':
          'The turn response is incompatible with this client.',
      'sessionUnavailable': 'The local game session is unavailable.',
      'stale_revision': 'The game state changed. Review it and try again.',
      'match_finished': 'The match has already finished.',
      'turn_player_not_controlled': 'This player cannot end the current turn.',
      'turn_player_not_active': 'This player is not active.',
      'turn_scope_invalid': 'The current turn scope is invalid.',
      'turn_processor_unsupported': 'A required turn processor is unavailable.',
      'turn_number_overflow': 'The next turn cannot be represented.',
      'state_revision_overflow': 'The game revision cannot be advanced.',
      'other': 'The turn could not be completed.',
    });
    return '$_temp0';
  }

  @override
  String get loadingMap => 'Loading map';

  @override
  String get mapLoadingFailed => 'Map loading failed';

  @override
  String get mapUnavailable => 'Map unavailable';

  @override
  String get mapAdapterUnavailable =>
      'The native game adapter is unavailable on this platform.';

  @override
  String get mapClientIncompatible =>
      'The native game adapter is incompatible with this client.';

  @override
  String get mapLoadSuperseded => 'A newer map request replaced this one.';

  @override
  String get mapLoadFailure => 'The map could not be loaded.';

  @override
  String get movementRequestFailed =>
      'The movement request could not be completed.';

  @override
  String get movementResponseIncompatible =>
      'The movement response is incompatible with this client.';

  @override
  String get movementSessionUnavailable =>
      'The local game session is unavailable.';

  @override
  String get moveRejectedStale =>
      'The game state changed. Review the latest position and try again.';

  @override
  String get moveRejectedUnitUnavailable =>
      'That unit is no longer available to move.';

  @override
  String get moveRejectedUnitBusy => 'That unit is busy and cannot move now.';

  @override
  String get moveRejectedTargetUnavailable =>
      'That destination is not available.';

  @override
  String get moveRejectedMovementInsufficient =>
      'The unit does not have enough movement remaining.';

  @override
  String get moveRejectedPathUnavailable =>
      'No valid route to that destination is available.';

  @override
  String get moveRejectedInternal =>
      'The move could not be applied. Try again.';

  @override
  String get retry => 'Retry';

  @override
  String get openSettings => 'Open settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get audioSettings => 'Audio';

  @override
  String get masterVolume => 'Master volume';

  @override
  String get cameraSettings => 'Camera';

  @override
  String get cameraSensitivity => 'Zoom sensitivity';

  @override
  String get accessibilitySettings => 'Accessibility';

  @override
  String get reducedMotion => 'Reduce motion';

  @override
  String get reducedMotionDescription =>
      'Avoid nonessential animations and transitions.';

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastDescription =>
      'Increase contrast in the application interface.';

  @override
  String get resetSettings => 'Restore defaults';
}
