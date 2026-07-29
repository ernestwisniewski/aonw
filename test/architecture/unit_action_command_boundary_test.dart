import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'unit_action_command_resolver.dart';
const _autoExploreKernelPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'auto_explore_command_resolver.dart';
const _interactionRulesPath =
    'packages/aonw_core/lib/game/domain/state/'
    'persisted_interaction_unit_rules.dart';
const _interactionRulesUri =
    'package:aonw_core/game/domain/state/'
    'persisted_interaction_unit_rules.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'persistent_unit_action_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'domain_unit_action_command_resolver.dart';
const _localCallSite = 'lib/game/domain/reducer/movement/movement_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_unit_action.dart';
const _lightweightMctsCallSite =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_movement_command_applier.dart';
const _economySimulationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';
const _fullMctsCallSite = 'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';

void main() {
  test('persistent adapter exposes only map-independent unit actions', () {
    final sources = productionDartSources();

    expect(
      _persistentAdapterApiViolations(sources[_persistentAdapterPath]!),
      isEmpty,
    );
  });

  test('persistent adapter guard rejects a restored auto-explore method', () {
    final source = productionDartSources()[_persistentAdapterPath]!;
    for (final modifier in const ['', 'static ']) {
      final widened = source.replaceFirst(
        '  static PersistentUnitActionResult _applyUnitAction(',
        '''
  ${modifier}PersistentUnitActionResult autoExploreUnit() =>
      throw UnimplementedError();

  static PersistentUnitActionResult _applyUnitAction(''',
      );

      expect(
        _persistentAdapterApiViolations(widened),
        contains(
          'PersistentUnitActionResolver must expose only its reviewed actions',
        ),
        reason: 'modifier: ${modifier.isEmpty ? 'instance' : 'static'}',
      );
    }
  });

  test('unit action paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    const sharedKernelCallSites = {
      _persistentAdapterPath,
      _domainAdapterPath,
      _localCallSite,
      _serverCallSite,
    };
    const expectedStaticCallSites = {
      'cancelUnitAction': {...sharedKernelCallSites, _lightweightMctsCallSite},
      'skipUnitTurn': {_domainAdapterPath},
      'fortifyUnit': {_domainAdapterPath},
    };
    const expectedPersistentCallSites = {
      'cancelUnitAction': {_economySimulationCallSite, _fullMctsCallSite},
      'skipUnitTurn': <String>{},
      'fortifyUnit': <String>{},
    };

    for (final entry in expectedStaticCallSites.entries) {
      expect(
        staticMemberReferencePaths(
          sources,
          'UnitActionCommandResolver',
          entry.key,
        ),
        entry.value,
        reason: 'Unexpected UnitActionCommandResolver.${entry.key} call-sites.',
      );
      expect(
        instanceMemberReferencePaths(
          sources,
          'PersistentUnitActionResolver',
          entry.key,
        ),
        expectedPersistentCallSites[entry.key],
        reason:
            'Unexpected PersistentUnitActionResolver.${entry.key} '
            'call-sites.',
      );
    }

    final kernelTypes = namedTypeReferencesInSource(
      sources[_kernelPath]!,
      path: _kernelPath,
    );
    final mapBoundaryTypes = typeNamesBackedBy(sources, const {
      'MapData',
      'MapDefinition',
      'MapSurvey',
      'MapTileCatalog',
      'MapTileLookup',
      'MapTileSource',
      'MapTraversalView',
      'MapReadView',
      'MapTileView',
      'WorldMap',
      'WorldMapReadView',
    });
    expect(
      kernelTypes.intersection({
        'PersistentGameState',
        'DomainState',
        'CanonicalGameSnapshot',
        'GameState',
        'GameRuntimeState',
        'GameInteractionState',
        'GameSelection',
        ...mapBoundaryTypes,
      }),
      isEmpty,
    );
    expect(
      staticMemberReferencePaths(sources, 'UnitFortificationRules', 'fortify'),
      {_kernelPath},
    );
  });

  test('auto explore stays outside the map-independent kernel', () {
    final sources = productionDartSources();
    final unit = parseString(
      content: sources[_kernelPath]!,
      path: _kernelPath,
    ).unit;
    final kernel = unit.declarations.whereType<ClassDeclaration>().singleWhere(
      (declaration) =>
          declaration.namePart.typeName.lexeme == 'UnitActionCommandResolver',
    );
    final kernelMethods = {
      for (final method in kernel.body.members.whereType<MethodDeclaration>())
        method.name.lexeme,
    };

    expect(kernelMethods, isNot(contains('autoExploreUnit')));
    expect(
      staticMemberReferencePaths(
        sources,
        'UnitActionCommandResolver',
        'autoExploreUnit',
      ),
      isEmpty,
    );
  });

  test('unit interaction cleanup has one state-container-neutral rule', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'PersistedInteractionUnitRules',
        'clearOwnedByUnit',
      ),
      {_kernelPath: 2, _autoExploreKernelPath: 2},
      reason: 'Selective unit interaction cleanup must not be duplicated.',
    );

    final rulesSource = sources[_interactionRulesPath];
    expect(
      rulesSource,
      isNotNull,
      reason: 'The state-container-neutral interaction rule must exist.',
    );
    final requiredRulesSource = rulesSource!;
    expect(
      namedTypeReferencesInSource(
        requiredRulesSource,
        path: _interactionRulesPath,
      ),
      {'PersistedInteractionState', 'String'},
    );
    expect(_importUris(requiredRulesSource, _interactionRulesPath), {
      'package:aonw_core/game/domain/state/'
          'canonical_game_snapshot.dart',
    });
    for (final path in const [_kernelPath, _autoExploreKernelPath]) {
      expect(
        _importUris(sources[path]!, path),
        contains(_interactionRulesUri),
        reason: '$path must import the narrow interaction-rule leaf.',
      );
    }
  });
}

List<String> _persistentAdapterApiViolations(String source) {
  final unit = parseString(content: source, path: _persistentAdapterPath).unit;
  final resolvers = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) =>
        declaration.namePart.typeName.lexeme == 'PersistentUnitActionResolver',
  );
  if (resolvers.length != 1) {
    return const ['PersistentUnitActionResolver must exist exactly once'];
  }
  final resolver = resolvers.single;
  final constructors = resolver.body.members
      .whereType<ConstructorDeclaration>()
      .toList(growable: false);
  final publicMethods = {
    for (final method in resolver.body.members.whereType<MethodDeclaration>())
      if (!method.name.lexeme.startsWith('_'))
        '${method.isStatic ? 'static' : 'instance'}:${method.name.lexeme}',
  };
  return [
    if (resolver.finalKeyword == null)
      'PersistentUnitActionResolver must remain final',
    if (constructors.length != 1 ||
        constructors.single.name != null ||
        constructors.single.constKeyword == null ||
        constructors.single.parameters.parameters.isNotEmpty)
      'PersistentUnitActionResolver must keep one const empty constructor',
    if (!_sameStringSet(publicMethods, const {'instance:cancelUnitAction'}))
      'PersistentUnitActionResolver must expose only its reviewed actions',
  ];
}

bool _sameStringSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

Set<String> _importUris(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  return unit.directives
      .whereType<ImportDirective>()
      .map((directive) => directive.uri.stringValue)
      .whereType<String>()
      .toSet();
}
