import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/city/'
    'city_production_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_city_production_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_city_production_resolver.dart';
const _localCallSite =
    'lib/game/domain/reducer/city/city_production_reducer_project.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_production.dart';
const _lightweightMctsCallSite =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_economy_command_applier.dart';
const _fullMctsCallSite = 'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';
const _economySimulationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier_production.dart';

void main() {
  test('city project paths share one state-neutral production kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferencePaths(
        sources,
        'CityProductionCommandResolver',
        'startCityProject',
      ),
      {
        _persistentAdapterPath,
        _domainAdapterPath,
        _localCallSite,
        _serverCallSite,
        _lightweightMctsCallSite,
      },
      reason:
          'Unexpected CityProductionCommandResolver.startCityProject '
          'call-sites.',
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'PersistentCityProductionResolver',
        'startCityProject',
      ),
      {_fullMctsCallSite, _economySimulationCallSite},
      reason:
          'Unexpected PersistentCityProductionResolver.startCityProject '
          'call-sites.',
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'DomainCityProductionResolver',
        'startCityProject',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral production kernel.',
    );
  });

  test('city project kernel depends only on production rule-state slices', () {
    final sources = productionDartSources();
    final kernelSource = sources[_kernelPath];
    expect(
      kernelSource,
      isNotNull,
      reason: 'The state-neutral city production kernel must exist.',
    );
    final kernelTypes = namedTypeReferencesInSource(
      kernelSource!,
      path: _kernelPath,
    );
    final forbiddenTypes = typeNamesBackedBy(sources, const {
      'PersistentGameState',
      'PersistentCityProductionResolver',
      'PersistentCityProductionResult',
      'DomainState',
      'DomainCityProductionResolver',
      'DomainCityProductionResult',
      'CanonicalGameSnapshot',
      'GameState',
      'GameRuntimeState',
      'GameSave',
      'PersistedInteractionState',
      'GameInteractionState',
      'PendingPlayerAction',
      'GameSelection',
      'GameRuleset',
      'MapData',
      'MapDefinition',
      'MapReadView',
      'MapTraversalView',
      'MapTileLookup',
      'MapTileView',
      'MapTileCatalog',
      'MapSurvey',
      'WorldMap',
      'WorldMapReadView',
      'TileData',
      'FogOfWarState',
      'FogOfWarService',
      'FogVisibilityQuery',
      'GameEvent',
      'GameStateTransition',
      'UiEffect',
    });
    expect(kernelTypes.intersection(forbiddenTypes), isEmpty);
  });

  test(
    'city production static guard catches aliases, prefixes, and tear-offs',
    () {
      final sources = <String, String>{
        'kernel.dart': '''
abstract final class CityProductionCommandResolver {
  static void startCityProject() {}
}
''',
        'alias.dart': '''
typedef ProductionKernel = CityProductionCommandResolver;
void apply() => ProductionKernel.startCityProject();
''',
        'prefixed.dart': '''
void apply() => core.CityProductionCommandResolver.startCityProject();
''',
        'tear_off.dart': '''
final startProject = CityProductionCommandResolver.startCityProject;
''',
        'unrelated.dart': '''
abstract final class LegacyCityProductionCommandResolver {
  static void startCityProject() {}
}
void apply() => LegacyCityProductionCommandResolver.startCityProject();
''',
      };

      expect(
        staticMemberReferencePaths(
          sources,
          'CityProductionCommandResolver',
          'startCityProject',
        ),
        {'alias.dart', 'prefixed.dart', 'tear_off.dart'},
      );
    },
  );
}
