import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _researchKernelPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'select_technology_resolver.dart';
const _researchPendingPolicyPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'research_selection_pending_action_policy.dart';
const _persistentResearchAdapterPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'persistent_research_command_resolver.dart';
const _domainResearchAdapterPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'domain_research_command_resolver.dart';
const _localResearchCallSite =
    'lib/game/domain/reducer/research/research_reducer.dart';
const _serverResearchCallSite =
    'server/lib/src/multiplayer/server_command_reducer_research.dart';
const _mctsResearchCallSite =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_economy_command_applier.dart';
const _mctsPersistentResearchCallSite =
    'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';
const _simulationPersistentResearchCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';

void main() {
  test('research paths share one state-neutral kernel and policy', () {
    final sources = productionDartSources();
    expect(
      staticMemberReferencePaths(
        sources,
        'SelectTechnologyResolver',
        'selectTechnology',
      ),
      {
        _persistentResearchAdapterPath,
        _domainResearchAdapterPath,
        _localResearchCallSite,
        _serverResearchCallSite,
        _mctsResearchCallSite,
      },
    );
    expect(
      staticMemberReferencePaths(
        sources,
        'ResearchSelectionPendingActionPolicy',
        'afterAcceptedSelection',
      ),
      {
        _persistentResearchAdapterPath,
        _localResearchCallSite,
        _serverResearchCallSite,
      },
    );
    expect(
      staticMemberReferencePaths(
        sources,
        'ResearchOverflowRules',
        'applyToSelectedTechnology',
      ),
      {_researchKernelPath},
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'PersistentResearchCommandResolver',
        'selectTechnology',
      ),
      {_mctsPersistentResearchCallSite, _simulationPersistentResearchCallSite},
    );

    final kernelTypes = namedTypeReferencesInSource(
      sources[_researchKernelPath]!,
      path: _researchKernelPath,
    );
    expect(
      kernelTypes.intersection(const {
        'PersistentGameState',
        'DomainState',
        'CanonicalGameSnapshot',
        'GameState',
        'GameRuntimeState',
        'PendingPlayerAction',
      }),
      isEmpty,
    );
    final policyTypes = namedTypeReferencesInSource(
      sources[_researchPendingPolicyPath]!,
      path: _researchPendingPolicyPath,
    );
    expect(
      policyTypes.intersection(const {
        'PersistentGameState',
        'DomainState',
        'CanonicalGameSnapshot',
        'GameState',
        'GameRuntimeState',
      }),
      isEmpty,
    );
  });
}
