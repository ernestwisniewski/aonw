part of 'city_expansion_command_resolver_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

CityExpansionCommandResult _selectExpansion({
  required List<GameCity> cities,
  ResearchState research = ResearchState.empty,
  CityRuleset cityRuleset = CityRulesets.standard,
  TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
}) {
  return CityExpansionCommandResolver.selectExpansionHex(
    cities: cities,
    research: research,
    command: const SelectCityExpansionHexCommand('city_1', 1, 2),
    actorPlayerId: _playerId,
    mapTiles: _expansionMap(),
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
  );
}

void _expectExpansionRejected({
  required List<GameCity> cities,
  required CityHex target,
  required String reason,
  String actorPlayerId = _playerId,
}) {
  final result = CityExpansionCommandResolver.selectExpansionHex(
    cities: cities,
    research: ResearchState.empty,
    command: SelectCityExpansionHexCommand('city_1', target.col, target.row),
    actorPlayerId: actorPlayerId,
    mapTiles: _expansionMap(),
  );

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.cities, cities), isTrue);
}

GameCity _expansionCity({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityHex center = const CityHex(col: 1, row: 1),
  int maxHexes = GameCity.defaultStartMaxHexes,
  Set<CityBuildingType> buildings = const {},
  CityHex? preferredExpansionHex,
}) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: center,
    controlledHexes: [CityHex(col: center.col + 1, row: center.row)],
    maxHexes: maxHexes,
    buildings: buildings,
    preferredExpansionHex: preferredExpansionHex,
  );
}

MapTileLookup _expansionMap() {
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
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
