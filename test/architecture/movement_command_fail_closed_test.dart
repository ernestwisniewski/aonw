import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/movement_adapter_boundary_guard.dart';
import 'support/movement_command_boundary_guard.dart';
import 'support/movement_instance_reference_guard.dart';
import 'support/movement_kernel_import_graph_guard.dart';
import 'support/movement_server_part_guard.dart';

void main() {
  test('production movement API and construction sites remain exact', () {
    final sources = productionDartSources();
    final runtimeSources = movementRuntimeSources(sources);
    expect(movementAdapterPublicApiViolations(sources), isEmpty);
    expect(
      movementConstructionReferenceCountsByPath(
        runtimeSources,
        'MovementCommandResolver',
      ),
      const {movementDomainAdapterPath: 1, movementAutoExploreKernelPath: 1},
    );
    expect(
      movementConstructionReferenceCountsByPath(
        runtimeSources,
        'DomainMoveUnitResolver',
      ),
      const {
        'packages/aonw_core/lib/game/application/engine/'
                'movement_engine_handler.dart':
            1,
      },
    );

    final reviewedCallSites = {
      for (final path in const {
        movementDomainAdapterPath,
        movementAutoExploreKernelPath,
      })
        path: sources[path]!,
    };
    expect(
      movementNamedMemberReferenceCountsByPath(reviewedCallSites, 'resolve'),
      const {movementDomainAdapterPath: 1, movementAutoExploreKernelPath: 1},
      reason: 'Each reviewed boundary must contain only its kernel resolve.',
    );
  });

  test('diagnostic workload has its own exact resolver boundary', () {
    final sources = productionDartSources();
    final diagnostic = {
      movementDiagnosticWorkloadPath: sources[movementDiagnosticWorkloadPath]!,
    };

    expect(
      movementInstanceMemberReferenceCountsByPath(
        diagnostic,
        'MovementCommandResolver',
        'resolve',
      ),
      const {movementDiagnosticWorkloadPath: 1},
    );
    expect(
      movementInstanceMemberReferenceCountsByPath(
        diagnostic,
        'DomainMoveUnitResolver',
        'resolve',
      ),
      const {movementDiagnosticWorkloadPath: 1},
    );
    expect(
      movementConstructionReferenceCountsByPath(
        diagnostic,
        'MovementCommandResolver',
      ),
      const {movementDiagnosticWorkloadPath: 2},
    );
    expect(
      movementConstructionReferenceCountsByPath(
        diagnostic,
        'DomainMoveUnitResolver',
      ),
      const {movementDiagnosticWorkloadPath: 1},
    );
    expect(
      movementNamedMemberReferenceCountsByPath(diagnostic, 'resolve'),
      const {movementDiagnosticWorkloadPath: 2},
    );
  });

  test(
    'only the reviewed diagnostic path is excluded from runtime consumers',
    () {
      final sources = {
        movementDiagnosticWorkloadPath:
            'void benchmark() => MovementCommandResolver().resolve();',
        'tool/performance/second_movement_consumer.dart':
            'void benchmark() => MovementCommandResolver().resolve();',
      };
      final runtime = movementRuntimeSources(sources);

      expect(runtime, isNot(contains(movementDiagnosticWorkloadPath)));
      expect(
        movementInstanceMemberReferenceCountsByPath(
          runtime,
          'MovementCommandResolver',
          'resolve',
        ),
        const {'tool/performance/second_movement_consumer.dart': 1},
        reason:
            'A second tool consumer must remain visible to the runtime gate.',
      );
    },
  );

  test('call-site guards catch an untyped factory and holder escape', () {
    final sources = <String, String>{
      'escaped.dart': '''
final resolver = MovementCommandResolver();
void reviewed() => resolver.resolve();
dynamic exposeResolver() => resolver;
void hidden() => exposeResolver().resolve();
''',
    };

    expect(
      movementInstanceMemberReferenceCountsByPath(
        sources,
        'MovementCommandResolver',
        'resolve',
      ),
      const {'escaped.dart': 1},
      reason: 'This fixture documents the receiver-inference blind spot.',
    );
    expect(
      movementConstructionReferenceCountsByPath(
        sources,
        'MovementCommandResolver',
      ),
      const {'escaped.dart': 1},
    );
    expect(
      movementNamedMemberReferenceCountsByPath(sources, 'resolve'),
      const {'escaped.dart': 2},
      reason: 'The exact reviewed file guard must catch the hidden call.',
    );
  });

  test('core API guard rejects widened constructors and declarations', () {
    final violations = movementStateShapeViolations('''
final class MovementCommandState {
  const MovementCommandState({
    required this.units,
    required this.cities,
    required this.fogOfWar,
    required this.diplomacy,
    required this.playerIds,
    Object? legacyBridge,
  });
  final List<GameUnit> units;
  final List<GameCity> cities;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
  final Iterable<String> playerIds;
}
final class ParallelMovementBridge {}
''');

    expect(
      violations,
      containsAll([
        'MovementCommandState file must declare only MovementCommandState',
        'MovementCommandState. constructor must expose its exact contract',
      ]),
    );
  });

  test('adapter API guard rejects a parallel routing method', () {
    final sources = productionDartSources();
    sources[movementDomainAdapterPath] = sources[movementDomainAdapterPath]!
        .replaceFirst('  DomainMoveUnitResult resolve({', '''
  DomainMoveUnitResult applyParallel() => throw UnimplementedError();

  DomainMoveUnitResult resolve({''');

    expect(
      movementAdapterPublicApiViolations(sources),
      contains('DomainMoveUnitResolver must not widen its public API'),
    );
  });

  test('kernel graph follows conditional imports and exports', () {
    const root = '${movementLibraryPath}conditional_root.dart';
    const approved = '${movementLibraryPath}unit_movement_plan.dart';
    const hidden = '${movementLibraryPath}conditional_hidden.dart';
    final graph = movementKernelImportGraph(
      {
        root: '''
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart'
  if (dart.library.io)
    'package:aonw_core/game/domain/movement/conditional_hidden.dart'
  if (dart.library.html)
    'package:aonw_core/game/domain/state/persistent_game_state.dart';
''',
        approved: 'final class UnitMovementPlan {}',
        hidden: 'void hiddenBridge() {}',
      },
      const {root},
    );
    final report = movementKernelImportGraphViolations(
      graph,
      expectedPaths: const {root, approved},
      forbiddenTypes: const {},
    ).join('\n');

    expect(graph.keys, contains(hidden));
    expect(report, contains('$hidden is an unexpected movement-kernel graph'));
    expect(
      report,
      contains(
        'imports unapproved dependency '
        'package:aonw_core/game/domain/state/persistent_game_state.dart',
      ),
    );
  });

  test('MapTileSource aliases cannot escape the pathfinder leaf', () {
    const root = '${movementLibraryPath}alias_consumer.dart';
    const pathfinder = '${movementLibraryPath}unit_movement_pathfinder.dart';
    final graph = movementKernelImportGraph(
      {
        root: '''
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
CompleteTiles widen(CompleteTiles source) => source;
''',
        pathfinder: '''
import 'package:aonw_core/map/domain/map_tile_source.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
typedef CompleteTiles = MapTileSource<MapTileView>;
''',
      },
      const {root},
    );

    expect(
      movementKernelImportGraphViolations(
        graph,
        expectedPaths: const {root, pathfinder},
        forbiddenTypes: const {},
      ).join('\n'),
      contains(
        '$root references MapTileSource outside the pathfinder leaf '
        'via CompleteTiles',
      ),
    );
  });

  test(
    'MapTileSource composition cannot escape through a pathfinder wrapper',
    () {
      const root = '${movementLibraryPath}wrapper_consumer.dart';
      const pathfinder = '${movementLibraryPath}unit_movement_pathfinder.dart';
      final graph = movementKernelImportGraph(
        {
          root: '''
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
HiddenTileSource widen(HiddenTileSource source) => source;
''',
          pathfinder: '''
import 'package:aonw_core/map/domain/map_tile_source.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
class UnitMovementPathfinder {}
class _PathNode {}
class _PathSearchResult {}
final class HiddenTileSource {
  const HiddenTileSource(this.source);
  final MapTileSource<MapTileView> source;
}
''',
        },
        const {root},
      );

      expect(
        movementKernelImportGraphViolations(
          graph,
          expectedPaths: const {root, pathfinder},
          forbiddenTypes: const {},
        ),
        contains(
          '$pathfinder must declare only the reviewed pathfinder classes',
        ),
      );
    },
  );

  test('server part rejects every extra top-level declaration', () {
    final violations = movementServerPartViolations({
      movementServerReducerPath: '''
part 'server_command_reducer_movement.dart';
class ServerCommandReducer {}
''',
      movementServerCallSite: '''
part of 'server_command_reducer.dart';
extension _ServerCommandReducerMovement on ServerCommandReducer {
  _CommandApplication _applyMoveUnit({
    required MapTraversalView mapView,
  }) => throw UnimplementedError();
}
extension _LegacyMovement on ServerCommandReducer {}
''',
    });

    expect(
      violations,
      contains(
        'movement server part must contain only its part-of directive and '
        'reviewed reducer extension',
      ),
    );
  });
}
