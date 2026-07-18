import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/city/'
    'city_founding_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_city_founding_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_city_founding_resolver.dart';
const _commandPath =
    'packages/aonw_core/lib/game/domain/command/city_commands.dart';
const _localCallSite =
    'lib/game/domain/reducer/city/city_founding_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_city_founding.dart';
const _lightweightMctsCallSite =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_economy_command_applier.dart';
const _fullMctsCallSite = 'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';
const _economySimulationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';

void main() {
  test('city founding paths share one state-neutral command kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferencePaths(
        sources,
        'CityFoundingCommandResolver',
        'foundCity',
      ),
      {
        _persistentAdapterPath,
        _domainAdapterPath,
        _localCallSite,
        _serverCallSite,
        _lightweightMctsCallSite,
      },
      reason: 'Unexpected CityFoundingCommandResolver.foundCity call-sites.',
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'PersistentCityFoundingResolver',
        'foundCity',
      ),
      {_fullMctsCallSite, _economySimulationCallSite},
      reason: 'Unexpected PersistentCityFoundingResolver.foundCity call-sites.',
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'DomainCityFoundingResolver',
        'foundCity',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral city-founding kernel.',
    );
  });

  test(
    'city founding kernel depends only on authoritative rule-state slices',
    () {
      final sources = productionDartSources();
      final kernelSource = sources[_kernelPath];
      expect(
        kernelSource,
        isNotNull,
        reason: 'The state-neutral city-founding kernel must exist.',
      );
      final kernelTypes = namedTypeReferencesInSource(
        kernelSource!,
        path: _kernelPath,
      );
      final forbiddenTypes = typeNamesBackedBy(sources, const {
        'PersistentGameState',
        'PersistentCityFoundingResolver',
        'PersistentCityFoundingResult',
        'DomainState',
        'DomainCityFoundingResolver',
        'DomainCityFoundingResult',
        'CanonicalGameSnapshot',
        'GameState',
        'GameRuntimeState',
        'GameSave',
        'PersistedInteractionState',
        'GameInteractionState',
        'PendingPlayerAction',
        'GameSelection',
        'GameRuleset',
        'CityRuleset',
        'MapData',
        'MapDefinition',
        'MapReadView',
        'MapTraversalView',
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
    },
  );

  test('FoundCity command requires an explicit controlled-hex payload', () {
    final source = File(_commandPath).readAsStringSync();
    final unit = parseString(content: source, path: _commandPath).unit;
    final declarations = unit.declarations
        .whereType<ClassDeclaration>()
        .where(
          (declaration) =>
              declaration.namePart.typeName.lexeme == 'FoundCityCommand',
        )
        .toList();
    expect(declarations, hasLength(1));

    final constructors = declarations.single.body.members
        .whereType<ConstructorDeclaration>()
        .where((constructor) => constructor.name == null)
        .toList();
    expect(constructors, hasLength(1));
    final parameters = constructors.single.parameters.parameters
        .whereType<DefaultFormalParameter>()
        .where((parameter) => parameter.name?.lexeme == 'controlledHexes')
        .toList();
    expect(parameters, hasLength(1));
    expect(parameters.single.isRequiredNamed, isTrue);
    expect(parameters.single.defaultValue, isNull);
  });

  test(
    'city founding static guard catches aliases, prefixes, and tear-offs',
    () {
      final sources = <String, String>{
        'kernel.dart': '''
abstract final class CityFoundingCommandResolver {
  static void foundCity() {}
}
''',
        'alias.dart': '''
typedef FoundingKernel = CityFoundingCommandResolver;
void apply() => FoundingKernel.foundCity();
''',
        'prefixed.dart': '''
void apply() => core.CityFoundingCommandResolver.foundCity();
''',
        'tear_off.dart': '''
final foundCity = CityFoundingCommandResolver.foundCity;
''',
        'unrelated.dart': '''
abstract final class LegacyCityFoundingCommandResolver {
  static void foundCity() {}
}
void apply() => LegacyCityFoundingCommandResolver.foundCity();
''',
      };

      expect(
        staticMemberReferencePaths(
          sources,
          'CityFoundingCommandResolver',
          'foundCity',
        ),
        {'alias.dart', 'prefixed.dart', 'tear_off.dart'},
      );
    },
  );
}
