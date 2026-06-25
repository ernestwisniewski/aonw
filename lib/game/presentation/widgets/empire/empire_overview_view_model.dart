import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';

class EmpireOverviewViewModel {
  const EmpireOverviewViewModel({
    required this.units,
    required this.cities,
    required this.unitGroups,
    required this.cityComparisons,
    required this.readyUnitCount,
    required this.totalPopulation,
    this.storedArtifactsByCityId = const {},
  });

  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<EmpireUnitGroup> unitGroups;
  final List<EmpireCityComparison> cityComparisons;
  final int readyUnitCount;
  final int totalPopulation;
  final Map<String, WorldArtifact> storedArtifactsByCityId;

  int get storedArtifactCount => storedArtifactsByCityId.length;

  String subtitle(AppLocalizations l10n) =>
      '${empireCityCountLabel(l10n, cities.length)} - '
      '${empireUnitCountLabel(l10n, units.length)}';

  factory EmpireOverviewViewModel.fromState(
    GameState state, {
    required String activePlayerId,
    MapData? mapData,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final units = _ownedUnits(state, activePlayerId);
    final cities = _ownedCities(state, activePlayerId);
    final storedArtifactsByCityId = _storedArtifactsByCityId(state, cities);

    return EmpireOverviewViewModel(
      units: units,
      cities: cities,
      unitGroups: _groupUnits(units),
      cityComparisons: _cityComparisons(
        state: state,
        cities: cities,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
      readyUnitCount: units.where((unit) => unit.movementPoints > 0).length,
      totalPopulation: cities.fold<int>(
        0,
        (total, city) => total + city.population,
      ),
      storedArtifactsByCityId: storedArtifactsByCityId,
    );
  }

  static List<EmpireCityComparison> _cityComparisons({
    required GameState state,
    required List<GameCity> cities,
    required MapData? mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    final comparisons =
        [
          for (final city in cities)
            _cityComparison(
              state: state,
              city: city,
              mapData: mapData,
              cityRuleset: cityRuleset,
              technologyRuleset: technologyRuleset,
              paceBalance: paceBalance,
            ),
        ]..sort((a, b) {
          final population = b.population.compareTo(a.population);
          if (population != 0) return population;
          final production = b.production.compareTo(a.production);
          if (production != 0) return production;
          return a.city.name.compareTo(b.city.name);
        });
    return List.unmodifiable(comparisons);
  }

  static EmpireCityComparison _cityComparison({
    required GameState state,
    required GameCity city,
    required MapData? mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required PaceBalance paceBalance,
  }) {
    if (mapData == null) {
      return EmpireCityComparison(
        city: city,
        storedArtifact: _storedArtifactForCity(
          artifacts: state.artifacts,
          cityId: city.id,
        ),
        population: city.population,
        production: 0,
        food: 0,
        gold: 0,
        defense: 0,
        buildings: city.buildings.length,
        territory: city.controlledHexes.length + 1,
      );
    }

    final tileYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final economy = CityEconomyBreakdown.from(
      city: city,
      tileYield: tileYield,
      mapData: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
      paceBalance: paceBalance,
    );
    return EmpireCityComparison(
      city: city,
      storedArtifact: _storedArtifactForCity(
        artifacts: state.artifacts,
        cityId: city.id,
      ),
      population: city.population,
      production: CityProductionRules.productionPerTurn(
        economy.netYield.production,
      ),
      food: economy.foodDeposit,
      gold: _nonNegative(economy.netYield.gold),
      defense: _nonNegative(economy.netYield.defense),
      buildings: city.buildings.length,
      territory: city.controlledHexes.length + 1,
    );
  }

  static int _nonNegative(int value) => value < 0 ? 0 : value;

  static Map<String, WorldArtifact> _storedArtifactsByCityId(
    GameState state,
    List<GameCity> cities,
  ) {
    final cityIds = {for (final city in cities) city.id};
    return Map.unmodifiable({
      for (final artifact in state.artifacts)
        if (artifact.location.isStored &&
            artifact.location.cityId != null &&
            cityIds.contains(artifact.location.cityId))
          artifact.location.cityId!: artifact,
    });
  }

  static WorldArtifact? _storedArtifactForCity({
    required List<WorldArtifact> artifacts,
    required String cityId,
  }) {
    for (final artifact in artifacts) {
      final location = artifact.location;
      if (location.isStored && location.cityId == cityId) {
        return artifact;
      }
    }
    return null;
  }

  static List<GameUnit> _ownedUnits(GameState state, String activePlayerId) {
    final units =
        [
          for (final unit in state.units)
            if (unit.ownerPlayerId == activePlayerId) unit,
        ]..sort((a, b) {
          final type = a.type.index.compareTo(b.type.index);
          if (type != 0) return type;
          final name = a.name.compareTo(b.name);
          if (name != 0) return name;
          return a.id.compareTo(b.id);
        });
    return List.unmodifiable(units);
  }

  static List<GameCity> _ownedCities(GameState state, String activePlayerId) {
    final cities =
        [
          for (final city in state.cities)
            if (city.ownerPlayerId == activePlayerId) city,
        ]..sort((a, b) {
          final name = a.name.compareTo(b.name);
          if (name != 0) return name;
          return a.id.compareTo(b.id);
        });
    return List.unmodifiable(cities);
  }

  static List<EmpireUnitGroup> _groupUnits(List<GameUnit> units) {
    final grouped = <GameUnitType, List<GameUnit>>{};
    for (final unit in units) {
      grouped.putIfAbsent(unit.type, () => []).add(unit);
    }
    return List.unmodifiable([
      for (final type in GameUnitType.values)
        if (grouped[type]?.isNotEmpty ?? false)
          EmpireUnitGroup(type: type, units: List.unmodifiable(grouped[type]!)),
    ]);
  }
}

class EmpireCityComparison {
  const EmpireCityComparison({
    required this.city,
    required this.population,
    required this.production,
    required this.food,
    required this.gold,
    required this.defense,
    required this.buildings,
    required this.territory,
    this.storedArtifact,
  });

  final GameCity city;
  final WorldArtifact? storedArtifact;
  final int population;
  final int production;
  final int food;
  final int gold;
  final int defense;
  final int buildings;
  final int territory;

  TileYield get yield => TileYield(
    food: food,
    production: production,
    gold: gold,
    defense: defense,
  );
}

class EmpireUnitGroup {
  const EmpireUnitGroup({required this.type, required this.units});

  final GameUnitType type;
  final List<GameUnit> units;

  int get readyUnitCount =>
      units.where((unit) => unit.movementPoints > 0).length;
}

String empireUnitSubtitle(AppLocalizations l10n, GameUnit unit) {
  final parts = <String>[l10n.empireUnitMovement(unit.movementPoints)];
  if (unit.isFortified) {
    parts.add(
      UnitFortificationRules.canHeal(unit)
          ? l10n.empireUnitHealing
          : l10n.empireUnitFortifying,
    );
  }
  if (unit.workerJob != null) parts.add(l10n.empireUnitBuilding);
  if (unit.workerAssignment != null) parts.add(l10n.empireUnitWorking);
  if (unit.queuedPath != null) parts.add(l10n.empireUnitEnRoute);
  return parts.join(' - ');
}

String empireUnitGroupSubtitle(AppLocalizations l10n, EmpireUnitGroup group) {
  final label = empireUnitCountLabel(l10n, group.units.length);
  final ready = group.readyUnitCount;
  final readyLabel = ready == 0
      ? l10n.empireUnitNoMovement
      : l10n.empireUnitsWithMovement(ready);
  return '$label - $readyLabel';
}

String empireCitySubtitle(
  AppLocalizations l10n,
  GameCity city, {
  WorldArtifact? storedArtifact,
}) {
  final base = l10n.empireCitySubtitle(
    city.population,
    city.controlledHexes.length + 1,
    city.buildings.length,
    empireCityProductionLabel(l10n, city),
  );
  if (storedArtifact == null) return base;
  final artifactName = GameDisplayNames.worldArtifact(
    l10n,
    storedArtifact.type,
  );
  return '$base - ${l10n.empireCityStoredArtifact(artifactName)}';
}

String empireCityProductionLabel(AppLocalizations l10n, GameCity city) {
  final target = city.productionQueue?.target;
  if (target == null) return l10n.productionNoProduction;
  return switch (target) {
    BuildingProductionTarget(:final buildingType) =>
      GameDisplayNames.cityBuilding(l10n, buildingType),
    UnitProductionTarget(:final unitType) => GameDisplayNames.unitType(
      l10n,
      unitType,
    ),
    ProjectProductionTarget(:final projectType) => GameDisplayNames.cityProject(
      l10n,
      projectType,
    ),
  };
}

String empireCityGroupSubtitle(AppLocalizations l10n, List<GameCity> cities) {
  final label = empireCityCountLabel(l10n, cities.length);
  final population = cities.fold<int>(
    0,
    (total, city) => total + city.population,
  );
  return l10n.empireCityGroupSubtitle(label, population);
}

String empireUnitCountLabel(AppLocalizations l10n, int count) {
  return l10n.empireUnitCountLabel(count);
}

String empireCityCountLabel(AppLocalizations l10n, int count) {
  return l10n.empireCityCountLabel(count);
}
