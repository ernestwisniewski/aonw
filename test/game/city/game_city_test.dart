import 'package:aonw/game/domain/city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCity', () {
    test('serializes population', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'City 1',
        population: 3,
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      final json = city.toJson();
      expect(json['population'], 3);
      expect(json['foundingOwnerPlayerId'], 'player_1');

      final decoded = GameCity.fromJson(json);
      expect(decoded.population, 3);
      expect(decoded.capitalOwnerPlayerId, 'player_1');
      expect(decoded, city);
    });

    test('copyWith preserves founding owner when ownership changes', () {
      const city = GameCity(
        id: 'city_player_2_0_0',
        ownerPlayerId: 'player_2',
        name: 'Rival',
        center: CityHex(col: 0, row: 0),
      );

      final captured = city.copyWith(ownerPlayerId: 'player_1');

      expect(captured.ownerPlayerId, 'player_1');
      expect(captured.foundingOwnerPlayerId, 'player_2');
      expect(captured.capitalOwnerPlayerId, 'player_2');
    });

    test('serializes worked hexes when present', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
        workedHexes: [CityHex(col: 0, row: 0)],
      );

      final json = city.toJson();

      expect(json['workedHexes'], [
        {'col': 0, 'row': 0},
      ]);
      expect(GameCity.fromJson(json), city);
    });

    test('serializes empty worked hexes explicitly', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );

      final json = city.toJson();

      expect(json['workedHexes'], isEmpty);
      expect(GameCity.fromJson(json), city);
    });

    test('copyWith preserves and can replace worked hexes', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
        workedHexes: [CityHex(col: 0, row: 0)],
      );

      expect(city.copyWith().workedHexes, city.workedHexes);
      expect(
        city.copyWith(workedHexes: const [CityHex(col: 1, row: 0)]).workedHexes,
        const [CityHex(col: 1, row: 0)],
      );
    });

    test('serializes preferred expansion hex when present', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
        preferredExpansionHex: CityHex(col: 0, row: 1),
      );

      final json = city.toJson();

      expect(json['preferredExpansionHex'], {'col': 0, 'row': 1});
      expect(GameCity.fromJson(json), city);
    });

    test(
      'copyWith preserves, replaces, and clears preferred expansion hex',
      () {
        const city = GameCity(
          id: 'city_player_1_0_0',
          ownerPlayerId: 'player_1',
          name: 'City 1',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 0)],
          preferredExpansionHex: CityHex(col: 0, row: 1),
        );

        expect(
          city.copyWith().preferredExpansionHex,
          city.preferredExpansionHex,
        );
        expect(
          city
              .copyWith(preferredExpansionHex: const CityHex(col: 1, row: 1))
              .preferredExpansionHex,
          const CityHex(col: 1, row: 1),
        );
        expect(
          city.copyWith(preferredExpansionHex: null).preferredExpansionHex,
          isNull,
        );
      },
    );

    test('copyWith can clear production queue', () {
      final city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: const CityHex(col: 0, row: 0),
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 1,
        ),
      );

      expect(city.copyWith().productionQueue, city.productionQueue);
      expect(city.copyWith(productionQueue: null).productionQueue, isNull);
    });

    test('serializes production overflow', () {
      const city = GameCity(
        id: 'city_player_1_0_0',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 0),
        productionOverflow: 3,
      );

      final json = city.toJson();

      expect(json['productionOverflow'], 3);
      expect(GameCity.fromJson(json), city);
    });

    test('defaults missing collection metadata from JSON', () {
      final json =
          const GameCity(
              id: 'city_player_1_0_0',
              ownerPlayerId: 'player_1',
              name: 'City 1',
              center: CityHex(col: 0, row: 0),
            ).toJson()
            ..remove('controlledHexes')
            ..remove('workedHexes')
            ..remove('buildings');

      final decoded = GameCity.fromJson(json);

      expect(decoded.controlledHexes, isEmpty);
      expect(decoded.workedHexes, isEmpty);
      expect(decoded.buildings, isEmpty);
      expect(decoded.productionOverflow, 0);
      expect(decoded.preferredExpansionHex, isNull);
      expect(decoded.foundingOwnerPlayerId, isNull);
      expect(decoded.capitalOwnerPlayerId, 'player_1');
    });
  });
}
