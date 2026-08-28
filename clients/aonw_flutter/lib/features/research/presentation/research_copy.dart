import 'package:flutter/widgets.dart';

import '../application/research_state.dart';
import '../read_model/research_view.dart';

enum ResearchText {
  title,
  open,
  close,
  loading,
  retry,
  selecting,
  selectionRequired,
  sciencePerTurn,
  overflow,
  active,
  none,
  cost,
  progress,
  boost,
  prerequisites,
  blockedBy,
  unlocks,
  select,
}

final class ResearchCopy {
  const ResearchCopy._(this._texts, this._failures);

  factory ResearchCopy.of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pl'
      ? const ResearchCopy._(_polishText, _polishFailures)
      : const ResearchCopy._(_englishText, _englishFailures);

  final Map<ResearchText, String> _texts;
  final Map<String, String> _failures;

  String text(ResearchText key) => _texts[key]!;

  String name(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)!.toLowerCase()}',
      )
      .replaceFirstMapped(
        RegExp(r'^.'),
        (match) => match.group(0)!.toUpperCase(),
      );

  String technology(TechnologyIdView value) => name(value.name);

  String availability(TechnologyAvailabilityView value) =>
      _failures['availability.${value.name}'] ?? name(value.name);

  String unlock(TechnologyUnlockView value) =>
      '${name(value.kind.name)}: ${name(value.target)}';

  String failure(ResearchFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _failures[key] ?? _failures['requestFailed']!;
  }
}

const _englishText = <ResearchText, String>{
  ResearchText.title: 'Research',
  ResearchText.open: 'Open research',
  ResearchText.close: 'Close research',
  ResearchText.loading: 'Loading research options',
  ResearchText.retry: 'Retry',
  ResearchText.selecting: 'Selecting technology',
  ResearchText.selectionRequired: 'Select a technology to continue',
  ResearchText.sciencePerTurn: 'Science per turn',
  ResearchText.overflow: 'Stored science',
  ResearchText.active: 'Active technology',
  ResearchText.none: 'None',
  ResearchText.cost: 'Cost',
  ResearchText.progress: 'Progress',
  ResearchText.boost: 'Boost discount',
  ResearchText.prerequisites: 'Prerequisites',
  ResearchText.blockedBy: 'Blocked by',
  ResearchText.unlocks: 'Unlocks',
  ResearchText.select: 'Select',
};

const _polishText = <ResearchText, String>{
  ResearchText.title: 'Badania',
  ResearchText.open: 'Otwórz badania',
  ResearchText.close: 'Zamknij badania',
  ResearchText.loading: 'Ładowanie opcji badań',
  ResearchText.retry: 'Ponów',
  ResearchText.selecting: 'Wybieranie technologii',
  ResearchText.selectionRequired: 'Wybierz technologię, aby kontynuować',
  ResearchText.sciencePerTurn: 'Nauka na turę',
  ResearchText.overflow: 'Zachowana nauka',
  ResearchText.active: 'Aktywna technologia',
  ResearchText.none: 'Brak',
  ResearchText.cost: 'Koszt',
  ResearchText.progress: 'Postęp',
  ResearchText.boost: 'Rabat za premię',
  ResearchText.prerequisites: 'Wymagania',
  ResearchText.blockedBy: 'Blokowane przez',
  ResearchText.unlocks: 'Odblokowuje',
  ResearchText.select: 'Wybierz',
};

const _englishFailures = <String, String>{
  'requestFailed': 'The research request could not be completed.',
  'responseIncompatible': 'The research response is incompatible.',
  'sessionUnavailable': 'The local game session is unavailable.',
  'staleRevision': 'Research changed. Review the options and try again.',
  'technologyPlayerNotControlled': 'This player cannot select research.',
  'technologyNotAvailable': 'This technology is not available.',
  'stateRevisionOverflow': 'The game state cannot advance further.',
  'availability.unlocked': 'Researched',
  'availability.active': 'Active',
  'availability.available': 'Available',
  'availability.lockedByPrerequisites': 'Prerequisites required',
  'availability.lockedByTechnology': 'Blocked by technology',
};

const _polishFailures = <String, String>{
  'requestFailed': 'Nie udało się wykonać żądania badań.',
  'responseIncompatible': 'Odpowiedź badań jest niezgodna z klientem.',
  'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
  'staleRevision': 'Stan badań uległ zmianie. Sprawdź opcje ponownie.',
  'technologyPlayerNotControlled': 'Ten gracz nie może wybrać badań.',
  'technologyNotAvailable': 'Ta technologia jest niedostępna.',
  'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
  'availability.unlocked': 'Zbadana',
  'availability.active': 'Aktywna',
  'availability.available': 'Dostępna',
  'availability.lockedByPrerequisites': 'Wymaga wcześniejszych technologii',
  'availability.lockedByTechnology': 'Zablokowana przez technologię',
};
