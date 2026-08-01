import 'package:aonw_core/domain.dart';

const rushCharacterizationPlayerId = 'player_1';
const rushCharacterizationOtherPlayerId = 'player_2';

DomainState rushCharacterizationState({
  required List<GameCity> cities,
  Map<String, int>? playerGold,
  Map<String, int>? playerStabilityNet,
  List<GameUnit>? units,
  List<WorldArtifact>? artifacts,
  List<FieldImprovement>? fieldImprovements,
  ResearchState research = ResearchState.empty,
  WonderRegistry? wonderRegistry,
}) {
  return DomainState.snapshot(
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

    submittedPlayerIds: const {rushCharacterizationOtherPlayerId},
    timeoutStreaksByPlayerId: const {rushCharacterizationOtherPlayerId: 1},
    afkPlayerIds: const {rushCharacterizationOtherPlayerId},
    dominationHoldTurnsByPlayerId: const {rushCharacterizationPlayerId: 2},
    culturalVictoryHoldTurnsByPlayerId: const {
      rushCharacterizationOtherPlayerId: 3,
    },
    turnStartedAt: DateTime.utc(2026, 7, 18, 12),

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
  return WorldMap(
    cols: 7,
    rows: 7,
    mapName: 'rush_characterization',
    tiles: [
      for (var row = 0; row < 7; row++)
        for (var col = 0; col < 7; col++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains: col == 2 && row == 1
                ? [workedTerrain]
                : const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

WorldArtifact rushCharacterizationHeroSword() {
  return const WorldArtifact(
    id: 'hero_sword',
    type: WorldArtifactType.heroSword,
    location: WorldArtifactLocation.stored(cityId: 'city_1'),
  );
}
