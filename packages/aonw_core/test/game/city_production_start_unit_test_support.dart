import 'package:aonw_core/domain.dart';

const unitCharacterizationPlayerId = 'player_1';
const unitCharacterizationOtherPlayerId = 'player_2';

DomainState unitCharacterizationState({
  required List<GameCity> cities,
  List<GameUnit>? units,
  List<WorldArtifact>? artifacts,
  List<FieldImprovement>? fieldImprovements,
  ResearchState research = ResearchState.empty,
  List<ResourceTradeAgreement> resourceTradeAgreements = const [],
}) {
  return DomainState.snapshot(
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

    submittedPlayerIds: const {unitCharacterizationOtherPlayerId},
    timeoutStreaksByPlayerId: const {unitCharacterizationOtherPlayerId: 1},
    afkPlayerIds: const {unitCharacterizationOtherPlayerId},
    dominationHoldTurnsByPlayerId: const {unitCharacterizationPlayerId: 2},
    culturalVictoryHoldTurnsByPlayerId: const {
      unitCharacterizationOtherPlayerId: 3,
    },
    resourceTradeAgreements: resourceTradeAgreements,
    turnStartedAt: DateTime.utc(2026, 7, 18, 12),

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

MapReadView unitCharacterizationMap({bool coastal = false}) {
  return WorldMap(
    cols: 7,
    rows: 7,
    mapName: 'start_unit_characterization',
    tiles: [
      for (var row = 0; row < 7; row++)
        for (var col = 0; col < 7; col++)
          WorldTile.at(
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
