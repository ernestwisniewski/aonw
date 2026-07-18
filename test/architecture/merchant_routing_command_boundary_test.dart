import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'merchant_routing_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'persistent_merchant_trade_route_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'domain_merchant_routing_command_resolver.dart';
const _localCallSite =
    'lib/game/domain/reducer/diplomacy/merchant_trade_route_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_merchant_routing.dart';
const _fullStateSimulationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';

void main() {
  test('merchant routing paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    const kernelCallSites = {
      _persistentAdapterPath,
      _domainAdapterPath,
      _localCallSite,
      _serverCallSite,
    };

    for (final method in const ['assignRoute', 'moveToCity']) {
      expect(
        staticMemberReferencePaths(
          sources,
          'MerchantRoutingCommandResolver',
          method,
        ),
        kernelCallSites,
        reason: 'Unexpected MerchantRoutingCommandResolver.$method call-sites.',
      );
      expect(
        instanceMemberReferencePaths(
          sources,
          'PersistentMerchantTradeRouteResolver',
          method,
        ),
        {_fullStateSimulationCallSite},
        reason:
            'Unexpected PersistentMerchantTradeRouteResolver.$method '
            'call-sites.',
      );
    }

    final kernelSource = sources[_kernelPath];
    expect(
      kernelSource,
      isNotNull,
      reason: 'The state-neutral merchant routing kernel must exist.',
    );
    final kernelTypes = namedTypeReferencesInSource(
      kernelSource!,
      path: _kernelPath,
    );
    final forbiddenTypes = typeNamesBackedBy(sources, const {
      'PersistentGameState',
      'DomainState',
      'CanonicalGameSnapshot',
      'GameState',
      'GameRuntimeState',
      'PersistedInteractionState',
      'GameInteractionState',
      'PendingPlayerAction',
      'GameSelection',
      'MapData',
      'FogOfWarState',
      'FogOfWarService',
      'FogVisibilityQuery',
      'GameEvent',
      'GameStateTransition',
      'UiEffect',
    });
    expect(kernelTypes.intersection(forbiddenTypes), isEmpty);
  });

  test('static guard separates resolver calls from routing-rule calls', () {
    final sources = <String, String>{
      'kernel.dart': '''
abstract final class MerchantRoutingCommandResolver {
  static void assignRoute() {}
  static void moveToCity() {}
}
''',
      'alias.dart': '''
typedef RoutingKernel = MerchantRoutingCommandResolver;
void apply() => RoutingKernel.assignRoute();
''',
      'prefixed.dart': '''
void apply() => core.MerchantRoutingCommandResolver.moveToCity();
''',
      'selection.dart': '''
abstract final class MerchantTradeRouteRules {
  static void planRoute() {}
  static void planMoveToCity() {}
}
void inspectCandidates() {
  MerchantTradeRouteRules.planRoute();
  MerchantTradeRouteRules.planMoveToCity();
}
''',
    };

    expect(
      staticMemberReferencePaths(
        sources,
        'MerchantRoutingCommandResolver',
        'assignRoute',
      ),
      {'alias.dart'},
    );
    expect(
      staticMemberReferencePaths(
        sources,
        'MerchantRoutingCommandResolver',
        'moveToCity',
      ),
      {'prefixed.dart'},
    );
  });
}
