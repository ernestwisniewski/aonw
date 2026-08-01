part of 'reducer_parity_fixture.dart';

const _requiredStartUnitFixtureIds = {
  'city-production-unit-not-found-rejected',
  'city-production-unit-wrong-actor-rejected',
  'city-production-unit-wrong-actor-compound-rejected',
  'city-production-unit-not-available-rejected',
  'city-production-unit-resource-required-rejected',
  'city-production-unit-coast-required-rejected',
  'city-production-unit-supply-full-rejected',
  'city-production-unit-overflow-accepted',
  'city-production-unit-import-coast-replacement-accepted',
  'city-production-unit-same-target-no-op-accepted',
  'city-production-unit-supply-bonuses-accepted',
};

const _requiredStartUnitRejectionReasons = {
  'city_not_found',
  'city_not_controlled',
  'unit_production_not_available',
  'unit_production_requires_resource',
  'unit_production_requires_coast',
  'unit_supply_limit_reached',
};

final class _StartUnitCorpusSummary {
  final fixtureIds = <String>{};
  final rejectionReasons = <String>{};

  void record(ReducerParityFixture fixture) {
    if (fixture.command is! StartUnitProductionCommand) return;
    fixtureIds.add(fixture.id);
    if (!fixture.expectedAccepted) {
      rejectionReasons.add(fixture.expectedReason!);
    }
  }
}

void _requireStartUnitCorpusCoverage(
  _StartUnitCorpusSummary summary,
  String family,
) {
  if (summary.fixtureIds.length != _requiredStartUnitFixtureIds.length ||
      !summary.fixtureIds.containsAll(_requiredStartUnitFixtureIds)) {
    throw StateError(
      '$family StartUnitProduction fixture ids must be exactly: '
      '${_requiredStartUnitFixtureIds.toList()..sort()}.',
    );
  }
  if (summary.rejectionReasons.length !=
          _requiredStartUnitRejectionReasons.length ||
      !summary.rejectionReasons.containsAll(
        _requiredStartUnitRejectionReasons,
      )) {
    throw StateError(
      '$family StartUnitProduction rejection reasons must be exactly: '
      '${_requiredStartUnitRejectionReasons.toList()..sort()}.',
    );
  }
}

typedef _StartUnitConditions = ({
  bool unitAvailable,
  bool resourcesAvailable,
  bool coastAvailable,
  bool supplyAvailable,
});

const _allStartUnitConditionsMet = (
  unitAvailable: true,
  resourcesAvailable: true,
  coastAvailable: true,
  supplyAvailable: true,
);

void _validateStartUnitCharacterizationFixture(ReducerParityFixture fixture) {
  final command = fixture.command;
  if (command is! StartUnitProductionCommand) return;
  _requireReviewedStartUnitFixtureShape(fixture);

  final city = fixture.state.cities.byId(command.cityId);
  if (fixture.id == 'city-production-unit-not-found-rejected') {
    _validateStartUnitNotFound(fixture, command, city);
    return;
  }
  if (city == null) {
    ReducerParityCorpus._fail(fixture, 'must target one existing city');
  }

  final conditions = _reviewedStartUnitConditions(fixture, command, city);
  if (_validateStartUnitWrongActor(fixture, command, city, conditions)) return;
  if (city.ownerPlayerId != fixture.actorPlayerId) {
    ReducerParityCorpus._fail(fixture, 'must target an actor-controlled city');
  }

  if (!fixture.expectedAccepted) {
    _validateRejectedStartUnit(fixture, command, conditions);
    return;
  }
  _validateAcceptedStartUnit(fixture, command, city, conditions);
}

void _requireReviewedStartUnitFixtureShape(ReducerParityFixture fixture) {
  if (!_requiredStartUnitFixtureIds.contains(fixture.id)) {
    ReducerParityCorpus._fail(
      fixture,
      'uses an unreviewed StartUnitProduction characterization id',
    );
  }
  if (fixture.state.cities.length < 2 ||
      fixture.state.cities.first.id != 'city_sentinel' ||
      fixture.state.turnStartedAt == null ||
      fixture.state.submittedPlayerIds.isEmpty ||
      fixture.expectedEvents.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve unrelated city, runtime, and empty-event sentinels',
    );
  }
}

void _validateStartUnitNotFound(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity? city,
) {
  if (command.cityId != 'missing_city' ||
      city != null ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_found') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize city_not_found before all later unit checks',
    );
  }
}

bool _validateStartUnitWrongActor(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
  _StartUnitConditions conditions,
) {
  final expectedConditions = switch (fixture.id) {
    'city-production-unit-wrong-actor-rejected' => _allStartUnitConditionsMet,
    'city-production-unit-wrong-actor-compound-rejected' => (
      unitAvailable: false,
      resourcesAvailable: false,
      coastAvailable: false,
      supplyAvailable: false,
    ),
    _ => null,
  };
  if (expectedConditions == null) return false;

  final expectedType = fixture.id.endsWith('compound-rejected')
      ? GameUnitType.warship
      : GameUnitType.warrior;
  if (city.ownerPlayerId == fixture.actorPlayerId ||
      command.unitType != expectedType ||
      conditions != expectedConditions ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_controlled') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize its reviewed city_not_controlled precedence mode',
    );
  }
  return true;
}

void _validateRejectedStartUnit(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  _StartUnitConditions conditions,
) {
  final expected = switch (fixture.id) {
    'city-production-unit-not-available-rejected' => (
      type: GameUnitType.warship,
      reason: 'unit_production_not_available',
      conditions: const (
        unitAvailable: false,
        resourcesAvailable: false,
        coastAvailable: false,
        supplyAvailable: false,
      ),
    ),
    'city-production-unit-resource-required-rejected' => (
      type: GameUnitType.warship,
      reason: 'unit_production_requires_resource',
      conditions: const (
        unitAvailable: true,
        resourcesAvailable: false,
        coastAvailable: false,
        supplyAvailable: false,
      ),
    ),
    'city-production-unit-coast-required-rejected' => (
      type: GameUnitType.warship,
      reason: 'unit_production_requires_coast',
      conditions: const (
        unitAvailable: true,
        resourcesAvailable: true,
        coastAvailable: false,
        supplyAvailable: false,
      ),
    ),
    'city-production-unit-supply-full-rejected' => (
      type: GameUnitType.warrior,
      reason: 'unit_supply_limit_reached',
      conditions: const (
        unitAvailable: true,
        resourcesAvailable: true,
        coastAvailable: true,
        supplyAvailable: false,
      ),
    ),
    _ => throw StateError(
      '${fixture.id} uses an unreviewed rejected StartUnitProduction mode.',
    ),
  };
  if (command.unitType != expected.type ||
      fixture.expectedReason != expected.reason ||
      conditions != expected.conditions) {
    ReducerParityCorpus._fail(
      fixture,
      'does not isolate its reviewed StartUnitProduction rejection stage',
    );
  }
  if (fixture.id == 'city-production-unit-coast-required-rejected') {
    _requireReviewedImportedIron(fixture, command.cityId);
  }
}

void _validateAcceptedStartUnit(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
  _StartUnitConditions conditions,
) {
  if (conditions != _allStartUnitConditionsMet ||
      !fixture.expectedAccepted ||
      fixture.expectedReason != null) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize an otherwise available accepted unit',
    );
  }
  switch (fixture.id) {
    case 'city-production-unit-overflow-accepted':
      _validateStartUnitOverflow(fixture, command, city);
    case 'city-production-unit-import-coast-replacement-accepted':
      _validateImportedCoastalStartUnitReplacement(fixture, command, city);
    case 'city-production-unit-same-target-no-op-accepted':
      _validateSameTargetStartUnit(fixture, command, city);
    case 'city-production-unit-supply-bonuses-accepted':
      _validateStartUnitSupplyBonuses(fixture, command, city);
    default:
      ReducerParityCorpus._fail(
        fixture,
        'uses an unreviewed accepted StartUnitProduction mode',
      );
  }
}

_StartUnitConditions _reviewedStartUnitConditions(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
) {
  final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
    playerId: city.ownerPlayerId,
    unitType: command.unitType,
    research: fixture.state.research,
    ruleset: TechnologyRulesets.standard,
  );
  return (
    unitAvailable: CityProductionRules.canProduceUnit(
      command.unitType,
      ruleset: CityRulesets.standard,
      technologyUnlocked: technologyUnlocked,
    ),
    resourcesAvailable: UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: fixture.state.cities,
      mapTiles: fixture.mapData,
      ruleset: CityRulesets.standard,
      research: fixture.state.research,
      resourceTradeAgreements: fixture.state.resourceTradeAgreements,
    ),
    coastAvailable: CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: command.unitType,
      mapTiles: fixture.mapData,
    ),
    supplyAvailable: _canQueueReviewedStartUnit(fixture, command, city),
  );
}

bool _canQueueReviewedStartUnit(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city, {
  Iterable<WorldArtifact>? artifacts,
  Iterable<FieldImprovement>? fieldImprovements,
}) {
  return CityUnitSupplyRules.canQueueUnit(
    playerId: city.ownerPlayerId,
    unitType: command.unitType,
    cities: fixture.state.cities,
    units: fixture.state.units,
    artifacts: artifacts ?? fixture.state.artifacts,
    fieldImprovements: fieldImprovements ?? fixture.state.fieldImprovements,
    mapView: fixture.mapData,
    cityRuleset: CityRulesets.standard,
    research: fixture.state.research,
    technologyRuleset: TechnologyRulesets.standard,
    replacingCityId: city.id,
  );
}

void _validateStartUnitOverflow(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
) {
  final cost = CityProductionRules.unitProductionCost(
    command.unitType,
    ruleset: CityRulesets.standard,
    paceBalance: fixture.save.matchRules.paceBalance,
  );
  if (command.unitType != GameUnitType.warrior ||
      fixture.save.matchRules.paceBalance.profile != PaceProfile.standard60 ||
      cost != 12 ||
      cost ~/ 2 != 6 ||
      city.productionQueue != null ||
      city.productionOverflow != 1000) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize warrior standard60 cost 12 and rollover cap 6',
    );
  }
}

void _validateImportedCoastalStartUnitReplacement(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
) {
  final queue = city.productionQueue;
  if (command.unitType != GameUnitType.warship ||
      queue?.target !=
          const BuildingProductionTarget(CityBuildingType.workshop) ||
      queue?.investedProduction != 7 ||
      city.productionOverflow != 13) {
    ReducerParityCorpus._fail(
      fixture,
      'must replace the reviewed active queue while preserving investment and overflow',
    );
  }
  _requireReviewedImportedIron(fixture, city.id);
}

void _requireReviewedImportedIron(ReducerParityFixture fixture, String cityId) {
  final city = fixture.state.cities.byId(cityId)!;
  final importsIron = fixture.state.resourceTradeAgreements.any(
    (agreement) =>
        agreement.resource == ResourceType.iron &&
        agreement.importsFor(city.ownerPlayerId),
  );
  final mapContainsIron = fixture.mapData.tiles.any(
    (tile) => tile.resources.contains(ResourceType.iron),
  );
  if (!importsIron || mapContainsIron) {
    ReducerParityCorpus._fail(
      fixture,
      'must satisfy iron exclusively through an active resource import',
    );
  }
}

void _validateSameTargetStartUnit(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
) {
  if (command.unitType != GameUnitType.warrior ||
      city.productionQueue?.target != UnitProductionTarget(command.unitType) ||
      city.productionQueue?.investedProduction != 5 ||
      city.productionOverflow != 13) {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize the accepted same-target unit value no-op',
    );
  }
}

void _validateStartUnitSupplyBonuses(
  ReducerParityFixture fixture,
  StartUnitProductionCommand command,
  GameCity city,
) {
  final artifacts = fixture.state.artifacts;
  final improvements = fixture.state.fieldImprovements;
  final reviewedArtifacts = artifacts.where(
    (artifact) =>
        artifact.type == WorldArtifactType.firstPeoplesChronicle &&
        artifact.location.cityId == city.id,
  );
  final reviewedFarms = improvements.where(
    (improvement) =>
        improvement.type == FieldImprovementType.farm &&
        city.controlsHex(improvement.hex),
  );
  if (command.unitType != GameUnitType.warrior ||
      reviewedArtifacts.length != 1 ||
      reviewedFarms.length != 1) {
    ReducerParityCorpus._fail(
      fixture,
      'must carry one stored food artifact and one controlled passive farm',
    );
  }

  final artifact = reviewedArtifacts.single;
  final farm = reviewedFarms.single;
  final withoutArtifact = artifacts.where((candidate) => candidate != artifact);
  final withoutFarm = improvements.where((candidate) => candidate != farm);
  if (_canQueueReviewedStartUnit(
        fixture,
        command,
        city,
        artifacts: withoutArtifact,
      ) ||
      _canQueueReviewedStartUnit(
        fixture,
        command,
        city,
        fieldImprovements: withoutFarm,
      ) ||
      _canQueueReviewedStartUnit(
        fixture,
        command,
        city,
        artifacts: withoutArtifact,
        fieldImprovements: withoutFarm,
      )) {
    ReducerParityCorpus._fail(
      fixture,
      'must cross the supply boundary only with both artifact and farm bonuses',
    );
  }
}

bool _permitsReviewedStartUnitValueNoOp(ReducerParityFixture fixture) {
  return fixture.id == 'city-production-unit-same-target-no-op-accepted' &&
      fixture.command is StartUnitProductionCommand &&
      fixture.expectedAccepted &&
      fixture.expectedReason == null;
}
