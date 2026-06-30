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

      expect(message.events, isEmpty);
      expect(message.state.diplomacy.messages, isEmpty);
      expect(war.events, isEmpty);
      expect(
        war.state.diplomacy.statusBetween('p1', 'p2'),
        DiplomaticRelationStatus.neutral,
      );
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
