import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const unitCharacterizationPlayerId = 'player_1';
const unitCharacterizationOtherPlayerId = 'player_2';

typedef UnitCharacterizationRuleSnapshot = ({
  bool technologyUnlocked,
  bool requirementsMet,
  bool coastAvailable,
  bool supplyAvailable,
});

PersistentCityProductionResult startUnitCharacterization(
  PersistentGameState state, {
  required StartUnitProductionCommand command,
  required MapReadView mapView,
  String actorPlayerId = unitCharacterizationPlayerId,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return const PersistentCityProductionResolver().startUnitProduction(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    mapView: mapView,
    paceBalance: paceBalance,
  );
}

PersistentGameState unitCharacterizationState({
  required List<GameCity> cities,
  List<GameUnit>? units,
  List<WorldArtifact>? artifacts,
  List<FieldImprovement>? fieldImprovements,
  ResearchState research = ResearchState.empty,
  List<ResourceTradeAgreement> resourceTradeAgreements = const [],
}) {
  return PersistentGameState.snapshot(
    playerColors: const {
      unitCharacterizationPlayerId: 0xFF336699,
      unitCharacterizationOtherPlayerId: 0xFF993333,
    },
    playerGold: const {
      unitCharacterizationPlayerId: 41,
      unitCharacterizationOtherPlayerId: 23,
    },
    playerWarWeariness: const {
      unitCharacterizationPlayerId: 2,
      unitCharacterizationOtherPlayerId: 3,
    },
    playerStabilityNet: const {
      unitCharacterizationPlayerId: 4,
      unitCharacterizationOtherPlayerId: 5,
    },
    units:
        units ??
        [
          GameUnit.startingCommander(
            ownerPlayerId: unitCharacterizationOtherPlayerId,
            col: 6,
            row: 6,
          ),
        ],
    cities: cities,
    artifacts:
        artifacts ??
        const [
          WorldArtifact(
            id: 'artifact_sentinel',
            type: WorldArtifactType.queensMirror,
            location: WorldArtifactLocation.map(col: 0, row: 0),
          ),
        ],
    fieldImprovements:
        fieldImprovements ??
        const [
          FieldImprovement(
            hex: CityHex(col: 0, row: 1),
            type: FieldImprovementType.mine,
            builtByCityId: 'sentinel_city',
          ),
        ],
    research: research,
    runtimeState: GameRuntimeState.snapshot(
      submittedPlayerIds: const {unitCharacterizationOtherPlayerId},
      timeoutStreaksByPlayerId: const {unitCharacterizationOtherPlayerId: 1},
      afkPlayerIds: const {unitCharacterizationOtherPlayerId},
      dominationHoldTurnsByPlayerId: const {unitCharacterizationPlayerId: 2},
      culturalVictoryHoldTurnsByPlayerId: const {
        unitCharacterizationOtherPlayerId: 3,
      },
      resourceTradeAgreements: resourceTradeAgreements,
      turnStartedAt: DateTime.utc(2026, 7, 18, 12),
    ),
    wonderRegistry: WonderRegistry.empty.complete(
      type: WonderType.greatLibrary,
      playerId: unitCharacterizationOtherPlayerId,
    ),
  );
}

GameCity unitCharacterizationCity({
  String id = 'city_1',
  String ownerPlayerId = unitCharacterizationPlayerId,
  CityHex center = const CityHex(col: 1, row: 1),
  int population = GameCity.defaultStartPopulation,
  List<CityHex> controlledHexes = const [],
  List<CityHex> workedHexes = const [],
  Set<CityBuildingType> buildings = const {},
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    population: population,
    controlledHexes: controlledHexes,
    workedHexes: workedHexes,
    buildings: buildings,
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
  );
}

ResearchState unitCharacterizationResearch(
  Set<TechnologyId> unlockedTechnologyIds, {
  String playerId = unitCharacterizationPlayerId,
}) {
  return ResearchState(
    players: {
      playerId: PlayerResearchState(
        unlockedTechnologyIds: unlockedTechnologyIds,
      ),
    },
  );
}

List<GameUnit> unitCharacterizationWorkers({
  required String ownerPlayerId,
  required int count,
}) {
  return [
    for (var index = 0; index < count; index++)
      GameUnit.produced(
        id: '${ownerPlayerId}_worker_$index',
        ownerPlayerId: ownerPlayerId,
        type: GameUnitType.worker,
        col: index,
        row: 0,
      ),
  ];
}

ResourceTradeAgreement unitCharacterizationIronImport() {
  return const ResourceTradeAgreement(
    id: 'iron_import',
    exporterPlayerId: unitCharacterizationOtherPlayerId,
    importerPlayerId: unitCharacterizationPlayerId,
    resource: ResourceType.iron,
    goldPerTurn: 3,
    remainingTurns: 8,
  );
}

WorldArtifact unitCharacterizationFoodArtifact() {
  return const WorldArtifact(
    id: 'food_artifact',
    type: WorldArtifactType.firstPeoplesChronicle,
    location: WorldArtifactLocation.stored(cityId: 'city_1'),
  );
}

FieldImprovement unitCharacterizationFarm() {
  return const FieldImprovement(
    hex: CityHex(col: 1, row: 2),
    type: FieldImprovementType.farm,
    builtByCityId: 'city_1',
  );
}

MapReadView unitCharacterizationMap({bool coastal = false}) {
  return WorldMapReadView(
    WorldMap(
      cols: 7,
      rows: 7,
      mapName: 'start_unit_characterization',
      tiles: [
        for (var row = 0; row < 7; row++)
          for (var col = 0; col < 7; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: coastal && col == 2 && row == 1
                  ? const [TerrainType.coast]
                  : coastal && col == 3 && row == 1
                  ? const [TerrainType.ocean]
                  : const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}

List<GameCity> unitCharacterizationCitiesWithTarget(GameCity target) {
  return [
    target,
    unitCharacterizationCity(
      id: 'sentinel_city',
      ownerPlayerId: unitCharacterizationOtherPlayerId,
      center: const CityHex(col: 5, row: 5),
      productionQueue: CityProductionQueue.project(
        projectType: CityProjectType.wealth,
        investedProduction: 3,
      ),
      productionOverflow: 2,
    ),
  ];
}

void registerStartUnitArtifactFarmSupplyCharacterization() {
  test('city-production-unit-artifact-farm-supply-accepted', () {
    final city = unitCharacterizationCity(
      population: 3,
      controlledHexes: const [CityHex(col: 1, row: 2)],
      buildings: const {CityBuildingType.granary},
    );
    final workers = unitCharacterizationWorkers(
      ownerPlayerId: unitCharacterizationPlayerId,
      count: 7,
    );
    final artifact = unitCharacterizationFoodArtifact();
    final farm = unitCharacterizationFarm();
    final state = unitCharacterizationState(
      cities: unitCharacterizationCitiesWithTarget(city),
      units: workers,
      artifacts: [artifact],
      fieldImprovements: [farm],
    );
    const command = StartUnitProductionCommand('city_1', GameUnitType.warrior);
    final mapView = unitCharacterizationMap();

    expect(
      unitCharacterizationRuleSnapshot(
        state: state,
        command: command,
        mapView: mapView,
      ).supplyAvailable,
      isTrue,
    );
    _expectSupplyUnavailableWithoutOneBonus(
      cities: state.cities,
      units: workers,
      artifacts: const [],
      fieldImprovements: [farm],
      mapView: mapView,
    );
    _expectSupplyUnavailableWithoutOneBonus(
      cities: state.cities,
      units: workers,
      artifacts: [artifact],
      fieldImprovements: const [],
      mapView: mapView,
    );

    final result = startUnitCharacterization(
      state,
      command: command,
      mapView: mapView,
    );

    final identities = expectAcceptedStartUnitOnlyCitiesChanged(
      before: state,
      result: result,
      cityId: command.cityId,
    );
    expect(
      identities.afterCity.productionQueue?.target,
      const UnitProductionTarget(GameUnitType.warrior),
    );
    expect(result.state.artifacts.single, same(artifact));
    expect(result.state.fieldImprovements.single, same(farm));
  });
}

void _expectSupplyUnavailableWithoutOneBonus({
  required List<GameCity> cities,
  required List<GameUnit> units,
  required List<WorldArtifact> artifacts,
  required List<FieldImprovement> fieldImprovements,
  required MapReadView mapView,
}) {
  expect(
    CityUnitSupplyRules.canQueueUnit(
      playerId: unitCharacterizationPlayerId,
      unitType: GameUnitType.warrior,
      cities: cities,
      units: units,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      mapView: mapView,
      replacingCityId: 'city_1',
    ),
    isFalse,
  );
}

UnitCharacterizationRuleSnapshot unitCharacterizationRuleSnapshot({
  required PersistentGameState state,
  required StartUnitProductionCommand command,
  required MapReadView mapView,
}) {
  final city = state.cities.singleWhere((city) => city.id == command.cityId);
  return (
    technologyUnlocked: TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      research: state.research,
      ruleset: TechnologyRulesets.standard,
    ),
    requirementsMet: UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      mapTiles: mapView.mapTiles,
      ruleset: CityRulesets.standard,
      research: state.research,
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
    ),
    coastAvailable: CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: command.unitType,
      mapTiles: mapView.mapTiles,
    ),
    supplyAvailable: CityUnitSupplyRules.canQueueUnit(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: state.cities,
      units: state.units,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      mapView: mapView,
      cityRuleset: CityRulesets.standard,
      research: state.research,
      technologyRuleset: TechnologyRulesets.standard,
      replacingCityId: city.id,
    ),
  );
}

void expectRejectedStartUnitIdentity({
  required PersistentGameState before,
  required PersistentCityProductionResult result,
  required String reason,
}) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.events, isEmpty);
  expect(result.state, same(before));
  expect(result.state.cities, same(before.cities));
  for (var index = 0; index < before.cities.length; index++) {
    expect(result.state.cities[index], same(before.cities[index]));
    expect(
      result.state.cities[index].productionQueue,
      same(before.cities[index].productionQueue),
    );
  }
  expectPersistentNonCityIdentities(before, result.state);
}

({GameCity beforeCity, GameCity afterCity})
expectAcceptedStartUnitOnlyCitiesChanged({
  required PersistentGameState before,
  required PersistentCityProductionResult result,
  required String cityId,
}) {
  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.events, isEmpty);
  expect(result.state, isNot(same(before)));
  expect(result.state.cities, isNot(same(before.cities)));
  expect(result.state.cities, hasLength(before.cities.length));
  expect(() => result.state.cities.clear(), throwsUnsupportedError);

  final cityIndex = before.cities.indexWhere((city) => city.id == cityId);
  expect(cityIndex, isNonNegative);
  final beforeCity = before.cities[cityIndex];
  final afterCity = result.state.cities[cityIndex];
  expect(afterCity, isNot(same(beforeCity)));
  expect(afterCity.controlledHexes, same(beforeCity.controlledHexes));
  expect(afterCity.workedHexes, same(beforeCity.workedHexes));
  expect(afterCity.buildings, same(beforeCity.buildings));
  expect(afterCity.wonders, same(beforeCity.wonders));
  for (var index = 0; index < before.cities.length; index++) {
    if (index == cityIndex) continue;
    expect(result.state.cities[index], same(before.cities[index]));
    expect(
      result.state.cities[index].productionQueue,
      same(before.cities[index].productionQueue),
    );
  }
  expectPersistentNonCityIdentities(before, result.state);
  return (beforeCity: beforeCity, afterCity: afterCity);
}

void expectPersistentNonCityIdentities(
  PersistentGameState before,
  PersistentGameState after,
) {
  expect(after.playerColors, same(before.playerColors));
  expect(after.playerCountries, same(before.playerCountries));
  expect(after.playerGold, same(before.playerGold));
  expect(after.playerWarWeariness, same(before.playerWarWeariness));
  expect(after.playerStabilityNet, same(before.playerStabilityNet));
  expect(after.units, same(before.units));
  expect(after.artifacts, same(before.artifacts));
  expect(after.fieldImprovements, same(before.fieldImprovements));
  expect(after.fogOfWar, same(before.fogOfWar));
  expect(after.research, same(before.research));
  expect(after.runtimeState, same(before.runtimeState));
  expect(after.wonderRegistry, same(before.wonderRegistry));
  expect(
    after.runtimeState.submittedPlayerIds,
    same(before.runtimeState.submittedPlayerIds),
  );
  expect(
    after.runtimeState.timeoutStreaksByPlayerId,
    same(before.runtimeState.timeoutStreaksByPlayerId),
  );
  expect(
    after.runtimeState.afkPlayerIds,
    same(before.runtimeState.afkPlayerIds),
  );
  expect(
    after.runtimeState.kickedPlayerIds,
    same(before.runtimeState.kickedPlayerIds),
  );
  expect(
    after.runtimeState.intendedAttacks,
    same(before.runtimeState.intendedAttacks),
  );
  expect(
    after.runtimeState.dominationHoldTurnsByPlayerId,
    same(before.runtimeState.dominationHoldTurnsByPlayerId),
  );
  expect(
    after.runtimeState.culturalVictoryHoldTurnsByPlayerId,
    same(before.runtimeState.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    after.runtimeState.mapObjectiveHoldStatesByObjectiveId,
    same(before.runtimeState.mapObjectiveHoldStatesByObjectiveId),
  );
  expect(
    after.runtimeState.resourceTradeAgreements,
    same(before.runtimeState.resourceTradeAgreements),
  );
}
