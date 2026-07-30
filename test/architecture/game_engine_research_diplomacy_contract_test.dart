import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/diplomacy_kernel_import_graph_guard.dart';
import 'support/map_boundary_source_guard.dart';
import 'support/research_diplomacy_family_pattern_guard.dart';
import 'support/static_member_reference_guard.dart';

const _gameEnginePath =
    'packages/aonw_core/lib/game/application/engine/game_engine.dart';
const _researchHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'research_engine_handler.dart';
const _diplomacyHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'diplomacy_engine_handler.dart';
const _domainResearchResolverPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'domain_research_command_resolver.dart';
const _domainDiplomacyResolverPath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'domain_diplomacy_command_resolver.dart';
const _diplomacyKernelPath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_command_resolver.dart';
const _diplomacyStatePath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_command_state.dart';
const _diplomacyResultPath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_command_result.dart';
const _diplomacySupportPath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_command_support.dart';
const _diplomacyProposalPath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_proposal_command_handler.dart';
const _diplomacyProposalResponsePath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_proposal_response_command_handler.dart';
const _diplomacyWarGiftPath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_war_and_gift_command_handler.dart';
const _diplomacyMessagePath =
    'packages/aonw_core/lib/game/domain/diplomacy/'
    'diplomacy_message_command_handler.dart';
const _researchKernelPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'select_technology_resolver.dart';
const _researchPendingPolicyPath =
    'packages/aonw_core/lib/game/domain/technology/'
    'research_selection_pending_action_policy.dart';
const _diplomacyKernelRoots = {
  _diplomacyKernelPath,
  _diplomacyStatePath,
  _diplomacyResultPath,
  _diplomacySupportPath,
  _diplomacyProposalPath,
  _diplomacyProposalResponsePath,
  _diplomacyWarGiftPath,
  _diplomacyMessagePath,
};

void main() {
  test('research and diplomacy commands have one engine family', () {
    const commands = <DomainCommand>[
      SelectTechnologyCommand('owner', TechnologyId.agriculture),
      SendDiplomaticProposalCommand(
        playerId: 'owner',
        targetPlayerId: 'guest',
        kind: DiplomaticProposalKind.friendship,
      ),
      RespondDiplomaticProposalCommand(
        playerId: 'guest',
        proposalId: 'proposal',
        accepted: true,
      ),
      DeclareWarCommand(playerId: 'owner', targetPlayerId: 'guest'),
      SendGoldGiftCommand(
        playerId: 'owner',
        targetPlayerId: 'guest',
        amount: 10,
      ),
      SendDiplomaticMessageCommand(
        playerId: 'owner',
        targetPlayerId: 'guest',
        topic: DiplomaticMessageTopic.commonEnemy,
      ),
      RespondDiplomaticMessageCommand(
        playerId: 'guest',
        messageId: 'message',
        response: DiplomaticMessageResponse.conciliatory,
      ),
    ];

    expect(
      {
        for (final command in commands)
          command.runtimeType.toString():
              GameEngine.commandFamily(command)?.name ?? 'unhandled',
      },
      const {
        'SelectTechnologyCommand': 'research',
        'SendDiplomaticProposalCommand': 'diplomacy',
        'RespondDiplomaticProposalCommand': 'diplomacy',
        'DeclareWarCommand': 'diplomacy',
        'SendGoldGiftCommand': 'diplomacy',
        'SendDiplomaticMessageCommand': 'diplomacy',
        'RespondDiplomaticMessageCommand': 'diplomacy',
      },
    );
  });

  test('cancel research selection remains a local intent', () {
    const command = CancelResearchSelectionCommand('owner');

    expect(command, isA<GameIntent>());
    expect(
      () => GameCommandSerializer.toJson(command),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('handlers and neutral kernels have one composition point', () {
    final sources = productionDartSources();

    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'ResearchEngineHandler',
        'apply',
      ),
      {_gameEnginePath: 1},
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DiplomacyEngineHandler',
        'apply',
      ),
      {_gameEnginePath: 1},
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DomainResearchCommandResolver',
        'selectTechnology',
      ),
      {_researchHandlerPath: 1},
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DomainDiplomacyCommandResolver',
        'resolve',
      ),
      {_diplomacyHandlerPath: 1},
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'SelectTechnologyResolver',
        'selectTechnology',
      ),
      {_domainResearchResolverPath: 1},
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'DiplomacyCommandResolver',
        'resolve',
      ),
      {_domainDiplomacyResolverPath: 1},
    );
  });

  test('retired research and diplomacy runtimes are absent', () {
    final paths = productionDartSources().keys;
    for (final fragment in const [
      'persistent_research_command_resolver.dart',
      'persistent_diplomacy_resolver.dart',
      'persistent_diplomacy_result.dart',
      'diplomacy_command_router.dart',
      '/research_reducer.dart',
      '/diplomacy_reducer.dart',
      'server_command_reducer_research.dart',
      'server_command_reducer_diplomacy.dart',
    ]) {
      expect(
        paths.where((path) => path.contains(fragment)),
        isEmpty,
        reason: '$fragment is a retired parallel runtime.',
      );
    }
  });

  test('neutral research and diplomacy kernels remain closed', () {
    final sources = productionDartSources();
    final forbiddenTypes = typeNamesBackedBy(
      sources,
      diplomacyKernelForbiddenRootTypes,
    );
    final graph = diplomacyKernelImportGraph(sources, _diplomacyKernelRoots);

    expect(
      diplomacyKernelImportGraphViolations(
        graph,
        expectedPaths: diplomacyKernelImportGraphPaths,
        forbiddenTypes: forbiddenTypes,
      ),
      isEmpty,
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'ResearchOverflowRules',
        'applyToSelectedTechnology',
      ),
      {_researchKernelPath: 1},
    );
    for (final path in [_researchKernelPath, _researchPendingPolicyPath]) {
      expect(
        namedTypeReferencesInSource(
          sources[path]!,
          path: path,
        ).intersection(const {
          'PersistentGameState',
          'DomainState',
          'CanonicalGameSnapshot',
          'GameState',
          'GameRuntimeState',
        }),
        isEmpty,
      );
    }
  });

  test('neutral kernel graph rejects stateful and persistence imports', () {
    const root = '${diplomacyKernelLibraryPath}fixture_command_resolver.dart';
    const helper = '${diplomacyKernelLibraryPath}stealth_persistence.dart';
    final graph = diplomacyKernelImportGraph(
      {
        root: '''
import 'package:aonw_core/game/domain/diplomacy/stealth_persistence.dart';
import 'package:aonw_core/game/domain/state.dart';
''',
        helper: '''
PersistentGameState leak(PersistentGameState state) => state;
''',
      },
      const {root},
    );
    final violations = diplomacyKernelImportGraphViolations(
      graph,
      expectedPaths: const {root},
      forbiddenTypes: const {'PersistentGameState'},
    );

    expect(graph.keys.toSet(), {root, helper});
    expect(
      violations.join('\n'),
      allOf(
        contains('unexpected graph path'),
        contains('PersistentGameState'),
        contains(
          'unapproved dependency package:aonw_core/game/domain/state.dart',
        ),
      ),
    );
  });

  test(
    'local server AI and replay have only reviewed family patterns',
    () async {
      final sources = researchDiplomacyRuntimeSources(productionDartSources());

      expect(
        await researchDiplomacyFamilyPatternSignaturesByPath(sources),
        reviewedResearchDiplomacyFamilyPatternSignatures,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'resolved family ratchet detects duplicate execution paths',
    () async {
      const duplicatePath =
          'lib/game/application/services/duplicate_research_executor.dart';
      final sources = {
        duplicatePath: '''
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';

Object execute(
  CanonicalGameSnapshot snapshot,
  DomainCommand command,
  GameEngineContext context,
) => switch (command) {
  SelectTechnologyCommand() => const ResearchEngineHandler().apply(
      snapshot: snapshot,
      command: command,
      context: context,
    ),
  _ => command,
};
''',
      };

      expect(
        await unreviewedResearchDiplomacyFamilyPatternPaths(sources),
        contains(duplicatePath),
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'resolved family ratchet detects inferred leaf calls and tear-offs',
    () async {
      const proposalPath =
          'lib/game/application/services/duplicate_proposal_leaf.dart';
      const warAliasPath =
          'lib/game/application/services/duplicate_war_leaf.dart';
      const domainTearOffPath =
          'lib/game/application/services/duplicate_domain_diplomacy.dart';
      const overflowAliasPath =
          'lib/game/application/services/duplicate_research_overflow.dart';
      final sources = {
        proposalPath: '''
import 'package:aonw_core/game/domain/diplomacy/diplomacy_proposal_command_handler.dart';

Object bypassProposal(state, command, actor, turn, canAct) =>
    DiplomacyProposalCommandHandler.resolve(
      state: state,
      command: command,
      actorPlayerId: actor,
      turn: turn,
      canAct: canAct,
    );
''',
        warAliasPath: '''
import 'package:aonw_core/game/domain/diplomacy/diplomacy_war_and_gift_command_handler.dart';

typedef WarRules = DiplomacyWarAndGiftCommandHandler;
final bypassWar = WarRules.declareWar;
''',
        domainTearOffPath: '''
import 'package:aonw_core/game/domain/diplomacy/domain_diplomacy_command_resolver.dart';

final bypassDomain = const DomainDiplomacyCommandResolver().resolve;
''',
        overflowAliasPath: '''
import 'package:aonw_core/game/domain/technology/research_overflow_rules.dart';

typedef OverflowRules = ResearchOverflowRules;
final bypassOverflow = OverflowRules.applyToSelectedTechnology;
''',
      };

      expect(
        await unreviewedResearchDiplomacyFamilyPatternPaths(sources),
        containsAll({
          proposalPath,
          warAliasPath,
          domainTearOffPath,
          overflowAliasPath,
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
