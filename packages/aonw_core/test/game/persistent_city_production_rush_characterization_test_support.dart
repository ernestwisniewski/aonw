import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const rushCharacterizationPlayerId = 'player_1';
const rushCharacterizationOtherPlayerId = 'player_2';

typedef RushRejectionCase = ({
  String name,
  PersistentGameState state,
  RushProductionCommand command,
  String actorPlayerId,
  String reason,
});

List<RushRejectionCase> rushAvailabilityRejectionCases(int granaryCost) {
  return [
    (
      name: 'already-complete-finite-queue-is-unavailable',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            productionQueue: rushCharacterizationBuildingQueue(
              investedProduction: granaryCost,
            ),
          ),
        ),
      ),
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      reason: 'rush_production_unavailable',
    ),
    (
      name: 'missing-treasury-entry-is-unavailable',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            productionQueue: rushCharacterizationBuildingQueue(),
          ),
        ),
        playerGold: const {rushCharacterizationOtherPlayerId: 23},
      ),
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      reason: 'rush_production_unavailable',
    ),
    (
      name: 'insufficient-treasury-is-unavailable',
      state: rushCharacterizationState(
        cities: rushCharacterizationCities(
          rushCharacterizationCity(
            productionQueue: rushCharacterizationBuildingQueue(),
          ),
        ),
        playerGold: const {
          rushCharacterizationPlayerId: 1,
          rushCharacterizationOtherPlayerId: 23,
        },
      ),
      command: const RushProductionCommand('city_1'),
      actorPlayerId: rushCharacterizationPlayerId,
      reason: 'rush_production_unavailable',
    ),
  ];
}

PersistentCityProductionResult rushCharacterization(
  PersistentGameState state, {
  RushProductionCommand command = const RushProductionCommand('city_1'),
  String actorPlayerId = rushCharacterizationPlayerId,
  MapTileLookup? mapTiles,
  CityRuleset cityRuleset = CityRulesets.standard,
  TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
  WonderRuleset wonderRuleset = WonderRuleset.standard,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return const PersistentCityProductionResolver().rushProduction(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    mapTiles: mapTiles ?? rushCharacterizationMap(),
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
    stabilityRuleset: stabilityRuleset,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
  );
}

PersistentGameState rushCharacterizationState({
  required List<GameCity> cities,
  Map<String, int>? playerGold,
  Map<String, int>? playerStabilityNet,
  List<GameUnit>? units,
  List<WorldArtifact>? artifacts,
  List<FieldImprovement>? fieldImprovements,
  ResearchState research = ResearchState.empty,
  WonderRegistry? wonderRegistry,
}) {
  return PersistentGameState.snapshot(
    playerColors: const {
      rushCharacterizationPlayerId: 0xFF336699,
      rushCharacterizationOtherPlayerId: 0xFF993333,
    },
    playerCountries: const {
      rushCharacterizationPlayerId: PlayerCountry.poland,
      rushCharacterizationOtherPlayerId: PlayerCountry.germany,
    },
    playerGold:
        playerGold ??
        const {
          rushCharacterizationPlayerId: 100,
          rushCharacterizationOtherPlayerId: 23,
        },
    playerWarWeariness: const {
      rushCharacterizationPlayerId: 2,
      rushCharacterizationOtherPlayerId: 3,
    },
    playerStabilityNet:
        playerStabilityNet ??
        const {
          rushCharacterizationPlayerId: 1,
          rushCharacterizationOtherPlayerId: 2,
        },
    units:
        units ??
        [
          GameUnit.startingCommander(
            ownerPlayerId: rushCharacterizationOtherPlayerId,
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
      submittedPlayerIds: const {rushCharacterizationOtherPlayerId},
      timeoutStreaksByPlayerId: const {rushCharacterizationOtherPlayerId: 1},
      afkPlayerIds: const {rushCharacterizationOtherPlayerId},
      dominationHoldTurnsByPlayerId: const {rushCharacterizationPlayerId: 2},
      culturalVictoryHoldTurnsByPlayerId: const {
        rushCharacterizationOtherPlayerId: 3,
      },
      turnStartedAt: DateTime.utc(2026, 7, 18, 12),
    ),
    wonderRegistry:
        wonderRegistry ??
        WonderRegistry.empty.complete(
          type: WonderType.greatLibrary,
          playerId: rushCharacterizationOtherPlayerId,
        ),
  );
}

GameCity rushCharacterizationCity({
  String id = 'city_1',
  String ownerPlayerId = rushCharacterizationPlayerId,
  CityHex center = const CityHex(col: 1, row: 1),
  List<CityHex> controlledHexes = const [],
  List<CityHex> workedHexes = const [],
  Set<CityBuildingType> buildings = const {},
  Set<WonderType> wonders = const {},
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    controlledHexes: controlledHexes,
    workedHexes: workedHexes,
    buildings: buildings,
    wonders: wonders,
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
  );
}

GameCity rushCharacterizationSentinelCity() {
  return rushCharacterizationCity(
    id: 'sentinel_city',
    ownerPlayerId: rushCharacterizationOtherPlayerId,
    center: const CityHex(col: 5, row: 5),
    productionQueue: CityProductionQueue.project(
      projectType: CityProjectType.wealth,
      investedProduction: 3,
    ),
    productionOverflow: 2,
  );
}

List<GameCity> rushCharacterizationCities(GameCity target) {
  return [target, rushCharacterizationSentinelCity()];
}

CityProductionQueue rushCharacterizationBuildingQueue({
  int investedProduction = 0,
}) {
  return CityProductionQueue.building(
    buildingType: CityBuildingType.granary,
    investedProduction: investedProduction,
  );
}

CityProductionQueue rushCharacterizationUnitQueue({
  int investedProduction = 0,
}) {
  return CityProductionQueue.unit(
    unitType: GameUnitType.warrior,
    investedProduction: investedProduction,
  );
}

MapTileLookup rushCharacterizationMap({
  TerrainType workedTerrain = TerrainType.grassland,
}) {
  return WorldMapReadView(
    WorldMap(
      cols: 7,
      rows: 7,
      mapName: 'rush_characterization',
      tiles: [
        for (var row = 0; row < 7; row++)
          for (var col = 0; col < 7; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: col == 2 && row == 1
                  ? [workedTerrain]
                  : const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}

CityRuleset rushCharacterizationCustomCityRuleset() {
  return CityRulesets.standard.copyWith(
    cityCenterYield: const TileYield(
      food: 2,
      production: 4,
      gold: 0,
      defense: 0,
    ),
    terrainYields: {
      ...CityRulesets.standard.terrainYields,
      TerrainType.plains: const TileYield(
        food: 0,
        production: 4,
        gold: 0,
        defense: 0,
      ),
    },
    buildings: {
      ...CityRulesets.standard.buildings,
      CityBuildingType.granary: const CityBuildingDefinition(
        type: CityBuildingType.granary,
        productionCost: 40,
      ),
    },
  );
}

TechnologyRuleset rushCharacterizationTechnologyRuleset() {
  final source = TechnologyRulesets.standard.definitionFor(
    TechnologyId.logistics,
  );
  final logistics = TechnologyDefinition(
    id: source.id,
    name: source.name,
    description: source.description,
    era: source.era,
    baseCost: source.baseCost,
    treePosition: source.treePosition,
    prerequisites: source.prerequisites,
    blockedBy: source.blockedBy,
    unlocks: source.unlocks,
    effects: const [ArmyProductionMultiplier(1)],
    boosts: source.boosts,
  );
  return TechnologyRuleset(
    science: TechnologyRulesets.standard.science,
    costs: TechnologyRulesets.standard.costs,
    technologies: {
      ...TechnologyRulesets.standard.technologies,
      TechnologyId.logistics: logistics,
    },
  );
}

WonderRuleset rushCharacterizationWonderRuleset() {
  final source = WonderRuleset.standard.definitionFor(
    WonderType.hangingGardens,
  );
  return WonderRuleset(
    wonders: {
      ...WonderRuleset.standard.wonders,
      WonderType.hangingGardens: WonderDefinition(
        type: source.type,
        productionCost: 20,
        unlockTech: source.unlockTech,
        requirements: source.requirements,
        standingEffects: source.standingEffects,
        completionEffects: const [GrantGold(7), ProductionBurst(3)],
      ),
    },
  );
}

ResearchState rushCharacterizationLogisticsResearch() {
  return ResearchState(
    players: {
      rushCharacterizationPlayerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.logistics},
      ),
    },
  );
}

WorldArtifact rushCharacterizationHeroSword() {
  return const WorldArtifact(
    id: 'hero_sword',
    type: WorldArtifactType.heroSword,
    location: WorldArtifactLocation.stored(cityId: 'city_1'),
  );
}

List<GameUnit> rushCharacterizationSpawnBlockers() {
  return [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        GameUnit.produced(
          id: 'blocker_${col}_$row',
          ownerPlayerId: rushCharacterizationOtherPlayerId,
          type: GameUnitType.worker,
          col: col,
          row: row,
        ),
  ];
}

void expectRejectedRushIdentity({
  required PersistentGameState before,
  required PersistentCityProductionResult result,
  required String reason,
}) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.events, isEmpty);
  expect(result.state, same(before));
  expectRushSliceIdentities(before, result.state);
  for (var index = 0; index < before.cities.length; index++) {
    expect(result.state.cities[index], same(before.cities[index]));
    expect(
      result.state.cities[index].productionQueue,
      same(before.cities[index].productionQueue),
    );
  }
}

void expectRushSliceIdentities(
  PersistentGameState before,
  PersistentGameState after, {
  bool citiesSame = true,
  bool? unitsSame = true,
  bool playerGoldSame = true,
  bool researchSame = true,
  bool wonderRegistrySame = true,
}) {
  _expectIdentity(after.playerColors, before.playerColors, isSame: true);
  _expectIdentity(after.playerCountries, before.playerCountries, isSame: true);
  _expectIdentity(after.playerGold, before.playerGold, isSame: playerGoldSame);
  _expectIdentity(
    after.playerWarWeariness,
    before.playerWarWeariness,
    isSame: true,
  );
  _expectIdentity(
    after.playerStabilityNet,
    before.playerStabilityNet,
    isSame: true,
  );
  if (unitsSame case final expected?) {
    _expectIdentity(after.units, before.units, isSame: expected);
  }
  _expectIdentity(after.cities, before.cities, isSame: citiesSame);
  _expectIdentity(after.artifacts, before.artifacts, isSame: true);
  _expectIdentity(
    after.fieldImprovements,
    before.fieldImprovements,
    isSame: true,
  );
  _expectIdentity(after.fogOfWar, before.fogOfWar, isSame: true);
  _expectIdentity(after.research, before.research, isSame: researchSame);
  _expectIdentity(after.runtimeState, before.runtimeState, isSame: true);
  _expectIdentity(
    after.wonderRegistry,
    before.wonderRegistry,
    isSame: wonderRegistrySame,
  );
}

void expectRushUnitElementsShared(
  PersistentGameState before,
  PersistentGameState after,
) {
  expect(after.units, hasLength(before.units.length));
  for (var index = 0; index < before.units.length; index++) {
    expect(after.units[index], same(before.units[index]));
  }
}

void _expectIdentity(Object? actual, Object? expected, {required bool isSame}) {
  expect(actual, isSame ? same(expected) : isNot(same(expected)));
}
