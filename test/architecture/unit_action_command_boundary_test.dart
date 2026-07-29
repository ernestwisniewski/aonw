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
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'domain_unit_action_command_resolver.dart';

void main() {
  test('unit action paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    const expectedStaticCallSites = {
      'cancelUnitAction': {_domainAdapterPath},
      'skipUnitTurn': {_domainAdapterPath},
      'fortifyUnit': {_domainAdapterPath},
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

Set<String> _importUris(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  return unit.directives
      .whereType<ImportDirective>()
      .map((directive) => directive.uri.stringValue)
      .whereType<String>()
      .toSet();
}
