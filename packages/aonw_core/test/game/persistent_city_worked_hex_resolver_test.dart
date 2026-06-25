import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCityWorkedHexResolver', () {
    test('adds a controlled hex to manual worked hexes', () {
      final state = PersistentGameState(cities: [_city()]);

      final result = const PersistentCityWorkedHexResolver().toggleWorkedHex(
        state: state,
        command: const ToggleWorkedHexCommand('city_1', 1, 0),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.cities.single.workedHexes, [
        const CityHex(col: 1, row: 0),
      ]);
    });

    test('removes an already manually worked hex', () {
      final state = PersistentGameState(
        cities: [
          _city(workedHexes: const [CityHex(col: 1, row: 0)]),
        ],
      );

      final result = const PersistentCityWorkedHexResolver().toggleWorkedHex(
        state: state,
        command: const ToggleWorkedHexCommand('city_1', 1, 0),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.cities.single.workedHexes, isEmpty);
    });

    test('rejects toggling another player city', () {
      final state = PersistentGameState(
        cities: [_city(ownerPlayerId: 'player_2')],
      );

      final result = const PersistentCityWorkedHexResolver().toggleWorkedHex(
        state: state,
        command: const ToggleWorkedHexCommand('city_1', 1, 0),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_not_controlled');
      expect(result.state, state);
    });

    test('rejects center or uncontrolled hexes', () {
      final state = PersistentGameState(cities: [_city()]);

      final center = const PersistentCityWorkedHexResolver().toggleWorkedHex(
        state: state,
        command: const ToggleWorkedHexCommand('city_1', 0, 0),
        actorPlayerId: 'player_1',
      );
      final outside = const PersistentCityWorkedHexResolver().toggleWorkedHex(
        state: state,
        command: const ToggleWorkedHexCommand('city_1', 2, 0),
        actorPlayerId: 'player_1',
      );

      expect(center.accepted, isFalse);
      expect(center.reason, 'worked_hex_unavailable');
      expect(outside.accepted, isFalse);
      expect(outside.reason, 'worked_hex_unavailable');
    });

    test('rejects adding when worked hex limit is reached', () {
      final state = PersistentGameState(
        cities: [
          _city(
            workedHexes: const [CityHex(col: 1, row: 0)],
            controlledHexes: const [
              CityHex(col: 1, row: 0),
              CityHex(col: 0, row: 1),
            ],
          ),
        ],
      );

      final result = const PersistentCityWorkedHexResolver().toggleWorkedHex(
        state: state,
        command: const ToggleWorkedHexCommand('city_1', 0, 1),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'worked_hex_limit_reached');
      expect(result.state, state);
    });
  });
}

GameCity _city({
  String ownerPlayerId = 'player_1',
  int population = 1,
  List<CityHex> controlledHexes = const [CityHex(col: 1, row: 0)],
  List<CityHex> workedHexes = const [],
}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: ownerPlayerId,
    name: 'City',
    population: population,
    center: const CityHex(col: 0, row: 0),
    controlledHexes: controlledHexes,
    workedHexes: workedHexes,
  );
}
