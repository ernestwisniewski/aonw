import 'package:flutter/widgets.dart';

import '../application/worker_state.dart';
import '../read_model/worker_view.dart';

enum WorkerText {
  title,
  loading,
  empty,
  executing,
  buildCharges,
  progress,
  assigned,
  selectImprovement,
  confirmImprovement,
  cancelJob,
  assign,
  cancelAssignment,
  buildRoad,
  automate,
  automationEvidence,
}

final class WorkerCopy {
  const WorkerCopy._(this._texts, this._failures);

  factory WorkerCopy.of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pl'
      ? const WorkerCopy._(_polishText, _polishFailures)
      : const WorkerCopy._(_englishText, _englishFailures);

  final Map<WorkerText, String> _texts;
  final Map<String, String> _failures;

  String text(WorkerText key) => _texts[key]!;

  String failure(WorkerFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _failures[key] ?? _failures['requestFailed']!;
  }

  String improvement(String name) => name
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)!.toLowerCase()}',
      )
      .replaceFirstMapped(
        RegExp(r'^.'),
        (match) => match.group(0)!.toUpperCase(),
      );

  String automationAction(WorkerAutomationActionView action) =>
      switch (action) {
        ImproveWorkerAutomationActionView(improvement: final kind) =>
          improvement(kind.name),
        AssignWorkerAutomationActionView() => text(WorkerText.assign),
      };
}

const _englishText = <WorkerText, String>{
  WorkerText.title: 'Worker',
  WorkerText.loading: 'Loading worker options',
  WorkerText.empty: 'No worker action is currently available.',
  WorkerText.executing: 'Applying worker action',
  WorkerText.buildCharges: 'Build charges',
  WorkerText.progress: 'Progress',
  WorkerText.assigned: 'Assigned hex',
  WorkerText.selectImprovement: 'Select',
  WorkerText.confirmImprovement: 'Confirm improvement',
  WorkerText.cancelJob: 'Cancel construction',
  WorkerText.assign: 'Assign to hex',
  WorkerText.cancelAssignment: 'Cancel assignment',
  WorkerText.buildRoad: 'Build road',
  WorkerText.automate: 'Automate',
  WorkerText.automationEvidence: 'Planner evidence',
};

const _polishText = <WorkerText, String>{
  WorkerText.title: 'Robotnik',
  WorkerText.loading: 'Ładowanie opcji robotnika',
  WorkerText.empty: 'Brak dostępnych akcji robotnika.',
  WorkerText.executing: 'Wykonywanie akcji robotnika',
  WorkerText.buildCharges: 'Ładunki budowy',
  WorkerText.progress: 'Postęp',
  WorkerText.assigned: 'Przypisane pole',
  WorkerText.selectImprovement: 'Wybierz',
  WorkerText.confirmImprovement: 'Potwierdź ulepszenie',
  WorkerText.cancelJob: 'Anuluj budowę',
  WorkerText.assign: 'Przypisz do pola',
  WorkerText.cancelAssignment: 'Anuluj przypisanie',
  WorkerText.buildRoad: 'Zbuduj drogę',
  WorkerText.automate: 'Automatyzuj',
  WorkerText.automationEvidence: 'Dane planera',
};

const _englishFailures = <String, String>{
  'requestFailed': 'The worker request could not be completed.',
  'responseIncompatible':
      'The worker response is incompatible with this client.',
  'sessionUnavailable': 'The local game session is unavailable.',
  'staleRevision': 'The game state changed. Review the worker and try again.',
  'matchFinished': 'The match has already finished.',
  'workerNotFound': 'The worker is no longer available.',
  'workerNotControlled': 'The worker is not controlled by this player.',
  'workerUnavailable': 'The worker is unavailable.',
  'workerNoMovementPoints': 'The worker has no movement points.',
  'workerQueuedPathActive': 'The worker has an active movement order.',
  'workerImprovementNotSelected': 'Select an improvement first.',
  'workerActionNotControlled': 'The pending worker action is not controlled.',
  'workerImprovementUnavailable': 'That improvement is unavailable.',
  'workerJobNotActive': 'The worker has no active construction.',
  'workerAssignmentUnavailable': 'The worker cannot be assigned here.',
  'workerAssignmentNotActive': 'The worker has no active assignment.',
  'workerRoadUnavailable': 'Road construction is unavailable here.',
  'roadConstructionExistingRoad': 'A road already exists here.',
  'roadConstructionCity': 'A road cannot be built on a city center.',
  'roadConstructionEnemyTerritory':
      'A road cannot be built in enemy territory.',
  'roadConstructionImpassableTerrain':
      'A road cannot be built on this terrain.',
  'workerAutomationNotActive': 'Worker automation is not active.',
  'workerAutomationNoTarget': 'Worker automation found no target.',
  'stateRevisionOverflow': 'The game state cannot advance further.',
};

const _polishFailures = <String, String>{
  'requestFailed': 'Nie udało się wykonać żądania robotnika.',
  'responseIncompatible': 'Odpowiedź robotnika jest niezgodna z klientem.',
  'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
  'staleRevision': 'Stan gry uległ zmianie. Sprawdź robotnika ponownie.',
  'matchFinished': 'Rozgrywka już się zakończyła.',
  'workerNotFound': 'Robotnik nie jest już dostępny.',
  'workerNotControlled': 'Robotnik nie należy do tego gracza.',
  'workerUnavailable': 'Robotnik jest niedostępny.',
  'workerNoMovementPoints': 'Robotnik nie ma punktów ruchu.',
  'workerQueuedPathActive': 'Robotnik ma aktywny rozkaz ruchu.',
  'workerImprovementNotSelected': 'Najpierw wybierz ulepszenie.',
  'workerActionNotControlled':
      'Oczekująca akcja robotnika nie jest kontrolowana.',
  'workerImprovementUnavailable': 'To ulepszenie jest niedostępne.',
  'workerJobNotActive': 'Robotnik nie prowadzi budowy.',
  'workerAssignmentUnavailable': 'Nie można przypisać robotnika do tego pola.',
  'workerAssignmentNotActive': 'Robotnik nie ma aktywnego przypisania.',
  'workerRoadUnavailable': 'Nie można tutaj zbudować drogi.',
  'roadConstructionExistingRoad': 'Na tym polu jest już droga.',
  'roadConstructionCity': 'Nie można budować drogi w centrum miasta.',
  'roadConstructionEnemyTerritory': 'Nie można budować drogi na terenie wroga.',
  'roadConstructionImpassableTerrain':
      'Na tym terenie nie można zbudować drogi.',
  'workerAutomationNotActive': 'Automatyzacja robotnika nie jest aktywna.',
  'workerAutomationNoTarget': 'Automatyzacja nie znalazła celu.',
  'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
};
