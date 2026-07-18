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
const _localBuildingCallSite =
    'lib/game/domain/reducer/city/city_production_reducer_building.dart';
const _localProjectCallSite =
    'lib/game/domain/reducer/city/city_production_reducer_project.dart';
const _localSpecializationCallSite =
    'lib/game/domain/reducer/city/'
    'city_production_reducer_specialization.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_production.dart';
const _lightweightMctsCallSite =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_economy_command_applier.dart';
const _fullMctsCallSite = 'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';
const _economySimulationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier_production.dart';
const _economySimulationSpecializationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';

void main() {
  test('city building paths share one state-neutral production kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'CityProductionCommandResolver',
        'startBuilding',
      ),
      {
        _persistentAdapterPath: 1,
        _domainAdapterPath: 1,
        _localBuildingCallSite: 1,
        _serverCallSite: 1,
        _lightweightMctsCallSite: 1,
      },
      reason:
          'Unexpected CityProductionCommandResolver.startBuilding '
          'call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'PersistentCityProductionResolver',
        'startBuilding',
      ),
      {_fullMctsCallSite: 1, _economySimulationCallSite: 1},
      reason:
          'Unexpected PersistentCityProductionResolver.startBuilding '
          'call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DomainCityProductionResolver',
        'startBuilding',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral production kernel.',
    );
  });

  test('city project paths share one state-neutral production kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'CityProductionCommandResolver',
        'startCityProject',
      ),
      {
        _persistentAdapterPath: 1,
        _domainAdapterPath: 1,
        _localProjectCallSite: 1,
        _serverCallSite: 1,
        _lightweightMctsCallSite: 1,
      },
      reason:
          'Unexpected CityProductionCommandResolver.startCityProject '
          'call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'PersistentCityProductionResolver',
        'startCityProject',
      ),
      {_fullMctsCallSite: 1, _economySimulationCallSite: 1},
      reason:
          'Unexpected PersistentCityProductionResolver.startCityProject '
          'call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DomainCityProductionResolver',
        'startCityProject',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral production kernel.',
    );
  });

  test('city specialization paths share one state-neutral kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'CityProductionCommandResolver',
        'setCitySpecialization',
      ),
      {
        _persistentAdapterPath: 1,
        _domainAdapterPath: 1,
        _localSpecializationCallSite: 1,
        _serverCallSite: 1,
        _lightweightMctsCallSite: 1,
      },
      reason:
          'Unexpected CityProductionCommandResolver.setCitySpecialization '
          'call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'PersistentCityProductionResolver',
        'setCitySpecialization',
      ),
      {_fullMctsCallSite: 1, _economySimulationSpecializationCallSite: 1},
      reason:
          'Unexpected PersistentCityProductionResolver.setCitySpecialization '
          'call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DomainCityProductionResolver',
        'setCitySpecialization',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral production kernel.',
    );
  });

  test(
    'city production kernel depends only on production rule-state slices',
    () {
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

      final mapTileLookupTypes = typeNamesBackedBy(sources, const {
        'MapTileLookup',
      });
      final typesOutsideStartBuilding = namedTypeReferencesOutsideClassMethods(
        kernelSource,
        path: _kernelPath,
        className: 'CityProductionCommandResolver',
        excludedMethodNames: const {'startBuilding'},
      );
      expect(
        typesOutsideStartBuilding.intersection(mapTileLookupTypes),
        isEmpty,
        reason: 'Only startBuilding may depend on bounded map lookup.',
      );
      final startBuildingParameterTypes = classMethodParameterNamedTypes(
        kernelSource,
        path: _kernelPath,
        className: 'CityProductionCommandResolver',
        methodName: 'startBuilding',
      );
      final mapParameters = {
        for (final entry in startBuildingParameterTypes.entries)
          if (entry.value.intersection(mapTileLookupTypes).isNotEmpty)
            entry.key,
      };
      expect(mapParameters, {'mapTiles'});
      expect(
        classMethodParameterTypeSource(
          kernelSource,
          path: _kernelPath,
          className: 'CityProductionCommandResolver',
          methodName: 'startBuilding',
          parameterName: 'mapTiles',
        ),
        'MapTileLookup',
      );
    },
  );

  test(
    'city production static guard catches aliases, prefixes, and tear-offs',
    () {
      for (final memberName in const {
        'startBuilding',
        'startCityProject',
        'setCitySpecialization',
      }) {
        final sources = <String, String>{
          'kernel.dart':
              '''
abstract final class CityProductionCommandResolver {
  static void $memberName() {}
}
''',
          'alias.dart':
              '''
typedef ProductionKernel = CityProductionCommandResolver;
void apply() => ProductionKernel.$memberName();
''',
          'prefixed.dart':
              '''
void apply() => core.CityProductionCommandResolver.$memberName();
''',
          'tear_off.dart':
              '''
final applyProduction = CityProductionCommandResolver.$memberName;
''',
          'duplicate.dart':
              '''
void applyOnce() => CityProductionCommandResolver.$memberName();
final applyAgain = CityProductionCommandResolver.$memberName;
''',
          'unrelated.dart':
              '''
abstract final class LegacyCityProductionCommandResolver {
  static void $memberName() {}
}
void apply() => LegacyCityProductionCommandResolver.$memberName();
''',
        };

        expect(
          staticMemberReferenceCountsByPath(
            sources,
            'CityProductionCommandResolver',
            memberName,
          ),
          {
            'alias.dart': 1,
            'prefixed.dart': 1,
            'tear_off.dart': 1,
            'duplicate.dart': 2,
          },
          reason: 'Static guard missed an indirect $memberName reference.',
        );
      }
    },
  );

  test('city building map dependency is scoped to one exact parameter', () {
    const cleanSource = '''
abstract final class CityProductionCommandResolver {
  static void startBuilding({required MapTileLookup mapTiles}) {}
  static void startCityProject({required CityRuleset cityRuleset}) {}
}
''';
    final cleanSources = {'kernel.dart': cleanSource};
    final cleanMapTypes = typeNamesBackedBy(cleanSources, const {
      'MapTileLookup',
    });
    expect(
      namedTypeReferencesOutsideClassMethods(
        cleanSource,
        className: 'CityProductionCommandResolver',
        excludedMethodNames: const {'startBuilding'},
      ).intersection(cleanMapTypes),
      isEmpty,
    );
    expect(
      classMethodParameterTypeSource(
        cleanSource,
        className: 'CityProductionCommandResolver',
        methodName: 'startBuilding',
        parameterName: 'mapTiles',
      ),
      'MapTileLookup',
    );

    const aliasedSource = '''
abstract final class CityProductionCommandResolver {
  static void startBuilding({required MapTileLookup mapTiles}) {}
  static void startCityProject({required Tiles mapTiles}) {}
}
''';
    final aliasedSources = {
      'aliases.dart': 'typedef Tiles = MapTileLookup;',
      'kernel.dart': aliasedSource,
    };
    final aliasedMapTypes = typeNamesBackedBy(aliasedSources, const {
      'MapTileLookup',
    });
    expect(
      namedTypeReferencesOutsideClassMethods(
        aliasedSource,
        className: 'CityProductionCommandResolver',
        excludedMethodNames: const {'startBuilding'},
      ).intersection(aliasedMapTypes),
      isNotEmpty,
      reason: 'Scoped guard must catch MapTileLookup-backed aliases.',
    );
  });
}
