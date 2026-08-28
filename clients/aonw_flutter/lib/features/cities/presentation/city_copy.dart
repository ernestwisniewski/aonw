import 'package:flutter/widgets.dart';

import '../application/city_state.dart';

enum CityText {
  title,
  foundingTitle,
  loading,
  owner,
  health,
  population,
  territory,
  foundingSelection,
  foundingConfirm,
  executing,
  cityYield,
  food,
  production,
  gold,
  defense,
  workedHexes,
  expansion,
  foundingOpen,
}

final class CityCopy {
  const CityCopy._(this._texts, this._failures);

  factory CityCopy.of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pl'
      ? const CityCopy._(_polishText, _polishFailures)
      : const CityCopy._(_englishText, _englishFailures);

  final Map<CityText, String> _texts;
  final Map<String, String> _failures;

  String text(CityText key) => _texts[key]!;

  String failure(CityFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _failures[key] ?? _failures['requestFailed']!;
  }
}

const _englishText = <CityText, String>{
  CityText.title: 'City',
  CityText.foundingTitle: 'Found a city',
  CityText.loading: 'Loading city details',
  CityText.owner: 'Owner',
  CityText.health: 'Health',
  CityText.population: 'Population',
  CityText.territory: 'Territory',
  CityText.foundingSelection: 'Initial territory',
  CityText.foundingConfirm: 'Confirm city founding',
  CityText.executing: 'Applying city action',
  CityText.cityYield: 'Yield',
  CityText.food: 'Food',
  CityText.production: 'Production',
  CityText.gold: 'Gold',
  CityText.defense: 'Defense',
  CityText.workedHexes: 'Worked hexes',
  CityText.expansion: 'Preferred expansion',
  CityText.foundingOpen: 'Plan a city',
};

const _polishText = <CityText, String>{
  CityText.title: 'Miasto',
  CityText.foundingTitle: 'Załóż miasto',
  CityText.loading: 'Ładowanie danych miasta',
  CityText.owner: 'Właściciel',
  CityText.health: 'Zdrowie',
  CityText.population: 'Populacja',
  CityText.territory: 'Terytorium',
  CityText.foundingSelection: 'Terytorium początkowe',
  CityText.foundingConfirm: 'Potwierdź założenie miasta',
  CityText.executing: 'Wykonywanie akcji miasta',
  CityText.cityYield: 'Dochód',
  CityText.food: 'Żywność',
  CityText.production: 'Produkcja',
  CityText.gold: 'Złoto',
  CityText.defense: 'Obrona',
  CityText.workedHexes: 'Pola robocze',
  CityText.expansion: 'Preferowana ekspansja',
  CityText.foundingOpen: 'Zaplanuj miasto',
};

const _englishFailures = <String, String>{
  'requestFailed': 'The city request could not be completed.',
  'responseIncompatible': 'The city response is incompatible with this client.',
  'sessionUnavailable': 'The local game session is unavailable.',
  'staleRevision': 'The game state changed. Review the city and try again.',
  'matchFinished': 'The match has already finished.',
  'cityFounderNotFound': 'The founding unit is no longer available.',
  'cityFounderNotControlled':
      'The founding unit is not controlled by this player.',
  'cityFounderBusy': 'The founding unit is busy.',
  'cityFounderInvalid': 'That unit cannot found a city.',
  'cityFounderNoSettlers': 'The founding unit has no settlers.',
  'citySiteInvalid': 'A city cannot be founded at that site.',
  'cityCenterOccupied': 'The city center is occupied.',
  'cityCenterClaimed': 'The city center is already claimed.',
  'cityCenterTooClose': 'The city center is too close to another city.',
  'cityControlledHexesInvalid': 'The selected initial territory is invalid.',
  'cityNotFound': 'That city is no longer available.',
  'cityNotControlled': 'That city is not controlled by this player.',
  'workedHexUnavailable': 'That worked hex is unavailable.',
  'workedHexLimitReached': 'The city has reached its worked-hex limit.',
  'cityExpansionHexUnavailable': 'That expansion hex is unavailable.',
  'stateRevisionOverflow': 'The game state cannot advance further.',
};

const _polishFailures = <String, String>{
  'requestFailed': 'Nie udało się wykonać żądania miasta.',
  'responseIncompatible': 'Odpowiedź miasta jest niezgodna z tym klientem.',
  'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
  'staleRevision': 'Stan gry uległ zmianie. Sprawdź miasto i spróbuj ponownie.',
  'matchFinished': 'Rozgrywka już się zakończyła.',
  'cityFounderNotFound': 'Jednostka zakładająca miasto nie jest już dostępna.',
  'cityFounderNotControlled':
      'Jednostka zakładająca miasto nie należy do tego gracza.',
  'cityFounderBusy': 'Jednostka zakładająca miasto jest zajęta.',
  'cityFounderInvalid': 'Ta jednostka nie może założyć miasta.',
  'cityFounderNoSettlers': 'Jednostka nie ma osadników.',
  'citySiteInvalid': 'W tym miejscu nie można założyć miasta.',
  'cityCenterOccupied': 'Centrum miasta jest zajęte.',
  'cityCenterClaimed': 'Centrum miasta jest już zajęte terytorialnie.',
  'cityCenterTooClose': 'Centrum miasta jest zbyt blisko innego miasta.',
  'cityControlledHexesInvalid':
      'Wybrane terytorium początkowe jest nieprawidłowe.',
  'cityNotFound': 'To miasto nie jest już dostępne.',
  'cityNotControlled': 'To miasto nie należy do tego gracza.',
  'workedHexUnavailable': 'To pole robocze jest niedostępne.',
  'workedHexLimitReached': 'Miasto osiągnęło limit pól roboczych.',
  'cityExpansionHexUnavailable': 'To pole ekspansji jest niedostępne.',
  'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
};
