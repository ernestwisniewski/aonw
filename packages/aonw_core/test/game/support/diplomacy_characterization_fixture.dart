part of '../diplomacy_command_router_characterization_test.dart';

const _player1 = 'p1';
const _player2 = 'p2';
const _player3 = 'p3';
const _player4 = 'p4';
const _sentinelPlayer = 'sentinel';

const _sentinelTrade = ResourceTradeAgreement(
  id: 'sentinel_trade',
  exporterPlayerId: _player3,
  importerPlayerId: _player4,
  resource: ResourceType.coal,
  goldPerTurn: 7,
  remainingTurns: 9,
);

PersistentGameState _diplomacyState({
  Map<String, int> playerColors = const {
    _player1: 1,
    _player2: 2,
    _player3: 3,
    _player4: 4,
    _sentinelPlayer: 99,
  },
  Map<String, PlayerCountry> playerCountries = const {
    _player1: PlayerCountry.poland,
    _player2: PlayerCountry.japan,
    _player3: PlayerCountry.egypt,
    _player4: PlayerCountry.canada,
    _sentinelPlayer: PlayerCountry.greece,
  },
  Map<String, int> playerGold = const {
    _player1: 100,
    _player2: 7,
    _player3: 11,
    _player4: 13,
    _sentinelPlayer: 97,
  },
  Map<String, int> playerWarWeariness = const {_sentinelPlayer: 5},
  Map<String, int> playerStabilityNet = const {_sentinelPlayer: 8},
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  DiplomacyState? diplomacy,
  Set<String> submittedPlayerIds = const {_sentinelPlayer},
  Map<String, int> timeoutStreaksByPlayerId = const {_sentinelPlayer: 2},
  Set<String> afkPlayerIds = const {_sentinelPlayer},
  Set<String> kickedPlayerIds = const {'removed_player'},
  List<IntendedAttack> intendedAttacks = const [],
  Map<String, int> dominationHoldTurnsByPlayerId = const {_sentinelPlayer: 3},
  Map<String, int> culturalVictoryHoldTurnsByPlayerId = const {
    _sentinelPlayer: 4,
  },
  List<ResourceTradeAgreement> resourceTradeAgreements = const [_sentinelTrade],
}) {
  return PersistentGameState.snapshot(
    playerColors: playerColors,
    playerCountries: playerCountries,
    playerGold: playerGold,
    playerWarWeariness: playerWarWeariness,
    playerStabilityNet: playerStabilityNet,
    units: units,
    cities: cities,
    fogOfWar: fogOfWar,
    runtimeState: GameRuntimeState.snapshot(
      submittedPlayerIds: submittedPlayerIds,
      timeoutStreaksByPlayerId: timeoutStreaksByPlayerId,
      afkPlayerIds: afkPlayerIds,
      kickedPlayerIds: kickedPlayerIds,
      intendedAttacks: intendedAttacks,
      diplomacy:
          diplomacy ?? DiplomacyState.empty.addContact(_player1, _player2),
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId: const {
        'sentinel_objective': MapObjectiveHoldState(
          objectiveId: 'sentinel_objective',
          playerId: _sentinelPlayer,
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: resourceTradeAgreements,
      turnStartedAt: DateTime.utc(2026, 7, 1, 12),
    ),
  );
}

_DiplomacyTestResult _route(
  PersistentGameState state,
  DiplomaticCommand command, {
  required String actorPlayerId,
  int turn = 10,
  bool canAct = true,
}) {
  final runtime = state.runtimeState;
  final resolved = DiplomacyCommandResolver.resolve(
    state: DiplomacyCommandState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: runtime.diplomacy,
      intendedAttacks: runtime.intendedAttacks,
      resourceTradeAgreements: runtime.resourceTradeAgreements,
    ),
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );
  if (!resolved.accepted) {
    return _DiplomacyTestResult(
      accepted: false,
      state: state,
      reason: resolved.reason,
    );
  }
  final runtimeChanged =
      !identical(resolved.diplomacy, runtime.diplomacy) ||
      !identical(resolved.intendedAttacks, runtime.intendedAttacks) ||
      !identical(
        resolved.resourceTradeAgreements,
        runtime.resourceTradeAgreements,
      );
  return _DiplomacyTestResult(
    accepted: true,
    state: state.copyWith(
      playerGold: identical(resolved.playerGold, state.playerGold)
          ? null
          : resolved.playerGold,
      runtimeState: runtimeChanged
          ? runtime.copyWith(
              diplomacy: identical(resolved.diplomacy, runtime.diplomacy)
                  ? null
                  : resolved.diplomacy,
              intendedAttacks:
                  identical(resolved.intendedAttacks, runtime.intendedAttacks)
                  ? null
                  : resolved.intendedAttacks,
              resourceTradeAgreements:
                  identical(
                    resolved.resourceTradeAgreements,
                    runtime.resourceTradeAgreements,
                  )
                  ? null
                  : resolved.resourceTradeAgreements,
            )
          : null,
    ),
    events: resolved.events,
  );
}

final class _DiplomacyTestResult {
  const _DiplomacyTestResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

void _expectRejectedDiplomacy(
  _DiplomacyTestResult result,
  PersistentGameState input,
  String reason,
) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.events, isEmpty);
  expect(result.state, same(input));
  expect(result.state.runtimeState, same(input.runtimeState));
  expect(
    result.state.runtimeState.diplomacy,
    same(input.runtimeState.diplomacy),
  );
  expect(
    result.state.runtimeState.intendedAttacks,
    same(input.runtimeState.intendedAttacks),
  );
  expect(
    result.state.runtimeState.resourceTradeAgreements,
    same(input.runtimeState.resourceTradeAgreements),
  );
  expect(result.state.playerGold, same(input.playerGold));
}

void _expectOuterSentinelsUnchanged(
  _DiplomacyTestResult result,
  PersistentGameState input, {
  bool goldChanged = false,
}) {
  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.state.playerColors, same(input.playerColors));
  expect(result.state.playerCountries, same(input.playerCountries));
  if (!goldChanged) expect(result.state.playerGold, same(input.playerGold));
  expect(result.state.playerWarWeariness, same(input.playerWarWeariness));
  expect(result.state.playerStabilityNet, same(input.playerStabilityNet));
  expect(result.state.units, same(input.units));
  expect(result.state.cities, same(input.cities));
  expect(result.state.artifacts, same(input.artifacts));
  expect(result.state.fieldImprovements, same(input.fieldImprovements));
  expect(result.state.fogOfWar, same(input.fogOfWar));
  expect(result.state.research, same(input.research));
  expect(result.state.wonderRegistry, same(input.wonderRegistry));
}

void _expectRuntimeSentinelsUnchanged(
  _DiplomacyTestResult result,
  PersistentGameState input, {
  bool intendedAttacksChanged = false,
  bool tradesChanged = false,
}) {
  final actual = result.state.runtimeState;
  final original = input.runtimeState;
  expect(actual.submittedPlayerIds, same(original.submittedPlayerIds));
  expect(
    actual.timeoutStreaksByPlayerId,
    same(original.timeoutStreaksByPlayerId),
  );
  expect(actual.afkPlayerIds, same(original.afkPlayerIds));
  expect(actual.kickedPlayerIds, same(original.kickedPlayerIds));
  if (!intendedAttacksChanged) {
    expect(actual.intendedAttacks, same(original.intendedAttacks));
  }
  expect(
    actual.dominationHoldTurnsByPlayerId,
    same(original.dominationHoldTurnsByPlayerId),
  );
  expect(
    actual.culturalVictoryHoldTurnsByPlayerId,
    same(original.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    actual.mapObjectiveHoldStatesByObjectiveId,
    same(original.mapObjectiveHoldStatesByObjectiveId),
  );
  if (!tradesChanged) {
    expect(
      actual.resourceTradeAgreements,
      same(original.resourceTradeAgreements),
    );
  }
  expect(actual.turnStartedAt, original.turnStartedAt);
}

DiplomaticProposal _proposal({
  String id = 'proposal_1',
  String fromPlayerId = _player1,
  String toPlayerId = _player2,
  DiplomaticProposalKind kind = DiplomaticProposalKind.truce,
  int createdTurn = 4,
  int expiresOnTurn = 12,
  int goldPayment = 0,
}) {
  return DiplomaticProposal(
    id: id,
    fromPlayerId: fromPlayerId,
    toPlayerId: toPlayerId,
    kind: kind,
    createdTurn: createdTurn,
    expiresOnTurn: expiresOnTurn,
    goldPayment: goldPayment,
  );
}

DiplomaticMessage _message({
  String id = 'message_1',
  String fromPlayerId = _player1,
  String toPlayerId = _player2,
  DiplomaticMessageTopic topic = DiplomaticMessageTopic.troopsNearCities,
  int createdTurn = 4,
  int expiresOnTurn = 12,
}) {
  return DiplomaticMessage.create(
    id: id,
    fromPlayerId: fromPlayerId,
    toPlayerId: toPlayerId,
    topic: topic,
    createdTurn: createdTurn,
    expiresOnTurn: expiresOnTurn,
  );
}
