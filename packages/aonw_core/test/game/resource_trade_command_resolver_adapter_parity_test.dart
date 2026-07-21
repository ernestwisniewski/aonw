import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _targetPlayerId = 'player_2';

void main() {
  group('resource trade persistent/domain adapter parity', () {
    test('gold trade changes only agreements at both boundaries', () {
      final states = _tradeStates();
      const command = OpenResourceTradeCommand(
        playerId: _playerId,
        targetPlayerId: _targetPlayerId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        durationTurns: 5,
        agreementId: 'gold_trade',
      );

      final results = _resolveGoldBoth(states, command);

      _expectAcceptedParity(states, results);
      expect(
        results.domain.state.resourceTradeAgreements.single.id,
        'gold_trade',
      );
    });

    test('resource exchange preserves requested-then-offered order', () {
      final states = _tradeStates();
      const command = OpenResourceExchangeCommand(
        playerId: _playerId,
        targetPlayerId: _targetPlayerId,
        offeredResource: ResourceType.iron,
        requestedResource: ResourceType.horses,
        durationTurns: 6,
        agreementId: 'exchange',
      );

      final results = _resolveExchangeBoth(states, command);

      _expectAcceptedParity(states, results);
      expect(
        results.domain.state.resourceTradeAgreements.map((trade) => trade.id),
        ['exchange_requested', 'exchange_offered'],
      );
    });

    test('war rejection preserves both complete state identities', () {
      final states = _tradeStates(atWar: true);
      const command = OpenResourceTradeCommand(
        playerId: _playerId,
        targetPlayerId: _targetPlayerId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        durationTurns: 5,
      );

      final results = _resolveGoldBoth(states, command);

      _expectRejectedIdentity(states, results, 'resource_trade_blocked_by_war');
    });

    test('capacity rejection preserves both complete state identities', () {
      final states = _tradeStates(
        agreements: const [
          ResourceTradeAgreement(
            id: 'committed_horses',
            exporterPlayerId: _targetPlayerId,
            importerPlayerId: 'player_3',
            resource: ResourceType.horses,
            goldPerTurn: 1,
            remainingTurns: 2,
          ),
        ],
      );
      const command = OpenResourceTradeCommand(
        playerId: _playerId,
        targetPlayerId: _targetPlayerId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        durationTurns: 5,
      );

      final results = _resolveGoldBoth(states, command);

      _expectRejectedIdentity(
        states,
        results,
        'resource_trade_export_unavailable',
      );
    });

    test('domain adapter forwards the authoritative actor identity', () {
      final states = _tradeStates();
      const command = OpenResourceTradeCommand(
        playerId: _playerId,
        targetPlayerId: _targetPlayerId,
        resource: ResourceType.horses,
        goldPerTurn: 3,
        durationTurns: 5,
      );

      final result = const DomainResourceTradeCommandResolver()
          .openGoldForResourceTrade(
            state: states.domain,
            command: command,
            actorPlayerId: 'player_3',
            mapTiles: _tradeMap(),
          );

      expect(result.accepted, isFalse);
      expect(result.reason, 'resource_trade_player_not_controlled');
      expect(identical(result.state, states.domain), isTrue);
    });
  });
}

typedef _TradeStates = ({PersistentGameState persistent, DomainState domain});

typedef _TradeResults = ({
  ResourceTradeCommandResult kernel,
  PersistentResourceTradeResult persistent,
  DomainResourceTradeCommandResult domain,
});

_TradeStates _tradeStates({
  bool atWar = false,
  List<ResourceTradeAgreement> agreements = const [],
}) {
  final diplomacy = atWar
      ? DiplomacyState.empty.setStatus(
          _playerId,
          _targetPlayerId,
          DiplomaticRelationStatus.war,
        )
      : DiplomacyState.empty.addContact(_playerId, _targetPlayerId);
  final research = ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.ironWorking},
      ),
      _targetPlayerId: PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.animalHusbandry},
      ),
    },
  );
  const cities = [
    GameCity(
      id: 'iron_city',
      ownerPlayerId: _playerId,
      name: 'Iron City',
      center: CityHex(col: 0, row: 0),
    ),
    GameCity(
      id: 'horse_city',
      ownerPlayerId: _targetPlayerId,
      name: 'Horse City',
      center: CityHex(col: 2, row: 0),
    ),
  ];
  final runtimeState = GameRuntimeState.snapshot(
    submittedPlayerIds: const {'sentinel'},
    timeoutStreaksByPlayerId: const {'sentinel': 2},
    diplomacy: diplomacy,
    resourceTradeAgreements: agreements,
    turnStartedAt: DateTime.utc(2026, 7, 20),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _targetPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _targetPlayerId: PlayerCountry.japan,
      },
      playerGold: const {_playerId: 10, _targetPlayerId: 20},
      playerWarWeariness: const {'sentinel': 3},
      playerStabilityNet: const {'sentinel': 4},
      cities: cities,
      research: research,
      runtimeState: runtimeState,
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: _playerId, name: 'One', colorValue: 1),
        Player(
          id: _targetPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.japan,
        ),
      ],
      playerGold: const {_playerId: 10, _targetPlayerId: 20},
      playerWarWeariness: const {'sentinel': 3},
      playerStabilityNet: const {'sentinel': 4},
      cities: cities,
      research: research,
      diplomacy: diplomacy,
      resourceTradeAgreements: agreements,
    ),
  );
}

_TradeResults _resolveGoldBoth(
  _TradeStates states,
  OpenResourceTradeCommand command,
) {
  return (
    kernel: ResourceTradeCommandResolver.openGoldForResourceTrade(
      playerGold: states.domain.playerGold,
      cities: states.domain.cities,
      research: states.domain.research,
      diplomacy: states.domain.diplomacy,
      resourceTradeAgreements: states.domain.resourceTradeAgreements,
      command: command,
      actorPlayerId: command.playerId,
      mapTiles: _tradeMap(),
    ),
    persistent: const PersistentResourceTradeResolver()
        .openGoldForResourceTrade(
          state: states.persistent,
          importerPlayerId: command.playerId,
          exporterPlayerId: command.targetPlayerId,
          resource: command.resource,
          goldPerTurn: command.goldPerTurn,
          durationTurns: command.durationTurns,
          mapTiles: _tradeMap(),
          agreementId: command.agreementId,
        ),
    domain: const DomainResourceTradeCommandResolver().openGoldForResourceTrade(
      state: states.domain,
      command: command,
      actorPlayerId: command.playerId,
      mapTiles: _tradeMap(),
    ),
  );
}

_TradeResults _resolveExchangeBoth(
  _TradeStates states,
  OpenResourceExchangeCommand command,
) {
  return (
    kernel: ResourceTradeCommandResolver.openResourceForResourceTrade(
      cities: states.domain.cities,
      research: states.domain.research,
      diplomacy: states.domain.diplomacy,
      resourceTradeAgreements: states.domain.resourceTradeAgreements,
      command: command,
      actorPlayerId: command.playerId,
      mapTiles: _tradeMap(),
    ),
    persistent: const PersistentResourceTradeResolver()
        .openResourceForResourceTrade(
          state: states.persistent,
          playerId: command.playerId,
          targetPlayerId: command.targetPlayerId,
          offeredResource: command.offeredResource,
          requestedResource: command.requestedResource,
          durationTurns: command.durationTurns,
          mapTiles: _tradeMap(),
          agreementId: command.agreementId,
        ),
    domain: const DomainResourceTradeCommandResolver()
        .openResourceForResourceTrade(
          state: states.domain,
          command: command,
          actorPlayerId: command.playerId,
          mapTiles: _tradeMap(),
        ),
  );
}

void _expectAcceptedParity(_TradeStates before, _TradeResults results) {
  expect(results.kernel.accepted, isTrue);
  expect(results.persistent.accepted, isTrue);
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.persistent.reason, isNull);
  expect(results.domain.reason, isNull);
  final persistentAgreements =
      results.persistent.state.runtimeState.resourceTradeAgreements;
  expect(results.kernel.resourceTradeAgreements, persistentAgreements);
  expect(persistentAgreements, results.domain.state.resourceTradeAgreements);
  expect(
    results.persistent.state,
    before.persistent.copyWith(
      runtimeState: before.persistent.runtimeState.copyWith(
        resourceTradeAgreements: persistentAgreements,
      ),
    ),
  );
  expect(
    results.domain.state,
    before.domain.copyWith(resourceTradeAgreements: persistentAgreements),
  );
  expect(
    identical(
      results.persistent.state.playerGold,
      before.persistent.playerGold,
    ),
    isTrue,
  );
  expect(
    identical(results.domain.state.playerGold, before.domain.playerGold),
    isTrue,
  );
}

void _expectRejectedIdentity(
  _TradeStates before,
  _TradeResults results,
  String reason,
) {
  expect(results.kernel.accepted, isFalse);
  expect(results.persistent.accepted, isFalse);
  expect(results.domain.accepted, isFalse);
  expect(results.kernel.reason, reason);
  expect(results.persistent.reason, reason);
  expect(results.domain.reason, reason);
  expect(identical(results.persistent.state, before.persistent), isTrue);
  expect(identical(results.domain.state, before.domain), isTrue);
  expect(
    identical(
      results.kernel.resourceTradeAgreements,
      before.domain.resourceTradeAgreements,
    ),
    isTrue,
  );
}

MapTileLookup _tradeMap() {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: 0),
            terrains: const [TerrainType.plains],
            resources: switch (col) {
              0 => const [ResourceType.iron],
              2 => const [ResourceType.horses],
              _ => const [],
            },
            height: 0,
          ),
      ],
    ),
  );
}
