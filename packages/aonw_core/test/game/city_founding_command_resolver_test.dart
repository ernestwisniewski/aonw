import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'city_founding_command_resolver_test_support.dart';

void main() {
  group('CityFoundingCommandResolver', () {
    test('schedules exact immutable job and preserves all sentinels', () {
      final beforeFounder = _founder(
        movementPoints: 3,
        queuedPath: _queuedPath(),
      );
      final beforeUnit = _sentinelUnit('before');
      final afterUnit = _sentinelUnit('after');
      final units = [beforeUnit, beforeFounder, afterUnit];
      final sentinelCity = _city(
        id: 'sentinel_city',
        center: const CityHex(col: 6, row: 6),
      );
      final cities = [sentinelCity];
      final matchingDraft = _draft(_founderId);

      final result = _resolve(
        units: units,
        cities: cities,
        cityFoundingDraft: matchingDraft,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.units, units), isFalse);
      expect(result.units, hasLength(3));
      expect(identical(result.units[0], beforeUnit), isTrue);
      expect(identical(result.units[2], afterUnit), isTrue);
      expect(result.cityFoundingDraft, isNull);
      expect(
        result.units[1],
        beforeFounder
            .copyWith(movementPoints: 0)
            .copyWithQueuedPath(null)
            .copyWithCityFoundingJob(
              CityFoundingJob(
                center: const CityHex(col: 1, row: 1),
                controlledHexes: _controlledHexes,
                remainingTurns: 1,
                totalTurns: 1,
              ),
            ),
      );
      expect(beforeFounder.movementPoints, 3);
      expect(beforeFounder.queuedPath, isNotNull);
      expect(beforeFounder.cityFoundingJob, isNull);
      expect(identical(cities.single, sentinelCity), isTrue);
      expect(() => result.units.clear(), throwsUnsupportedError);
      expect(
        () => result.units[1].cityFoundingJob!.controlledHexes.clear(),
        throwsUnsupportedError,
      );
    });

    test('successful command preserves an unrelated draft identity', () {
      final unrelatedDraft = _draft('other_founder');

      final result = _resolve(
        units: [_founder()],
        cityFoundingDraft: unrelatedDraft,
      );

      expect(result.accepted, isTrue);
      expect(identical(result.cityFoundingDraft, unrelatedDraft), isTrue);
    });

    test('rejects empty self-contained payload without using the draft', () {
      final draftWithValidHexes = _draft(
        _founderId,
        controlledHexes: _controlledHexes,
      );

      _expectRejected(
        units: [_founder()],
        cityFoundingDraft: draftWithValidHexes,
        controlledHexes: const [],
        reason: 'city_controlled_hexes_invalid',
      );
    });

    test('preserves exact rejection precedence and input identities', () {
      _expectRejected(
        units: const [],
        actorPlayerId: _otherPlayerId,
        controlledHexes: const [],
        mapTiles: _map(centerTerrain: TerrainType.ocean),
        reason: 'city_founder_not_found',
      );
      _expectRejected(
        units: [_founder(ownerPlayerId: _otherPlayerId, busy: true)],
        controlledHexes: const [],
        mapTiles: _map(centerTerrain: TerrainType.ocean),
        reason: 'city_founder_not_controlled',
      );
      _expectRejected(
        units: [_founder(busy: true)],
        controlledHexes: const [],
        mapTiles: _map(centerTerrain: TerrainType.ocean),
        reason: 'city_founder_busy',
      );
      _expectRejected(
        units: [_founder(type: GameUnitType.warrior)],
        controlledHexes: const [],
        mapTiles: _map(centerTerrain: TerrainType.ocean),
        reason: 'city_founder_invalid',
      );
      _expectRejected(
        units: [_founder(type: GameUnitType.commander)],
        controlledHexes: const [],
        mapTiles: _map(centerTerrain: TerrainType.ocean),
        reason: 'city_founder_no_settlers',
      );
      _expectRejected(
        units: [_founder()],
        cities: [_city(center: const CityHex(col: 1, row: 1))],
        controlledHexes: const [],
        mapTiles: _map(centerTerrain: TerrainType.ocean),
        reason: 'city_site_invalid',
      );
      _expectRejected(
        units: [_founder()],
        cities: [_city(center: const CityHex(col: 1, row: 1))],
        controlledHexes: const [],
        reason: 'city_center_occupied',
      );
      _expectRejected(
        units: [_founder()],
        cities: [
          _city(
            center: const CityHex(col: 6, row: 6),
            controlledHexes: const [CityHex(col: 1, row: 1)],
          ),
        ],
        controlledHexes: const [],
        reason: 'city_center_claimed',
      );
      _expectRejected(
        units: [_founder()],
        cities: [_city(center: const CityHex(col: 3, row: 1))],
        controlledHexes: const [],
        reason: 'city_center_too_close',
      );
    });

    test('rejects every invalid controlled-hex shape and map reference', () {
      _expectRejected(
        units: [_founder()],
        controlledHexes: const [CityHex(col: 2, row: 1)],
        reason: 'city_controlled_hexes_invalid',
      );
      _expectRejected(
        units: [_founder()],
        controlledHexes: const [
          CityHex(col: 2, row: 1),
          CityHex(col: 1, row: 2),
          CityHex(col: 2, row: 2),
        ],
        reason: 'city_controlled_hexes_invalid',
      );
      _expectRejected(
        units: [_founder()],
        controlledHexes: const [
          CityHex(col: 2, row: 1),
          CityHex(col: 2, row: 1),
        ],
        reason: 'city_controlled_hexes_invalid',
      );
      _expectRejected(
        units: [_founder()],
        controlledHexes: const [
          CityHex(col: 3, row: 1),
          CityHex(col: 1, row: 3),
        ],
        reason: 'city_controlled_hexes_invalid',
      );
      _expectRejected(
        units: [_founder()],
        controlledHexes: const [
          CityHex(col: 1, row: 1),
          CityHex(col: 2, row: 1),
        ],
        reason: 'city_controlled_hexes_invalid',
      );
      _expectRejected(
        units: [_founder()],
        controlledHexes: _controlledHexes,
        mapTiles: _map(missing: const CityHex(col: 2, row: 1)),
        reason: 'city_controlled_hexes_invalid',
      );
      _expectRejected(
        units: [_founder()],
        cities: [
          _city(
            center: const CityHex(col: 6, row: 6),
            controlledHexes: const [CityHex(col: 2, row: 1)],
          ),
        ],
        controlledHexes: _controlledHexes,
        reason: 'city_controlled_hexes_invalid',
      );
    });
  });
}
