import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/city/'
    'rush_production_command_resolver.dart';
const _expectedKernelClosure = {
  _kernelPath,
  'packages/aonw_core/lib/game/domain/city/'
      'rush_production_command_completion.dart',
  'packages/aonw_core/lib/game/domain/city/'
      'rush_production_command_economy.dart',
};
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_city_production_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_city_production_resolver.dart';
const _localCallSite =
    'lib/game/domain/reducer/city/city_production_reducer_rush.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_production.dart';

void main() {
  test('rush paths share one state-neutral production kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'RushProductionCommandResolver',
        'resolve',
      ),
      {
        _persistentAdapterPath: 1,
        _domainAdapterPath: 1,
        _localCallSite: 1,
        _serverCallSite: 1,
      },
      reason:
          'RushProductionCommandResolver.resolve must have exactly four '
          'production consumers and must not expand into MCTS or economy '
          'simulation.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'PersistentCityProductionResolver',
        'rushProduction',
      ),
      isEmpty,
      reason:
          'Production consumers must not bypass the neutral RushProduction '
          'kernel through the Persistent adapter.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DomainCityProductionResolver',
        'rushProduction',
      ),
      isEmpty,
      reason:
          'Production consumers must not bypass the neutral RushProduction '
          'kernel through the Domain adapter.',
    );
  });

  test('rush kernel exposes only explicit rule-state slices', () {
    final sources = productionDartSources();
    final kernelSource = sources[_kernelPath];
    expect(
      kernelSource,
      isNotNull,
      reason: 'The state-neutral RushProduction kernel must exist.',
    );

    final closure = _libraryPartClosure(sources, mainPath: _kernelPath);
    expect(
      closure.missingPaths,
      isEmpty,
      reason: 'Every RushProduction part directive must resolve to a source.',
    );
    expect(
      closure.paths,
      _expectedKernelClosure,
      reason: 'The complete RushProduction library closure must stay reviewed.',
    );
    final kernelSources = {
      for (final path in closure.paths) path: sources[path]!,
    };
    final kernelTypes = {
      for (final entry in kernelSources.entries)
        ...namedTypeReferencesInSource(entry.value, path: entry.key),
    };
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
      'MapTileCatalog',
      'MapTileSource',
      'MapTileView',
      'MapSurvey',
      'WorldMap',
      'WorldMapReadView',
      'TileData',
      'FogOfWarState',
      'FogOfWarService',
      'FogVisibilityQuery',
      'GameStateTransition',
      'UiEffect',
    });
    expect(
      kernelTypes.intersection(forbiddenTypes),
      isEmpty,
      reason:
          'RushProduction must consume explicit domain slices rather than a '
          'full state, wide map, persistence DTO, or UI boundary.',
    );

    final mapBoundaryTypes = typeNamesBackedBy(sources, const {
      'MapData',
      'MapDefinition',
      'MapReadView',
      'MapTileLookup',
      'MapTraversalView',
      'MapTileCatalog',
      'MapTileSource',
      'MapSurvey',
      'WorldMap',
      'WorldMapReadView',
    });
    final parameterTypes = classMethodParameterNamedTypes(
      kernelSource!,
      path: _kernelPath,
      className: 'RushProductionCommandResolver',
      methodName: 'resolve',
    );
    final mapParameters = {
      for (final entry in parameterTypes.entries)
        if (entry.value.intersection(mapBoundaryTypes).isNotEmpty) entry.key,
    };
    expect(mapParameters, {'mapTiles'});
    expect(
      classMethodParameterTypeSource(
        kernelSource,
        path: _kernelPath,
        className: 'RushProductionCommandResolver',
        methodName: 'resolve',
        parameterName: 'mapTiles',
      ),
      'MapTileLookup',
      reason: 'RushProduction must expose one exact bounded map dependency.',
    );
  });

  test('rush static guard catches aliases, prefixes, and tear-offs', () {
    final sources = <String, String>{
      'kernel.dart': '''
abstract final class RushProductionCommandResolver {
  static void resolve() {}
}
''',
      'alias.dart': '''
typedef RushKernel = RushProductionCommandResolver;
void apply() => RushKernel.resolve();
''',
      'prefixed.dart': '''
void apply() => core.RushProductionCommandResolver.resolve();
''',
      'tear_off.dart': '''
final applyRush = RushProductionCommandResolver.resolve;
''',
      'duplicate.dart': '''
void applyOnce() => RushProductionCommandResolver.resolve();
final applyAgain = RushProductionCommandResolver.resolve;
''',
      'unrelated.dart': '''
abstract final class LegacyRushProductionCommandResolver {
  static void resolve() {}
}
void apply() => LegacyRushProductionCommandResolver.resolve();
''',
    };

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'RushProductionCommandResolver',
        'resolve',
      ),
      {
        'alias.dart': 1,
        'prefixed.dart': 1,
        'tear_off.dart': 1,
        'duplicate.dart': 2,
      },
    );
  });

  test('rush closure follows part directives instead of file names', () {
    const mainPath = 'lib/rush_production_command_resolver.dart';
    final closure = _libraryPartClosure(const {
      mainPath: "part 'helpers/odd_name.dart';",
      'lib/helpers/odd_name.dart': "part of '../main.dart';",
      'lib/rush_production_command_orphan.dart': "part of 'main.dart';",
    }, mainPath: mainPath);

    expect(closure.paths, {mainPath, 'lib/helpers/odd_name.dart'});
    expect(closure.missingPaths, isEmpty);

    final incomplete = _libraryPartClosure(const {
      mainPath: "part 'missing.dart';",
    }, mainPath: mainPath);
    expect(incomplete.missingPaths, {'lib/missing.dart'});
  });
}

({Set<String> paths, Set<String> missingPaths}) _libraryPartClosure(
  Map<String, String> sources, {
  required String mainPath,
}) {
  final paths = <String>{};
  final missingPaths = <String>{};
  final pendingPaths = <String>[mainPath];
  while (pendingPaths.isNotEmpty) {
    final path = pendingPaths.removeLast();
    if (!paths.add(path)) continue;
    final source = sources[path];
    if (source == null) {
      missingPaths.add(path);
      continue;
    }
    final unit = parseString(content: source, path: path).unit;
    for (final directive in unit.directives.whereType<PartDirective>()) {
      final uri = directive.uri.stringValue;
      if (uri == null) {
        missingPaths.add('$path::<non-static-part-uri>');
        continue;
      }
      pendingPaths.add(Uri.parse(path).resolve(uri).path);
    }
  }
  return (paths: paths, missingPaths: missingPaths);
}
