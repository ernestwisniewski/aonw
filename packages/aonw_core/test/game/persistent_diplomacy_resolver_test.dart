import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentDiplomacyResolver', () {
    const resolver = PersistentDiplomacyResolver();

    test('sends a diplomatic proposal', () {
      final result = resolver.sendProposal(
        state: _state(),
        command: const SendDiplomaticProposalCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'proposal_1',
        ),
        actorPlayerId: 'p1',
        turn: 4,
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.runtimeState.diplomacy.pendingProposals,
        contains('proposal_1'),
      );
      expect(result.events.single, isA<DiplomaticProposalSentEvent>());
    });

    test('rejects proposals before contact is discovered', () {
      final result = resolver.sendProposal(
        state: _state(contacted: false),
        command: const SendDiplomaticProposalCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          kind: DiplomaticProposalKind.friendship,
        ),
        actorPlayerId: 'p1',
        turn: 4,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'diplomacy_target_not_discovered');
    });

    test(
      'accepts truce proposals with payment and clears intended attacks',
      () {
        final state = _state(
          playerGold: const {'p1': 20, 'p2': 3},
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'p1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'p2',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
          diplomacy: DiplomacyState.empty
              .addContact('p1', 'p2')
              .setStatus('p1', 'p2', DiplomaticRelationStatus.war)
              .addProposal(
                const DiplomaticProposal(
                  id: 'proposal_1',
                  fromPlayerId: 'p1',
                  toPlayerId: 'p2',
                  kind: DiplomaticProposalKind.truce,
                  createdTurn: 4,
                  expiresOnTurn: 9,
                  goldPayment: 7,
                ),
              ),
          intendedAttacks: const [
            IntendedAttack(
              attackerUnitId: 'warrior_1',
              defenderCol: 1,
              defenderRow: 1,
              declaredAtTick: 2,
              declaringPlayerId: 'p1',
            ),
          ],
        );

        final result = resolver.respondProposal(
          state: state,
          command: const RespondDiplomaticProposalCommand(
            playerId: 'p2',
            proposalId: 'proposal_1',
            accepted: true,
          ),
          actorPlayerId: 'p2',
          turn: 5,
        );

        expect(result.accepted, isTrue);
        expect(result.state.playerGold, {'p1': 13, 'p2': 10});
        expect(result.state.runtimeState.intendedAttacks, isEmpty);
        expect(
          result.state.runtimeState.diplomacy.statusBetween('p1', 'p2'),
          DiplomaticRelationStatus.truce,
        );
        expect(
          result.events
              .whereType<DiplomaticRelationChangedEvent>()
              .single
              .newStatus,
          DiplomaticRelationStatus.truce,
        );
      },
    );

    test('rejects accepted proposals when payment is no longer funded', () {
      final state = _state(
        playerGold: const {'p1': 4, 'p2': 3},
        diplomacy: DiplomacyState.empty
            .addContact('p1', 'p2')
            .setStatus('p1', 'p2', DiplomaticRelationStatus.war)
            .addProposal(
              const DiplomaticProposal(
                id: 'proposal_1',
                fromPlayerId: 'p1',
                toPlayerId: 'p2',
                kind: DiplomaticProposalKind.truce,
                createdTurn: 4,
                expiresOnTurn: 9,
                goldPayment: 7,
              ),
            ),
      );

      final result = resolver.respondProposal(
        state: state,
        command: const RespondDiplomaticProposalCommand(
          playerId: 'p2',
          proposalId: 'proposal_1',
          accepted: true,
        ),
        actorPlayerId: 'p2',
        turn: 5,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'diplomacy_proposal_payment_unavailable');
      expect(result.state, state);
    });

    test('declares war, removes pair trade, and emits warmonger events', () {
      final state = _state(
        playerColors: const {'p1': 1, 'p2': 2, 'p3': 3},
        diplomacy: DiplomacyState.empty
            .addContact('p1', 'p2')
            .addContact('p1', 'p3')
            .addContact('p2', 'p3'),
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'war_trade',
            exporterPlayerId: 'p2',
            importerPlayerId: 'p1',
            resource: ResourceType.horses,
            goldPerTurn: 3,
            remainingTurns: 5,
          ),
          ResourceTradeAgreement(
            id: 'observer_trade',
            exporterPlayerId: 'p3',
            importerPlayerId: 'p1',
            resource: ResourceType.iron,
            goldPerTurn: 1,
            remainingTurns: 5,
          ),
        ],
      );

      final result = resolver.declareWar(
        state: state,
        command: const DeclareWarCommand(playerId: 'p1', targetPlayerId: 'p2'),
        actorPlayerId: 'p1',
        turn: 9,
      );

      expect(result.accepted, isTrue);
      expect(
        result.state.runtimeState.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.war,
      );
      expect(
        result.state.runtimeState.resourceTradeAgreements.map(
          (trade) => trade.id,
        ),
        ['observer_trade'],
      );
      expect(
        result.events.whereType<DiplomaticScoreChangedEvent>().map(
          (event) => event.reason,
        ),
        contains(DiplomaticScoreChangeReason.warmongerPenalty),
      );
    });

    test('rejects war declarations during an active truce', () {
      final state = _state(
        diplomacy: DiplomacyState.empty
            .addContact('p1', 'p2')
            .setStatus(
              'p1',
              'p2',
              DiplomaticRelationStatus.truce,
              statusExpiresOnTurn: 15,
            ),
      );

      final result = resolver.declareWar(
        state: state,
        command: const DeclareWarCommand(playerId: 'p1', targetPlayerId: 'p2'),
        actorPlayerId: 'p1',
        turn: 9,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'diplomacy_truce_active');
      expect(result.state, state);
    });

    test('sends a funded gold gift and rejects actor spoofing', () {
      final accepted = resolver.sendGoldGift(
        state: _state(playerGold: const {'p1': 10, 'p2': 1}),
        command: const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 10,
        ),
        actorPlayerId: 'p1',
        turn: 6,
      );
      final spoofed = resolver.sendGoldGift(
        state: _state(playerGold: const {'p1': 10, 'p2': 1}),
        command: const SendGoldGiftCommand(
          playerId: 'p2',
          targetPlayerId: 'p1',
          amount: 5,
        ),
        actorPlayerId: 'p1',
        turn: 6,
      );

      expect(accepted.accepted, isTrue);
      expect(accepted.state.playerGold, {'p1': 0, 'p2': 11});
      expect(
        accepted.state.runtimeState.diplomacy.relationScoreBetween('p1', 'p2'),
        2,
      );
      expect(spoofed.accepted, isFalse);
      expect(spoofed.reason, 'diplomacy_player_not_controlled');
    });

    test('rejects unfunded gold gifts', () {
      final result = resolver.sendGoldGift(
        state: _state(playerGold: const {'p1': 4, 'p2': 1}),
        command: const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 5,
        ),
        actorPlayerId: 'p1',
        turn: 6,
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'diplomacy_gold_unavailable');
    });

    test('sends diplomatic messages and enforces category cooldown', () {
      final sent = resolver.sendMessage(
        state: _state(),
        command: const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.blockedRoutes,
          messageId: 'message_1',
        ),
        actorPlayerId: 'p1',
        turn: 7,
      );
      final cooledDown = resolver.sendMessage(
        state: sent.state,
        command: const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.withdrawScouts,
          messageId: 'message_2',
        ),
        actorPlayerId: 'p1',
        turn: 10,
      );

      expect(sent.accepted, isTrue);
      expect(sent.events.single, isA<DiplomaticMessageSentEvent>());
      expect(cooledDown.accepted, isFalse);
      expect(cooledDown.reason, 'diplomacy_message_cooldown');
    });

    test('responds to diplomatic messages with relation delta and promise', () {
      final state = _state(
        diplomacy: DiplomacyState.empty.addMessage(
          DiplomaticMessage.create(
            id: 'message_1',
            fromPlayerId: 'p1',
            toPlayerId: 'p2',
            topic: DiplomaticMessageTopic.troopsNearCities,
            createdTurn: 4,
            expiresOnTurn: 9,
          ),
        ),
      );

      final result = resolver.respondMessage(
        state: state,
        command: const RespondDiplomaticMessageCommand(
          playerId: 'p2',
          messageId: 'message_1',
          response: DiplomaticMessageResponse.conciliatory,
        ),
        actorPlayerId: 'p2',
        turn: 5,
      );
      final message = result.state.runtimeState.diplomacy.messages['message_1'];

      expect(result.accepted, isTrue);
      expect(message?.response, DiplomaticMessageResponse.conciliatory);
      expect(message?.promiseDueTurn, 8);
      expect(
        result.events.whereType<DiplomaticScoreChangedEvent>(),
        hasLength(1),
      );
    });

    test('rejects unavailable diplomatic message responses', () {
      final missing = resolver.respondMessage(
        state: _state(),
        command: const RespondDiplomaticMessageCommand(
          playerId: 'p2',
          messageId: 'missing',
          response: DiplomaticMessageResponse.neutral,
        ),
        actorPlayerId: 'p2',
        turn: 5,
      );
      final expiredState = _state(
        diplomacy: DiplomacyState.empty.addMessage(
          DiplomaticMessage.create(
            id: 'message_1',
            fromPlayerId: 'p1',
            toPlayerId: 'p2',
            topic: DiplomaticMessageTopic.troopsNearCities,
            createdTurn: 1,
            expiresOnTurn: 4,
          ),
        ),
      );
      final expired = resolver.respondMessage(
        state: expiredState,
        command: const RespondDiplomaticMessageCommand(
          playerId: 'p2',
          messageId: 'message_1',
          response: DiplomaticMessageResponse.neutral,
        ),
        actorPlayerId: 'p2',
        turn: 5,
      );

      expect(missing.accepted, isFalse);
      expect(missing.reason, 'diplomacy_message_not_found');
      expect(expired.accepted, isFalse);
      expect(expired.reason, 'diplomacy_message_unavailable');
      expect(expired.state, expiredState);
    });
  });
}

PersistentGameState _state({
  bool contacted = true,
  Map<String, int> playerColors = const {'p1': 1, 'p2': 2},
  Map<String, int> playerGold = const {},
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  DiplomacyState? diplomacy,
  List<IntendedAttack> intendedAttacks = const [],
  List<ResourceTradeAgreement> resourceTradeAgreements = const [],
}) {
  final baseDiplomacy =
      diplomacy ??
      (contacted
          ? DiplomacyState.empty.addContact('p1', 'p2')
          : DiplomacyState.empty);
  return PersistentGameState(
    playerColors: playerColors,
    playerGold: playerGold,
    units: units,
    cities: cities,
    runtimeState: GameRuntimeState(
      intendedAttacks: intendedAttacks,
      diplomacy: baseDiplomacy,
      resourceTradeAgreements: resourceTradeAgreements,
    ),
  );
}
