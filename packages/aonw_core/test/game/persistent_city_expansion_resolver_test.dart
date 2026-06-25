import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCityExpansionResolver', () {
    test('records preferred expansion hex for a controlled city', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityExpansionResolver().selectExpansionHex(
        state: state,
        command: const SelectCityExpansionHexCommand('city_1', 1, 2),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.cities.single.preferredExpansionHex,
        const CityHex(col: 1, row: 2),
      );
    });

    test('rejects selecting another player city', () {
      final state = PersistentGameState(
        cities: [_city(ownerPlayerId: 'player_2')],
      );

      final result = const PersistentCityExpansionResolver().selectExpansionHex(
        state: state,
        command: const SelectCityExpansionHexCommand('city_1', 1, 2),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_not_controlled');
      expect(result.state, state);
    });

    test('rejects unavailable expansion hexes', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityExpansionResolver().selectExpansionHex(
        state: state,
        command: const SelectCityExpansionHexCommand('city_1', 0, 0),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_expansion_hex_unavailable');
      expect(result.state, state);
    });
  });
}

GameCity _city({String ownerPlayerId = 'player_1'}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    center: const CityHex(col: 1, row: 1),
    controlledHexes: const [CityHex(col: 2, row: 1)],
  );
}

MapDefinition _mapDefinition() {
  return MapDefinition(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
