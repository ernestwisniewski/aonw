import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('artifact persistent/domain adapter parity', () {
    test('start excavation has exact parity and unit branch isolation', () {
      final unit = _unit(id: 'scout_1', col: 2, row: 3);
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.astronomersTablets,
        location: WorldArtifactLocation.map(col: 2, row: 3),
      );
      final states = _states(units: [unit], artifacts: const [artifact]);
      const command = StartArtifactExcavationCommand('scout_1');

      final persistentResult = const PersistentArtifactCommandResolver()
          .startExcavation(
            state: states.persistent,
            command: command,
            actorPlayerId: _playerId,
          );
      final domainResult = const DomainArtifactCommandResolver()
          .startExcavation(
            state: states.domain,
            command: command,
            actorPlayerId: _playerId,
          );

      _expectParity(persistentResult, domainResult, accepted: true);
      _expectUnitBranchIsolation(
        states.persistent,
        persistentResult.state,
        states.domain,
        domainResult.state,
      );
      expect(
        persistentResult.state.units.single.excavatingArtifactId,
        artifact.id,
      );
      expect(
        persistentResult.state.artifacts.single.location,
        const WorldArtifactLocation.excavation(
          unitId: 'scout_1',
          col: 2,
          row: 3,
          remainingTurns: ArtifactCommandResolver.excavationTurns,
        ),
      );
    });

    test('start excavation reject preserves both state identities', () {
      final states = _states(
        units: [_unit(id: 'scout_1', col: 2, row: 3)],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.map(col: 2, row: 3),
          ),
        ],
      );

      final persistentResult = const PersistentArtifactCommandResolver()
          .startExcavation(
            state: states.persistent,
            command: const StartArtifactExcavationCommand('scout_1'),
            actorPlayerId: _otherPlayerId,
          );
      final domainResult = const DomainArtifactCommandResolver()
          .startExcavation(
            state: states.domain,
            command: const StartArtifactExcavationCommand('scout_1'),
            actorPlayerId: _otherPlayerId,
          );

      _expectRejectedIdentity(
        states.persistent,
        persistentResult,
        states.domain,
        domainResult,
        reason: 'unit_not_controlled',
      );
    });

    test('store in city has exact parity and unit branch isolation', () {
      final unit = _unit(
        id: 'carrier_1',
        col: 1,
        row: 1,
        carriedArtifactId: 'artifact_1',
      );
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.carried(unitId: 'carrier_1'),
      );
      final states = _states(
        units: [unit],
        cities: const [_playerCity, _otherPlayerCity],
        artifacts: const [artifact],
      );
      const command = StoreArtifactInCityCommand('carrier_1', cityId: 'city_1');

      final persistentResult = const PersistentArtifactCommandResolver()
          .storeInCity(
            state: states.persistent,
            command: command,
            actorPlayerId: _playerId,
          );
      final domainResult = const DomainArtifactCommandResolver().storeInCity(
        state: states.domain,
        command: command,
        actorPlayerId: _playerId,
      );

      _expectParity(persistentResult, domainResult, accepted: true);
      _expectUnitBranchIsolation(
        states.persistent,
        persistentResult.state,
        states.domain,
        domainResult.state,
      );
      expect(persistentResult.state.units.single.carriedArtifactId, isNull);
      expect(
        persistentResult.state.artifacts.single.location,
        const WorldArtifactLocation.stored(cityId: 'city_1'),
      );
    });

    test('store in city reject preserves both state identities', () {
      final unit = _unit(id: 'carrier_1', col: 1, row: 1);
      final states = _states(units: [unit], cities: const [_playerCity]);

      final persistentResult = const PersistentArtifactCommandResolver()
          .storeInCity(
            state: states.persistent,
            command: const StoreArtifactInCityCommand('carrier_1'),
            actorPlayerId: _playerId,
          );
      final domainResult = const DomainArtifactCommandResolver().storeInCity(
        state: states.domain,
        command: const StoreArtifactInCityCommand('carrier_1'),
        actorPlayerId: _playerId,
      );

      _expectRejectedIdentity(
        states.persistent,
        persistentResult,
        states.domain,
        domainResult,
        reason: 'unit_not_carrying_artifact',
      );
    });

    test('artifact trade has exact parity and trade branch isolation', () {
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.merchantsSeal,
        location: WorldArtifactLocation.stored(cityId: 'city_1'),
      );
      final states = _states(
        units: [_unit(id: 'sentinel_1', col: 8, row: 8)],
        cities: const [_playerCity, _otherPlayerCity],
        artifacts: const [artifact],
        playerGold: const {_playerId: 10, _otherPlayerId: 1},
      );
      const command = TradeArtifactCommand(
        playerId: _playerId,
        targetPlayerId: _otherPlayerId,
        offeredArtifactId: 'artifact_1',
        offeredGold: 3,
      );

      final persistentResult = const PersistentArtifactCommandResolver()
          .tradeArtifact(
            state: states.persistent,
            command: command,
            actorPlayerId: _playerId,
          );
      final domainResult = const DomainArtifactCommandResolver().tradeArtifact(
        state: states.domain,
        command: command,
        actorPlayerId: _playerId,
      );

      _expectParity(persistentResult, domainResult, accepted: true);
      _expectTradeBranchIsolation(
        states.persistent,
        persistentResult.state,
        states.domain,
        domainResult.state,
      );
      expect(persistentResult.state.playerGold, {
        _playerId: 7,
        _otherPlayerId: 4,
      });
      expect(
        persistentResult.state.artifacts.single.location,
        const WorldArtifactLocation.stored(cityId: 'city_2'),
      );
    });

    test('artifact trade reject preserves both state identities', () {
      final states = _states(
        cities: const [_playerCity, _otherPlayerCity],
        artifacts: const [
          WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.merchantsSeal,
            location: WorldArtifactLocation.stored(cityId: 'city_1'),
          ),
        ],
        playerGold: const {_playerId: 10, _otherPlayerId: 1},
      );
      const command = TradeArtifactCommand(
        playerId: _playerId,
        targetPlayerId: _otherPlayerId,
        offeredArtifactId: 'artifact_1',
      );

      final persistentResult = const PersistentArtifactCommandResolver()
          .tradeArtifact(
            state: states.persistent,
            command: command,
            actorPlayerId: _otherPlayerId,
          );
      final domainResult = const DomainArtifactCommandResolver().tradeArtifact(
        state: states.domain,
        command: command,
        actorPlayerId: _otherPlayerId,
      );

      _expectRejectedIdentity(
        states.persistent,
        persistentResult,
        states.domain,
        domainResult,
        reason: 'invalid_artifact_trade_actor',
      );
    });
  });
}

typedef _StatePair = ({PersistentGameState persistent, DomainState domain});

_StatePair _states({
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  List<WorldArtifact> artifacts = const [],
  Map<String, int> playerGold = const {_playerId: 17, _otherPlayerId: 11},
}) {
  final runtimeState = GameRuntimeState.snapshot(
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
    turnStartedAt: DateTime.utc(2026, 7, 18),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _otherPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _otherPlayerId: PlayerCountry.france,
      },
      playerGold: playerGold,
      playerWarWeariness: const {_playerId: 3},
      playerStabilityNet: const {_otherPlayerId: -2},
      units: units,
      cities: cities,
      artifacts: artifacts,
      runtimeState: runtimeState,
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _playerId,
          name: 'One',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _otherPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: playerGold,
      playerWarWeariness: const {_playerId: 3},
      playerStabilityNet: const {_otherPlayerId: -2},
      units: units,
      cities: cities,
      artifacts: artifacts,
      diplomacy: runtimeState.diplomacy,
      intendedAttacks: runtimeState.intendedAttacks,
      resourceTradeAgreements: runtimeState.resourceTradeAgreements,
      dominationHoldTurnsByPlayerId: runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          runtimeState.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          runtimeState.mapObjectiveHoldStatesByObjectiveId,
    ),
  );
}

GameUnit _unit({
  required String id,
  required int col,
  required int row,
  String? carriedArtifactId,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.scout,
    name: 'Scout',
    col: col,
    row: row,
    movementPoints: 5,
    carriedArtifactId: carriedArtifactId,
  );
}

void _expectParity(
  PersistentArtifactCommandResult persistent,
  DomainArtifactCommandResult domain, {
  required bool accepted,
  String? reason,
}) {
  expect(persistent.accepted, accepted);
  expect(domain.accepted, accepted);
  expect(persistent.reason, reason);
  expect(domain.reason, reason);
  expect(persistent.state.playerGold, domain.state.playerGold);
  expect(persistent.state.units, domain.state.units);
  expect(persistent.state.artifacts, domain.state.artifacts);
}

void _expectRejectedIdentity(
  PersistentGameState persistentBefore,
  PersistentArtifactCommandResult persistent,
  DomainState domainBefore,
  DomainArtifactCommandResult domain, {
  required String reason,
}) {
  _expectParity(persistent, domain, accepted: false, reason: reason);
  expect(identical(persistent.state, persistentBefore), isTrue);
  expect(identical(domain.state, domainBefore), isTrue);
}

void _expectUnitBranchIsolation(
  PersistentGameState persistentBefore,
  PersistentGameState persistentAfter,
  DomainState domainBefore,
  DomainState domainAfter,
) {
  expect(
    persistentAfter,
    persistentBefore.copyWith(
      units: persistentAfter.units,
      artifacts: persistentAfter.artifacts,
    ),
  );
  expect(
    domainAfter,
    domainBefore.copyWith(
      units: domainAfter.units,
      artifacts: domainAfter.artifacts,
    ),
  );
  expect(identical(persistentAfter.units, persistentBefore.units), isFalse);
  expect(
    identical(persistentAfter.artifacts, persistentBefore.artifacts),
    isFalse,
  );
  expect(
    identical(persistentAfter.playerGold, persistentBefore.playerGold),
    isTrue,
  );
  expect(identical(domainAfter.units, domainBefore.units), isFalse);
  expect(identical(domainAfter.artifacts, domainBefore.artifacts), isFalse);
  expect(identical(domainAfter.playerGold, domainBefore.playerGold), isTrue);
}

void _expectTradeBranchIsolation(
  PersistentGameState persistentBefore,
  PersistentGameState persistentAfter,
  DomainState domainBefore,
  DomainState domainAfter,
) {
  expect(
    persistentAfter,
    persistentBefore.copyWith(
      artifacts: persistentAfter.artifacts,
      playerGold: persistentAfter.playerGold,
    ),
  );
  expect(
    domainAfter,
    domainBefore.copyWith(
      artifacts: domainAfter.artifacts,
      playerGold: domainAfter.playerGold,
    ),
  );
  expect(identical(persistentAfter.units, persistentBefore.units), isTrue);
  expect(
    identical(persistentAfter.artifacts, persistentBefore.artifacts),
    isFalse,
  );
  expect(
    identical(persistentAfter.playerGold, persistentBefore.playerGold),
    isFalse,
  );
  expect(identical(domainAfter.units, domainBefore.units), isTrue);
  expect(identical(domainAfter.artifacts, domainBefore.artifacts), isFalse);
  expect(identical(domainAfter.playerGold, domainBefore.playerGold), isFalse);
}

const _playerCity = GameCity(
  id: 'city_1',
  ownerPlayerId: _playerId,
  name: 'One City',
  center: CityHex(col: 1, row: 1),
);

const _otherPlayerCity = GameCity(
  id: 'city_2',
  ownerPlayerId: _otherPlayerId,
  name: 'Two City',
  center: CityHex(col: 4, row: 1),
);
