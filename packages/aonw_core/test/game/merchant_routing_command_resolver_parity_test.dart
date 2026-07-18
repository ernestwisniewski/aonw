import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

part 'merchant_routing_command_resolver_parity_test_support.dart';

void main() {
  group('merchant routing persistent/domain adapter parity', () {
    test('assign route has exact state-boundary parity', () {
      final states = _routingStates(
        merchant: _routingMerchant(
          queuedPath: _routingQueuedPath(),
          posture: UnitPosture.autoExploring,
        ),
      );
      const command = AssignMerchantTradeRouteCommand(
        'merchant',
        'destination',
      );

      final persistent = const PersistentMerchantTradeRouteResolver()
          .assignRoute(
            state: states.persistent,
            command: command,
            actorPlayerId: _routingPlayerId,
            mapData: _routingMap(),
          );
      final domain = const DomainMerchantRoutingCommandResolver().assignRoute(
        state: states.domain,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );

      _expectRoutingAcceptedParity(states, persistent, domain);
      final merchant = persistent.state.units.first;
      expect(merchant.posture, UnitPosture.active);
      expect(merchant.queuedPath, isNull);
      expect(merchant.merchantTradeRoute?.originCityId, 'origin');
      expect(merchant.merchantTradeRoute?.destinationCityId, 'destination');
    });

    test('move to city has exact state-boundary parity', () {
      final states = _routingStates(merchant: _routingMerchant(col: 1));
      const command = MoveMerchantToCityCommand('merchant', 'destination');

      final persistent = const PersistentMerchantTradeRouteResolver()
          .moveToCity(
            state: states.persistent,
            command: command,
            actorPlayerId: _routingPlayerId,
            mapData: _routingMap(),
          );
      final domain = const DomainMerchantRoutingCommandResolver().moveToCity(
        state: states.domain,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );

      _expectRoutingAcceptedParity(states, persistent, domain);
      final merchant = persistent.state.units.first;
      expect(merchant.merchantTradeRoute, isNull);
      expect(merchant.queuedPath?.targetCol, 3);
      expect(merchant.queuedPath?.targetRow, 0);
    });

    test('reject preserves both complete state identities', () {
      final states = _routingStates(merchant: _routingMerchant());
      const command = AssignMerchantTradeRouteCommand(
        'merchant',
        'destination',
      );

      final persistent = const PersistentMerchantTradeRouteResolver()
          .assignRoute(
            state: states.persistent,
            command: command,
            actorPlayerId: _routingOtherPlayerId,
            mapData: _routingMap(),
          );
      final domain = const DomainMerchantRoutingCommandResolver().assignRoute(
        state: states.domain,
        command: command,
        actorPlayerId: _routingOtherPlayerId,
        mapData: _routingMap(),
      );

      expect(persistent.accepted, isFalse);
      expect(domain.accepted, isFalse);
      expect(persistent.reason, 'unit_not_controlled');
      expect(domain.reason, 'unit_not_controlled');
      expect(identical(persistent.state, states.persistent), isTrue);
      expect(identical(domain.state, states.domain), isTrue);
    });

    test('assign accepted no-op preserves both state identities', () {
      final states = _routingStates(merchant: _routingMerchant());
      const command = AssignMerchantTradeRouteCommand(
        'merchant',
        'destination',
      );
      const persistentResolver = PersistentMerchantTradeRouteResolver();
      const domainResolver = DomainMerchantRoutingCommandResolver();

      final firstPersistent = persistentResolver.assignRoute(
        state: states.persistent,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );
      final firstDomain = domainResolver.assignRoute(
        state: states.domain,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );
      final secondPersistent = persistentResolver.assignRoute(
        state: firstPersistent.state,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );
      final secondDomain = domainResolver.assignRoute(
        state: firstDomain.state,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );

      expect(secondPersistent.accepted, isTrue);
      expect(secondDomain.accepted, isTrue);
      expect(identical(secondPersistent.state, firstPersistent.state), isTrue);
      expect(identical(secondDomain.state, firstDomain.state), isTrue);
    });

    test('move accepted no-op preserves both state identities', () {
      final states = _routingStates(merchant: _routingMerchant(col: 1));
      const command = MoveMerchantToCityCommand('merchant', 'destination');
      const persistentResolver = PersistentMerchantTradeRouteResolver();
      const domainResolver = DomainMerchantRoutingCommandResolver();

      final firstPersistent = persistentResolver.moveToCity(
        state: states.persistent,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );
      final firstDomain = domainResolver.moveToCity(
        state: states.domain,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );
      final secondPersistent = persistentResolver.moveToCity(
        state: firstPersistent.state,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );
      final secondDomain = domainResolver.moveToCity(
        state: firstDomain.state,
        command: command,
        actorPlayerId: _routingPlayerId,
        mapData: _routingMap(),
      );

      expect(secondPersistent.accepted, isTrue);
      expect(secondDomain.accepted, isTrue);
      expect(identical(secondPersistent.state, firstPersistent.state), isTrue);
      expect(identical(secondDomain.state, firstDomain.state), isTrue);
    });
  });
}
