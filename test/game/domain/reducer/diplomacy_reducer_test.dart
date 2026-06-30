import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiplomacyReducer via GameStateReducer', () {
    test('sends a diplomatic message and enforces category cooldown', () {
      final reducer = GameStateReducer(mapData: _map());
      final state = _state();
      const command = SendDiplomaticMessageCommand(
        playerId: 'p1',
        targetPlayerId: 'p2',
        topic: DiplomaticMessageTopic.blockedRoutes,
        messageId: 'message_1',
      );

      final sent = reducer.reduce(
        state,
        command,
        context: const GameCommandContext(combatSeedTurn: 7),
      );
      final cooledDown = reducer.reduce(
        sent.state,
        const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.withdrawScouts,
          messageId: 'message_2',
        ),
        context: const GameCommandContext(combatSeedTurn: 10),
      );
      final afterCooldown = reducer.reduce(
        sent.state,
        const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.withdrawScouts,
          messageId: 'message_3',
        ),
        context: const GameCommandContext(combatSeedTurn: 12),
      );

      expect(sent.events.single, isA<DiplomaticMessageSentEvent>());
      expect(sent.state.diplomacy.messages, contains('message_1'));
      expect(cooledDown.state.diplomacy.messages, isNot(contains('message_2')));
      expect(cooledDown.events, isEmpty);
      expect(afterCooldown.state.diplomacy.messages, contains('message_3'));
    });

    test('blocks initial diplomacy before discovering the civilization', () {
      final reducer = GameStateReducer(mapData: _map());
      final state = _state(contacted: false);

      final message = reducer.reduce(
        state,
        const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.blockedRoutes,
          messageId: 'message_1',
        ),
      );
      final war = reducer.reduce(
        state,
        const DeclareWarCommand(playerId: 'p1', targetPlayerId: 'p2'),
      );
      final gift = reducer.reduce(
        state.copyWith(playerGold: const {'p1': 5}),
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 5,
        ),
      );

      expect(message.events, isEmpty);
      expect(message.state.diplomacy.messages, isEmpty);
      expect(war.events, isEmpty);
      expect(gift.events, isEmpty);
      expect(
        war.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.neutral,
      );
      expect(gift.state.playerGold, {'p1': 5});
    });

    test('gold gift transfers available gold and improves relations', () {
      final reducer = GameStateReducer(mapData: _map());
      final result = reducer.reduce(
        _state().copyWith(playerGold: const {'p1': 10, 'p2': 1}),
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 10,
        ),
        context: const GameCommandContext(combatSeedTurn: 6),
      );
      final scoreEvent = result.events
          .whereType<DiplomaticScoreChangedEvent>()
          .single;

      expect(result.state.playerGold, {'p1': 0, 'p2': 11});
      expect(result.state.diplomacy.relationScoreBetween('p1', 'p2'), 2);
      expect(
        result.state.diplomacy.scoreEntriesBetween('p1', 'p2').single.reason,
        DiplomaticScoreChangeReason.goldGift,
      );
      expect(scoreEvent.delta, 2);
      expect(scoreEvent.reason, DiplomaticScoreChangeReason.goldGift);
      expect(scoreEvent.sourceId, 'gold_gift.6.p1.p2');
    });

    test('gold gift below minimum does not farm relations', () {
      final reducer = GameStateReducer(mapData: _map());
      final state = _state().copyWith(playerGold: const {'p1': 4, 'p2': 1});

      final result = reducer.reduce(
        state,
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 4,
        ),
      );

      expect(result.events, isEmpty);
      expect(result.state.playerGold, state.playerGold);
      expect(result.state.diplomacy.relationScoreBetween('p1', 'p2'), 0);
    });

    test('gold gift respects relation cooldown', () {
      final reducer = GameStateReducer(mapData: _map());
      final first = reducer.reduce(
        _state().copyWith(playerGold: const {'p1': 20, 'p2': 1}),
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 10,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p1',
          combatSeedTurn: 6,
        ),
      );

      final repeated = reducer.reduce(
        first.state,
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 10,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p1',
          combatSeedTurn: 8,
        ),
      );

      expect(repeated.events, isEmpty);
      expect(repeated.state.playerGold, first.state.playerGold);
      expect(repeated.state.diplomacy.relationScoreBetween('p1', 'p2'), 2);
    });

    test('gold gift is blocked during war and truce', () {
      final reducer = GameStateReducer(mapData: _map());
      final war = _state().copyWith(
        playerGold: const {'p1': 7, 'p2': 1},
        diplomacy: DiplomacyState.empty
            .addContact('p1', 'p2')
            .setStatus('p1', 'p2', DiplomaticRelationStatus.war),
      );
      final truce = war.copyWith(
        diplomacy: war.diplomacy.setStatus(
          'p1',
          'p2',
          DiplomaticRelationStatus.truce,
        ),
      );

      final warResult = reducer.reduce(
        war,
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 5,
        ),
      );
      final truceResult = reducer.reduce(
        truce,
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 5,
        ),
      );

      expect(warResult.events, isEmpty);
      expect(warResult.state.playerGold, war.playerGold);
      expect(truceResult.events, isEmpty);
      expect(truceResult.state.playerGold, truce.playerGold);
    });

    test('allows initial diplomacy after visible contact', () {
      final reducer = GameStateReducer(mapData: _map());
      final state = _state(
        contacted: false,
        fogOfWar: FogOfWarState(
          players: {
            'p1': PlayerFogOfWar(
              playerId: 'p1',
              visibleHexes: {const HexCoordinate(col: 1, row: 1)},
            ),
          },
        ),
        units: [GameUnit.startingWarrior(ownerPlayerId: 'p2', col: 1, row: 1)],
      );

      final result = reducer.reduce(
        state,
        const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.blockedRoutes,
          messageId: 'message_1',
        ),
      );

      expect(result.events.single, isA<DiplomaticMessageSentEvent>());
      expect(result.state.diplomacy.messages, contains('message_1'));
    });

    test('conciliatory response improves relation and creates a promise', () {
      final reducer = GameStateReducer(mapData: _map());
      final withMessage = _state().copyWith(
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

      final result = reducer.reduce(
        withMessage,
        const RespondDiplomaticMessageCommand(
          playerId: 'p2',
          messageId: 'message_1',
          response: DiplomaticMessageResponse.conciliatory,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p2',
          combatSeedTurn: 5,
        ),
      );
      final message = result.state.diplomacy.messages['message_1'];

      expect(
        result.state.diplomacy.relationScoreBetween('p1', 'p2'),
        DiplomaticMessageResponse.conciliatory.relationScoreDelta,
      );
      expect(message?.response, DiplomaticMessageResponse.conciliatory);
      expect(message?.promiseDueTurn, 8);
      expect(
        result.events.whereType<DiplomaticScoreChangedEvent>(),
        hasLength(1),
      );
    });

    test('common enemy response rewards shared war cooperation', () {
      final reducer = GameStateReducer(mapData: _map());
      final withMessage = _state().copyWith(
        playerColors: const {'p1': 1, 'p2': 2, 'p3': 3},
        diplomacy: DiplomacyState.empty
            .addContact('p1', 'p2')
            .addContact('p1', 'p3')
            .addContact('p2', 'p3')
            .setStatus('p1', 'p3', DiplomaticRelationStatus.war)
            .setStatus('p2', 'p3', DiplomaticRelationStatus.war)
            .addMessage(
              DiplomaticMessage.create(
                id: 'message_1',
                fromPlayerId: 'p1',
                toPlayerId: 'p2',
                topic: DiplomaticMessageTopic.commonEnemy,
                createdTurn: 4,
                expiresOnTurn: 9,
              ),
            ),
      );

      final result = reducer.reduce(
        withMessage,
        const RespondDiplomaticMessageCommand(
          playerId: 'p2',
          messageId: 'message_1',
          response: DiplomaticMessageResponse.conciliatory,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p2',
          combatSeedTurn: 5,
        ),
      );
      final message = result.state.diplomacy.messages['message_1'];
      final scoreEvent = result.events
          .whereType<DiplomaticScoreChangedEvent>()
          .single;

      expect(result.state.diplomacy.relationScoreBetween('p1', 'p2'), 20);
      expect(message?.relationScoreDelta, 20);
      expect(
        result.state.diplomacy.scoreEntriesBetween('p1', 'p2').single.reason,
        DiplomaticScoreChangeReason.commonEnemyCooperation,
      );
      expect(
        scoreEvent.reason,
        DiplomaticScoreChangeReason.commonEnemyCooperation,
      );
    });

    test('accepted truce updates status and expiry', () {
      final reducer = GameStateReducer(mapData: _map());
      final withProposal = _state().copyWith(
        diplomacy: DiplomacyState.empty
            .setStatus('p1', 'p2', DiplomaticRelationStatus.war)
            .addProposal(
              const DiplomaticProposal(
                id: 'proposal_1',
                fromPlayerId: 'p1',
                toPlayerId: 'p2',
                kind: DiplomaticProposalKind.truce,
                createdTurn: 4,
                expiresOnTurn: 9,
              ),
            ),
      );

      final result = reducer.reduce(
        withProposal,
        const RespondDiplomaticProposalCommand(
          playerId: 'p2',
          proposalId: 'proposal_1',
          accepted: true,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p2',
          combatSeedTurn: 5,
        ),
      );

      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.truce,
      );
      expect(
        result.state.diplomacy.relationBetween('p1', 'p2').statusExpiresOnTurn,
        15,
      );
      expect(
        result.events
            .whereType<DiplomaticRelationChangedEvent>()
            .single
            .newStatus,
        DiplomaticRelationStatus.truce,
      );
    });

    test('accepted truce transfers offered gold payment', () {
      final reducer = GameStateReducer(mapData: _map());
      final sent = reducer.reduce(
        _state().copyWith(
          playerGold: const {'p1': 20, 'p2': 3},
          diplomacy: DiplomacyState.empty.setStatus(
            'p1',
            'p2',
            DiplomaticRelationStatus.war,
          ),
        ),
        const SendDiplomaticProposalCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          kind: DiplomaticProposalKind.truce,
          proposalId: 'proposal_1',
          goldPayment: 7,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p1',
          combatSeedTurn: 4,
        ),
      );
      final proposal = sent.state.diplomacy.pendingProposals['proposal_1'];

      final result = reducer.reduce(
        sent.state,
        const RespondDiplomaticProposalCommand(
          playerId: 'p2',
          proposalId: 'proposal_1',
          accepted: true,
        ),
        context: const GameCommandContext(
          actorPlayerId: 'p2',
          combatSeedTurn: 5,
        ),
      );

      expect(proposal?.goldPayment, 7);
      expect(result.state.playerGold['p1'], 13);
      expect(result.state.playerGold['p2'], 10);
      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.truce,
      );
    });

    test(
      'paid truce acceptance requires promised gold to remain available',
      () {
        final reducer = GameStateReducer(mapData: _map());
        final state = _state().copyWith(
          playerGold: const {'p1': 4, 'p2': 3},
          diplomacy: DiplomacyState.empty
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

        final result = reducer.reduce(
          state,
          const RespondDiplomaticProposalCommand(
            playerId: 'p2',
            proposalId: 'proposal_1',
            accepted: true,
          ),
          context: const GameCommandContext(
            actorPlayerId: 'p2',
            combatSeedTurn: 5,
          ),
        );

        expect(result.events, isEmpty);
        expect(result.state.playerGold, state.playerGold);
        expect(
          result.state.diplomacy.statusBetween('p1', 'p2'),
          DiplomaticRelationStatus.war,
        );
        expect(result.state.diplomacy.pendingProposals, contains('proposal_1'));
      },
    );

    test('declaration of war breaks trade and hurts shared contacts', () {
      final reducer = GameStateReducer(mapData: _map());
      final state = _state().copyWith(
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

      final result = reducer.reduce(
        state,
        const DeclareWarCommand(playerId: 'p1', targetPlayerId: 'p2'),
        context: const GameCommandContext(combatSeedTurn: 9),
      );

      expect(
        result.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.war,
      );
      expect(result.state.resourceTradeAgreements.map((trade) => trade.id), [
        'observer_trade',
      ]);
      expect(
        result.state.diplomacy.relationScoreBetween('p1', 'p3'),
        DiplomaticWarmongerReputation.declarationOfWarPenalty,
      );
      expect(
        result.events.whereType<DiplomaticScoreChangedEvent>().map(
          (event) => event.reason,
        ),
        contains(DiplomaticScoreChangeReason.warmongerPenalty),
      );
    });

    test('matches persistent diplomacy router for local commands', () {
      _expectDiplomacyParity(
        _state(),
        const SendDiplomaticProposalCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'proposal_1',
        ),
        actorPlayerId: 'p1',
        turn: 4,
      );

      _expectDiplomacyParity(
        _state().copyWith(playerGold: const {'p1': 20, 'p2': 1}),
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 10,
        ),
        actorPlayerId: 'p1',
        turn: 6,
      );

      _expectDiplomacyParity(
        _state().copyWith(
          playerGold: const {'p1': 20, 'p2': 3},
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
        ),
        const RespondDiplomaticProposalCommand(
          playerId: 'p2',
          proposalId: 'proposal_1',
          accepted: true,
        ),
        actorPlayerId: 'p2',
        turn: 5,
      );

      _expectDiplomacyParity(
        _state(),
        const SendDiplomaticMessageCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          topic: DiplomaticMessageTopic.peacefulPraise,
          messageId: 'message_1',
        ),
        actorPlayerId: 'p1',
        turn: 6,
      );

      _expectDiplomacyParity(
        _state().copyWith(
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
        ),
        const RespondDiplomaticMessageCommand(
          playerId: 'p2',
          messageId: 'message_1',
          response: DiplomaticMessageResponse.conciliatory,
        ),
        actorPlayerId: 'p2',
        turn: 5,
      );

      _expectDiplomacyParity(
        _state().copyWith(
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
          ],
        ),
        const DeclareWarCommand(playerId: 'p1', targetPlayerId: 'p2'),
        actorPlayerId: 'p1',
        turn: 9,
      );
    });

    test('opens resource trade from controlled exporter resource', () {
      final reducer = GameStateReducer(mapData: _resourceMap());
      final state = _state().copyWith(
        playerGold: const {'p1': 10, 'p2': 0},
        cities: const [
          GameCity(
            id: 'city_p2',
            ownerPlayerId: 'p2',
            name: 'Exporter',
            center: CityHex(col: 1, row: 1),
          ),
        ],
        research: ResearchState(
          players: {
            'p2': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.animalHusbandry},
            ),
          },
        ),
      );

      final result = reducer.reduce(
        state,
        const OpenResourceTradeCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          durationTurns: 5,
          agreementId: 'trade_1',
        ),
      );

      expect(result.state.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'p2',
          importerPlayerId: 'p1',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          remainingTurns: 5,
        ),
      ]);
      expect(result.state.runtimeState.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'trade_1',
          exporterPlayerId: 'p2',
          importerPlayerId: 'p1',
          resource: ResourceType.horses,
          goldPerTurn: 3,
          remainingTurns: 5,
        ),
      ]);
    });

    test('opens resource exchange from two controlled resources', () {
      final reducer = GameStateReducer(mapData: _exchangeResourceMap());
      final state = _state().copyWith(
        cities: const [
          GameCity(
            id: 'city_p1',
            ownerPlayerId: 'p1',
            name: 'Iron City',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'city_p2',
            ownerPlayerId: 'p2',
            name: 'Horse City',
            center: CityHex(col: 2, row: 2),
          ),
        ],
        research: ResearchState(
          players: {
            'p1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.ironWorking},
            ),
            'p2': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.animalHusbandry},
            ),
          },
        ),
      );

      final result = reducer.reduce(
        state,
        const OpenResourceExchangeCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          offeredResource: ResourceType.iron,
          requestedResource: ResourceType.horses,
          durationTurns: 5,
          agreementId: 'exchange_1',
        ),
      );

      expect(result.state.resourceTradeAgreements, [
        const ResourceTradeAgreement(
          id: 'exchange_1_requested',
          exporterPlayerId: 'p2',
          importerPlayerId: 'p1',
          resource: ResourceType.horses,
          goldPerTurn: 0,
          remainingTurns: 5,
        ),
        const ResourceTradeAgreement(
          id: 'exchange_1_offered',
          exporterPlayerId: 'p1',
          importerPlayerId: 'p2',
          resource: ResourceType.iron,
          goldPerTurn: 0,
          remainingTurns: 5,
        ),
      ]);
      expect(
        result.state.runtimeState.resourceTradeAgreements,
        result.state.resourceTradeAgreements,
      );
    });
  });
}

void _expectDiplomacyParity(
  GameState state,
  DiplomaticCommand command, {
  required String actorPlayerId,
  required int turn,
}) {
  final client = GameStateReducer(mapData: _map()).reduce(
    state,
    command,
    context: GameCommandContext(
      actorPlayerId: actorPlayerId,
      combatSeedTurn: turn,
    ),
  );
  final server = const DiplomacyCommandRouter().route(
    state: _persistentState(state),
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
  );

  expect(server.state.runtimeState.diplomacy, client.state.diplomacy);
  expect(server.state.playerGold, client.state.playerGold);
  expect(
    server.state.runtimeState.intendedAttacks,
    client.state.intendedAttacks,
  );
  expect(
    server.state.runtimeState.resourceTradeAgreements,
    client.state.resourceTradeAgreements,
  );
  expect(_eventJson(server.events), _eventJson(client.events));
}

PersistentGameState _persistentState(GameState state) {
  return PersistentGameState(
    playerColors: state.playerColors,
    playerCountries: state.playerCountries,
    playerGold: state.playerGold,
    units: state.units,
    cities: state.cities,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    fogOfWar: state.fogOfWar,
    research: state.research,
    runtimeState: state.runtimeState,
  );
}

List<Map<String, dynamic>> _eventJson(List<GameEvent> events) {
  return [for (final event in events) GameEventSerializer.toJson(event)];
}

GameState _state({
  bool contacted = true,
  FogOfWarState fogOfWar = FogOfWarState.empty,
  List<GameUnit> units = const [],
}) {
  return GameState(
    activePlayerId: 'p1',
    playerColors: const {'p1': 1, 'p2': 2},
    units: units,
    fogOfWar: fogOfWar,
    diplomacy: contacted
        ? DiplomacyState.empty.addContact('p1', 'p2')
        : DiplomacyState.empty,
  );
}

MapData _map() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (var col = 0; col < 2; col++)
      for (var row = 0; row < 2; row++)
        TileData(
          col: col,
          row: row,
          height: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
        ),
  ],
);

MapData _resourceMap() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (var col = 0; col < 2; col++)
      for (var row = 0; row < 2; row++)
        TileData(
          col: col,
          row: row,
          height: 0,
          terrains: const [TerrainType.grassland],
          resources: col == 1 && row == 1
              ? const [ResourceType.horses]
              : const [],
        ),
  ],
);

MapData _exchangeResourceMap() => MapData(
  cols: 3,
  rows: 3,
  tiles: [
    for (var col = 0; col < 3; col++)
      for (var row = 0; row < 3; row++)
        TileData(
          col: col,
          row: row,
          height: 0,
          terrains: const [TerrainType.grassland],
          resources: switch ((col, row)) {
            (0, 0) => const [ResourceType.iron],
            (2, 2) => const [ResourceType.horses],
            _ => const [],
          },
        ),
  ],
);
