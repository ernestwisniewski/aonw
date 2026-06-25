import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_requirement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

enum WorkerImprovementBlocker {
  notWorker,
  workerBusy,
  noMovementPoints,
  queuedPathActive,
  missingTile,
  cityCenter,
  outsideOwnedTerritory,
  existingImprovement,
  technologyLocked,
  missingResource,
  invalidTerrain,
  missingRiver,
}

enum WorkerImprovementTileAvailability {
  unavailable,
  availableNow,
  technologyLocked,
}

class WorkerImprovementLegality {
  final bool allowed;
  final WorkerImprovementBlocker? blocker;
  final TechnologyDefinition? requiredTechnology;
  final GameCity? city;

  const WorkerImprovementLegality._({
    required this.allowed,
    this.blocker,
    this.requiredTechnology,
    this.city,
  });

  const WorkerImprovementLegality.allowed({required GameCity city})
    : this._(allowed: true, city: city);

  const WorkerImprovementLegality.blocked(
    WorkerImprovementBlocker blocker, {
    TechnologyDefinition? requiredTechnology,
  }) : this._(
         allowed: false,
         blocker: blocker,
         requiredTechnology: requiredTechnology,
       );
}

abstract final class WorkerImprovementRules {
  static WorkerImprovementLegality evaluate({
    required GameUnit unit,
    required FieldImprovementType improvementType,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
    required ResearchState research,
    CityHex? targetHex,
    bool requireReadyWorker = true,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (!unit.isWorker) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.notWorker,
      );
    }
    if (requireReadyWorker && unit.isWorking) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.workerBusy,
      );
    }
    if (requireReadyWorker && unit.movementPoints <= 0) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.noMovementPoints,
      );
    }
    if (requireReadyWorker && unit.queuedPath != null) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.queuedPathActive,
      );
    }

    final currentHex = targetHex ?? CityHex(col: unit.col, row: unit.row);
    final tile = mapData.tileAt(currentHex.col, currentHex.row);
    if (tile == null) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.missingTile,
      );
    }

    if (cities.any(
      (city) => city.center.occupies(currentHex.col, currentHex.row),
    )) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.cityCenter,
      );
    }

    if (fieldImprovements.any(
      (improvement) => improvement.occupies(currentHex.col, currentHex.row),
    )) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.existingImprovement,
      );
    }

    final failure = FieldImprovementRules.requirementFailureFor(
      improvementType,
      tile,
      ruleset: cityRuleset,
    );
    if (failure != null) {
      return WorkerImprovementLegality.blocked(_mapFailure(failure));
    }

    final city = cityForImprovementHex(
      playerId: unit.ownerPlayerId,
      hex: currentHex,
      cities: cities,
    );
    if (city == null) {
      return const WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.outsideOwnedTerritory,
      );
    }

    final unlocked = TechnologyUnlockQuery.hasFieldImprovementUnlocked(
      playerId: unit.ownerPlayerId,
      improvementType: improvementType,
      research: research,
      ruleset: technologyRuleset,
    );
    if (!unlocked) {
      return WorkerImprovementLegality.blocked(
        WorkerImprovementBlocker.technologyLocked,
        requiredTechnology:
            TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
              improvementType: improvementType,
              ruleset: technologyRuleset,
            ),
      );
    }

    return WorkerImprovementLegality.allowed(city: city);
  }

  static WorkerImprovementTileAvailability availabilityForTile({
    required GameUnit unit,
    required CityHex targetHex,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
    required ResearchState research,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    var hasTechnologyLockedCandidate = false;
    for (final type in FieldImprovementType.values) {
      final legality = evaluate(
        unit: unit,
        improvementType: type,
        cities: cities,
        fieldImprovements: fieldImprovements,
        mapData: mapData,
        research: research,
        targetHex: targetHex,
        requireReadyWorker: false,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
      );
      if (legality.allowed) {
        return WorkerImprovementTileAvailability.availableNow;
      }
      if (legality.blocker == WorkerImprovementBlocker.technologyLocked) {
        hasTechnologyLockedCandidate = true;
      }
    }
    return hasTechnologyLockedCandidate
        ? WorkerImprovementTileAvailability.technologyLocked
        : WorkerImprovementTileAvailability.unavailable;
  }

  static GameCity? cityForImprovementHex({
    required String playerId,
    required CityHex hex,
    required Iterable<GameCity> cities,
  }) {
    for (final city in cities) {
      if (city.ownerPlayerId != playerId) continue;
      if (city.controlsHex(hex) && city.center != hex) {
        return city;
      }
    }
    return null;
  }

  static WorkerImprovementBlocker _mapFailure(
    FieldImprovementRequirementFailure failure,
  ) {
    return switch (failure.type) {
      FieldImprovementRequirementFailureType.missingResource =>
        WorkerImprovementBlocker.missingResource,
      FieldImprovementRequirementFailureType.invalidTerrain =>
        WorkerImprovementBlocker.invalidTerrain,
      FieldImprovementRequirementFailureType.missingRiver =>
        WorkerImprovementBlocker.missingRiver,
    };
  }
}
