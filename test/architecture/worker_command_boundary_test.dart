import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/city/worker_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_worker_command_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_worker_command_resolver.dart';
const _localCallSite = 'lib/game/domain/reducer/worker/worker_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_worker.dart';
const _economySimulationCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';
const _lightweightMctsCallSite =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_economy_command_applier.dart';
const _fullMctsCallSite = 'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';

void main() {
  test('worker command paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    const kernelCallSites = {
      _persistentAdapterPath,
      _domainAdapterPath,
      _localCallSite,
      _serverCallSite,
    };
    const persistentCallSites = <String, Set<String>>{
      'selectWorkerImprovement': {
        _economySimulationCallSite,
        _lightweightMctsCallSite,
        _fullMctsCallSite,
      },
      'confirmWorkerImprovement': {_fullMctsCallSite},
      'cancelWorkerJob': {_economySimulationCallSite},
      'assignWorkerToHex': {
        _economySimulationCallSite,
        _lightweightMctsCallSite,
        _fullMctsCallSite,
      },
      'cancelWorkerAssignment': {_economySimulationCallSite},
    };

    for (final entry in persistentCallSites.entries) {
      expect(
        staticMemberReferencePaths(sources, 'WorkerCommandResolver', entry.key),
        kernelCallSites,
        reason: 'Unexpected WorkerCommandResolver.${entry.key} call-sites.',
      );
      expect(
        instanceMemberReferencePaths(
          sources,
          'PersistentWorkerCommandResolver',
          entry.key,
        ),
        entry.value,
        reason:
            'Unexpected PersistentWorkerCommandResolver.${entry.key} '
            'call-sites.',
      );
      expect(
        instanceMemberReferencePaths(
          sources,
          'DomainWorkerCommandResolver',
          entry.key,
        ),
        isEmpty,
        reason: 'Production must call the state-neutral worker kernel.',
      );
    }
  });

  test('worker kernel exposes only rule-state slices and a tile lookup', () {
    final sources = productionDartSources();
    final kernelSource = sources[_kernelPath];
    expect(kernelSource, isNotNull);
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
      'GameInteractionState',
      'GameSelection',
      'MapData',
      'MapDefinition',
      'MapReadView',
      'MapTraversalView',
      'MapTileView',
      'WorldMap',
      'WorldMapReadView',
      'FogOfWarState',
      'FogOfWarService',
      'FogVisibilityQuery',
      'GameEvent',
      'GameStateTransition',
      'UiEffect',
    });
    expect(kernelTypes.intersection(forbiddenTypes), isEmpty);
  });

  test('worker static guard catches aliases, prefixes, and tear-offs', () {
    final sources = <String, String>{
      'kernel.dart': '''
abstract final class WorkerCommandResolver {
  static void assignWorkerToHex() {}
}
''',
      'alias.dart': '''
typedef WorkerKernel = WorkerCommandResolver;
void apply() => WorkerKernel.assignWorkerToHex();
''',
      'prefixed.dart': '''
void apply() => core.WorkerCommandResolver.assignWorkerToHex();
''',
      'tear_off.dart': '''
final applyAssignment = WorkerCommandResolver.assignWorkerToHex;
''',
      'unrelated.dart': '''
abstract final class LegacyWorkerCommandResolver {
  static void assignWorkerToHex() {}
}
void apply() => LegacyWorkerCommandResolver.assignWorkerToHex();
''',
    };

    expect(
      staticMemberReferencePaths(
        sources,
        'WorkerCommandResolver',
        'assignWorkerToHex',
      ),
      {'alias.dart', 'prefixed.dart', 'tear_off.dart'},
    );
  });
}
