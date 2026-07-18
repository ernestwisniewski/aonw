import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'merchant_routing_command_resolver_test_support.dart';

void main() {
  group('MerchantRoutingCommandResolver.assignRoute', () {
    test('assigns an owned immutable route and preserves other units', () {
      final merchant = _merchant();
      final guard = _unit(id: 'guard', col: 3);
      final units = [merchant, guard];

      final result = MerchantRoutingCommandResolver.assignRoute(
        units: units,
        cities: _cities(),
        command: const AssignMerchantTradeRouteCommand(
          'merchant',
          'destination',
        ),
        actorPlayerId: _playerId,
        mapData: _lineMap(),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.units, units), isFalse);
      expect(identical(result.units.last, guard), isTrue);
      expect(
        () => result.units.add(_unit(id: 'extra', col: 2)),
        throwsUnsupportedError,
      );
      final updated = result.units.first;
      expect(updated.posture, UnitPosture.active);
      expect(updated.queuedPath, isNull);
      expect(updated.merchantTradeRoute?.originCityId, 'origin');
      expect(updated.merchantTradeRoute?.destinationCityId, 'destination');
      expect(updated.merchantTradeRoute?.steps.map((step) => step.col), [
        0,
        1,
        2,
        3,
      ]);
    });

    test('accepted semantic no-op preserves units identity', () {
      final first = MerchantRoutingCommandResolver.assignRoute(
        units: [_merchant()],
        cities: _cities(),
        command: const AssignMerchantTradeRouteCommand(
          'merchant',
          'destination',
        ),
        actorPlayerId: _playerId,
        mapData: _lineMap(),
      );

      final second = MerchantRoutingCommandResolver.assignRoute(
        units: first.units,
        cities: _cities(),
        command: const AssignMerchantTradeRouteCommand(
          'merchant',
          'destination',
        ),
        actorPlayerId: _playerId,
        mapData: _lineMap(),
      );

      expect(second.accepted, isTrue);
      expect(identical(second.units, first.units), isTrue);
    });

    test('preserves exact rejection precedence and input identity', () {
      final cities = _cities();
      _expectAssignRejected(
        units: const [],
        cities: cities,
        actorPlayerId: _otherPlayerId,
        destinationCityId: 'missing',
        reason: 'unit_not_found',
      );
      _expectAssignRejected(
        units: [
          _unit(
            ownerPlayerId: _otherPlayerId,
            type: GameUnitType.warrior,
            posture: UnitPosture.fortified,
          ),
        ],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'unit_not_controlled',
      );
      _expectAssignRejected(
        units: [
          _unit(type: GameUnitType.warrior, posture: UnitPosture.fortified),
        ],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'unit_not_merchant',
      );
      _expectAssignRejected(
        units: [_merchant(posture: UnitPosture.fortified)],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'unit_unavailable',
      );
      _expectAssignRejected(
        units: [_merchant(col: 1)],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'merchant_not_in_city',
      );
      _expectAssignRejected(
        units: [_merchant()],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'destination_city_not_found',
      );
      _expectAssignRejected(
        units: [_merchant()],
        cities: [
          cities.first,
          _city('foreign', 3, owner: _otherPlayerId),
        ],
        destinationCityId: 'foreign',
        reason: 'destination_city_not_controlled',
      );
      _expectAssignRejected(
        units: [_merchant()],
        cities: cities,
        destinationCityId: 'origin',
        reason: 'destination_city_is_origin',
      );
      _expectAssignRejected(
        units: [_merchant()],
        cities: cities,
        destinationCityId: 'destination',
        mapData: _lineMap(blockedCol: 1),
        reason: 'merchant_route_not_found',
      );
    });
  });

  group('MerchantRoutingCommandResolver.moveToCity', () {
    test('queues immutable city travel and preserves other units', () {
      final merchant = _merchant(col: 1);
      final guard = _unit(id: 'guard', col: 3);
      final units = [merchant, guard];

      final result = MerchantRoutingCommandResolver.moveToCity(
        units: units,
        cities: _cities(),
        command: const MoveMerchantToCityCommand('merchant', 'destination'),
        actorPlayerId: _playerId,
        mapData: _lineMap(),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.units, units), isFalse);
      expect(identical(result.units.last, guard), isTrue);
      expect(() => result.units.clear(), throwsUnsupportedError);
      final updated = result.units.first;
      expect(updated.posture, UnitPosture.active);
      expect(updated.merchantTradeRoute, isNull);
      expect(updated.queuedPath?.targetCol, 3);
      expect(updated.queuedPath?.targetRow, 0);
      expect(updated.queuedPath?.steps.map((step) => step.col), [1, 2, 3]);
    });

    test('accepted semantic no-op preserves units identity', () {
      final first = MerchantRoutingCommandResolver.moveToCity(
        units: [_merchant(col: 1)],
        cities: _cities(),
        command: const MoveMerchantToCityCommand('merchant', 'destination'),
        actorPlayerId: _playerId,
        mapData: _lineMap(),
      );

      final second = MerchantRoutingCommandResolver.moveToCity(
        units: first.units,
        cities: _cities(),
        command: const MoveMerchantToCityCommand('merchant', 'destination'),
        actorPlayerId: _playerId,
        mapData: _lineMap(),
      );

      expect(second.accepted, isTrue);
      expect(identical(second.units, first.units), isTrue);
    });

    test('preserves exact rejection precedence and input identity', () {
      final cities = _cities();
      _expectMoveRejected(
        units: const [],
        cities: cities,
        actorPlayerId: _otherPlayerId,
        destinationCityId: 'missing',
        reason: 'unit_not_found',
      );
      _expectMoveRejected(
        units: [
          _unit(
            ownerPlayerId: _otherPlayerId,
            type: GameUnitType.warrior,
            posture: UnitPosture.fortified,
          ),
        ],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'unit_not_controlled',
      );
      _expectMoveRejected(
        units: [
          _unit(type: GameUnitType.warrior, posture: UnitPosture.fortified),
        ],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'unit_not_merchant',
      );
      _expectMoveRejected(
        units: [_merchant(col: 1, merchantTradeRoute: _route())],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'unit_unavailable',
      );
      _expectMoveRejected(
        units: [_merchant(col: 1)],
        cities: cities,
        destinationCityId: 'missing',
        reason: 'destination_city_not_found',
      );
      _expectMoveRejected(
        units: [_merchant(col: 1)],
        cities: [
          cities.first,
          _city('foreign', 3, owner: _otherPlayerId),
        ],
        destinationCityId: 'foreign',
        reason: 'destination_city_not_controlled',
      );
      _expectMoveRejected(
        units: [_merchant(col: 3)],
        cities: cities,
        destinationCityId: 'destination',
        reason: 'destination_city_is_current',
      );
      _expectMoveRejected(
        units: [_merchant(col: 1)],
        cities: cities,
        destinationCityId: 'destination',
        mapData: _lineMap(blockedCol: 2),
        reason: 'merchant_city_path_not_found',
      );
    });
  });
}
