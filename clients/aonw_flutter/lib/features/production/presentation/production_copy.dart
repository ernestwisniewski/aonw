import 'package:flutter/widgets.dart';

import '../application/production_state.dart';
import '../read_model/production_view.dart';

enum ProductionText {
  title,
  loading,
  executing,
  current,
  invested,
  overflow,
  resources,
  buildings,
  units,
  projects,
  wonders,
  specializations,
  rush,
  cost,
  requires,
  empty,
}

final class ProductionCopy {
  const ProductionCopy._(this._texts, this._failures);

  factory ProductionCopy.of(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'pl'
      ? const ProductionCopy._(_polishText, _polishFailures)
      : const ProductionCopy._(_englishText, _englishFailures);

  final Map<ProductionText, String> _texts;
  final Map<String, String> _failures;

  String text(ProductionText key) => _texts[key]!;

  String failure(ProductionFailureView failure) =>
      rejection(failure.rejectionCode) ??
      _failures[failure.code.name] ??
      _failures['requestFailed']!;

  String? rejection(ProductionRejectionCodeView? value) =>
      value == null ? null : _failures[value.name] ?? value.name;

  String name(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)!.toLowerCase()}',
      )
      .replaceFirstMapped(
        RegExp(r'^.'),
        (match) => match.group(0)!.toUpperCase(),
      );

  String target(ProductionTargetView value) => switch (value) {
    BuildingProductionTargetView(:final building) => name(building),
    UnitProductionTargetView(:final unit) => name(unit.name),
    ProjectProductionTargetView(:final project) => name(project),
    WonderProductionTargetView(:final wonder) => name(wonder),
  };
}

const _englishText = <ProductionText, String>{
  ProductionText.title: 'Production and resources',
  ProductionText.loading: 'Loading production options',
  ProductionText.executing: 'Updating city production',
  ProductionText.current: 'Current production',
  ProductionText.invested: 'Invested',
  ProductionText.overflow: 'Overflow',
  ProductionText.resources: 'Strategic resources',
  ProductionText.buildings: 'Buildings',
  ProductionText.units: 'Units',
  ProductionText.projects: 'Projects',
  ProductionText.wonders: 'Wonders',
  ProductionText.specializations: 'Specializations',
  ProductionText.rush: 'Rush production',
  ProductionText.cost: 'cost',
  ProductionText.requires: 'requires',
  ProductionText.empty: 'No option is currently available.',
};

const _polishText = <ProductionText, String>{
  ProductionText.title: 'Produkcja i zasoby',
  ProductionText.loading: 'Ładowanie opcji produkcji',
  ProductionText.executing: 'Aktualizacja produkcji miasta',
  ProductionText.current: 'Bieżąca produkcja',
  ProductionText.invested: 'Zainwestowano',
  ProductionText.overflow: 'Nadwyżka',
  ProductionText.resources: 'Zasoby strategiczne',
  ProductionText.buildings: 'Budynki',
  ProductionText.units: 'Jednostki',
  ProductionText.projects: 'Projekty',
  ProductionText.wonders: 'Cuda',
  ProductionText.specializations: 'Specjalizacje',
  ProductionText.rush: 'Przyspiesz produkcję',
  ProductionText.cost: 'koszt',
  ProductionText.requires: 'wymaga',
  ProductionText.empty: 'Brak dostępnych opcji.',
};

const _englishFailures = <String, String>{
  'requestFailed': 'The production request could not be completed.',
  'responseIncompatible': 'The production response is incompatible.',
  'sessionUnavailable': 'The local game session is unavailable.',
  'staleRevision': 'The city changed. Review production and try again.',
  'matchFinished': 'The match has already finished.',
  'cityNotFound': 'The city is no longer available.',
  'cityNotControlled': 'The city is not controlled by this player.',
  'buildingNotAvailable': 'This building is unavailable.',
  'unitProductionInvalidResourceOption': 'That resource option is invalid.',
  'unitProductionNotAvailable': 'This unit is unavailable.',
  'unitProductionRequiresResource': 'Select a resource option.',
  'unitProductionMissingStrategicResource': 'Required resources are missing.',
  'unitProductionRequiresCoast': 'This unit requires a coastal city.',
  'unitSupplyLimitReached': 'The unit supply limit is reached.',
  'wonderNotAvailable': 'This wonder is unavailable.',
  'citySpecializationLocked': 'This specialization is locked.',
  'citySpecializationUnchanged': 'This specialization is already active.',
  'citySpecializationMissingBuilding': 'A required building is missing.',
  'productionQueueEmpty': 'The production queue is empty.',
  'projectCannotBeRushed': 'A continuous project cannot be rushed.',
  'rushProductionUnavailable': 'Rush production is unavailable.',
  'stateRevisionOverflow': 'The game state cannot advance further.',
};

const _polishFailures = <String, String>{
  'requestFailed': 'Nie udało się wykonać żądania produkcji.',
  'responseIncompatible': 'Odpowiedź produkcji jest niezgodna z klientem.',
  'sessionUnavailable': 'Lokalna sesja gry jest niedostępna.',
  'staleRevision': 'Miasto uległo zmianie. Sprawdź produkcję ponownie.',
  'matchFinished': 'Rozgrywka już się zakończyła.',
  'cityNotFound': 'Miasto nie jest już dostępne.',
  'cityNotControlled': 'Miasto nie należy do tego gracza.',
  'buildingNotAvailable': 'Ten budynek jest niedostępny.',
  'unitProductionInvalidResourceOption': 'Ta opcja zasobów jest nieprawidłowa.',
  'unitProductionNotAvailable': 'Ta jednostka jest niedostępna.',
  'unitProductionRequiresResource': 'Wybierz opcję zasobów.',
  'unitProductionMissingStrategicResource': 'Brakuje wymaganych zasobów.',
  'unitProductionRequiresCoast': 'Ta jednostka wymaga miasta nadbrzeżnego.',
  'unitSupplyLimitReached': 'Osiągnięto limit jednostek.',
  'wonderNotAvailable': 'Ten cud jest niedostępny.',
  'citySpecializationLocked': 'Ta specjalizacja jest zablokowana.',
  'citySpecializationUnchanged': 'Ta specjalizacja jest już aktywna.',
  'citySpecializationMissingBuilding': 'Brakuje wymaganego budynku.',
  'productionQueueEmpty': 'Kolejka produkcji jest pusta.',
  'projectCannotBeRushed': 'Nie można przyspieszyć projektu ciągłego.',
  'rushProductionUnavailable': 'Przyspieszenie produkcji jest niedostępne.',
  'stateRevisionOverflow': 'Stan gry nie może przejść dalej.',
};
