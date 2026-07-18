part of 'city_production_command_resolver_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

CityProductionCommandResult _startBuilding({
  required List<GameCity> cities,
  CityBuildingType buildingType = CityBuildingType.granary,
  ResearchState research = ResearchState.empty,
  MapTileLookup? mapTiles,
  String actorPlayerId = _playerId,
}) {
  return CityProductionCommandResolver.startBuilding(
    cities: cities,
    research: research,
    command: StartBuildingCommand('city_1', buildingType),
    actorPlayerId: actorPlayerId,
    mapTiles: mapTiles ?? _productionMapTiles(),
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    paceBalance: PaceBalance.standard60,
  );
}

void _expectBuildingRejected({
  required List<GameCity> cities,
  required String reason,
  String actorPlayerId = _playerId,
}) {
  final result = _startBuilding(cities: cities, actorPlayerId: actorPlayerId);

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.cities, cities), isTrue);
}

CityProductionCommandResult _startProject({
  required List<GameCity> cities,
  String actorPlayerId = _playerId,
}) {
  return CityProductionCommandResolver.startCityProject(
    cities: cities,
    command: const StartCityProjectCommand('city_1', CityProjectType.research),
    actorPlayerId: actorPlayerId,
    cityRuleset: CityRulesets.standard,
    paceBalance: PaceBalance.standard60,
  );
}

void _expectProjectRejected({
  required List<GameCity> cities,
  required String reason,
  String actorPlayerId = _playerId,
}) {
  final result = _startProject(cities: cities, actorPlayerId: actorPlayerId);

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.cities, cities), isTrue);
}

CityProductionCommandResult _setSpecialization({
  required List<GameCity> cities,
  required ResearchState research,
  String actorPlayerId = _playerId,
}) {
  return CityProductionCommandResolver.setCitySpecialization(
    cities: cities,
    research: research,
    command: const SetCitySpecializationCommand(
      'city_1',
      CitySpecializationType.industry,
    ),
    actorPlayerId: actorPlayerId,
  );
}

void _expectSpecializationRejected({
  required List<GameCity> cities,
  required ResearchState research,
  required String reason,
  String actorPlayerId = _playerId,
}) {
  final result = _setSpecialization(
    cities: cities,
    research: research,
    actorPlayerId: actorPlayerId,
  );

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.cities, cities), isTrue);
}

ResearchState _specializationResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.specialization},
      ),
    },
  );
}

ResearchState _researchWith(Set<TechnologyId> technologyIds) {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(unlockedTechnologyIds: technologyIds),
    },
  );
}

MapTileLookup _productionMapTiles({ResourceType? resource}) {
  return WorldMapReadView(
    WorldMap(
      cols: 5,
      rows: 5,
      tiles: [
        for (var row = 0; row < 5; row++)
          for (var col = 0; col < 5; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: col == 1 && row == 1 && resource != null
                  ? [resource]
                  : const [],
              height: 0,
            ),
      ],
    ),
  );
}

GameCity _productionCity({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
  Set<CityBuildingType> buildings = const {},
  CitySpecializationType? specialization,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: id == 'city_1'
        ? const CityHex(col: 1, row: 1)
        : const CityHex(col: 3, row: 3),
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
    buildings: buildings,
    specialization: specialization,
  );
}
