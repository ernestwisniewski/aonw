part of '../diplomacy_command_router_characterization_test.dart';

void _registerActorGuardCharacterizationTests() {
  group('common actor guard', () {
    final commands = <DiplomaticCommand>[
      const SendDiplomaticProposalCommand(
        playerId: '',
        targetPlayerId: _player2,
        kind: DiplomaticProposalKind.friendship,
      ),
      const RespondDiplomaticProposalCommand(
        playerId: '',
        proposalId: 'missing',
        accepted: true,
      ),
      const DeclareWarCommand(playerId: '', targetPlayerId: _player2),
      const SendGoldGiftCommand(
        playerId: '',
        targetPlayerId: _player2,
        amount: 5,
      ),
      const SendDiplomaticMessageCommand(
        playerId: '',
        targetPlayerId: _player2,
        topic: DiplomaticMessageTopic.peacefulPraise,
      ),
      const RespondDiplomaticMessageCommand(
        playerId: '',
        messageId: 'missing',
        response: DiplomaticMessageResponse.neutral,
      ),
    ];

    for (final command in commands) {
      test('${command.runtimeType} rejects an empty command player', () {
        final state = _diplomacyState();
        final result = _route(state, command, actorPlayerId: '');

        _expectRejectedDiplomacy(
          result,
          state,
          'diplomacy_player_not_controlled',
        );
      });
    }

    test('matching actor need not otherwise exist in persistent state', () {
      const ghost = 'ghost';
      final state = _diplomacyState(
        diplomacy: DiplomacyState.empty.addContact(ghost, _player2),
      );
      expect(state.knownPlayerIds, isNot(contains(ghost)));

      final result = _route(
        state,
        const SendDiplomaticProposalCommand(
          playerId: ghost,
          targetPlayerId: _player2,
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'ghost_proposal',
        ),
        actorPlayerId: ghost,
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.diplomacy.pendingProposals,
        contains('ghost_proposal'),
      );
    });
  });
}
