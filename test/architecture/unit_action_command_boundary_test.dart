import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/movement/'
    'unit_action_command_resolver.dart';
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
      'skipUnitTurn': sharedKernelCallSites,
      'fortifyUnit': sharedKernelCallSites,
    };
    const expectedPersistentCallSites = {
      _economySimulationCallSite,
      _fullMctsCallSite,
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
        expectedPersistentCallSites,
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
}
