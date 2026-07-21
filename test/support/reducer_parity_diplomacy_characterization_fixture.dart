part of 'reducer_parity_diplomacy_characterization.dart';

const _diplomacyActorId = 'player_1';
const _diplomacyTargetId = 'player_2';
const _diplomacyObserverId = 'player_3';
const _diplomacyTurn = 7;

const _unrelatedProposal = DiplomaticProposal(
  id: 'sentinel_proposal',
  fromPlayerId: _diplomacyObserverId,
  toPlayerId: _diplomacyTargetId,
  kind: DiplomaticProposalKind.friendship,
  createdTurn: 2,
  expiresOnTurn: 20,
);

final _unrelatedMessage = DiplomaticMessage.create(
  id: 'sentinel_message',
  fromPlayerId: _diplomacyObserverId,
  toPlayerId: _diplomacyTargetId,
  topic: DiplomaticMessageTopic.peacefulPraise,
  createdTurn: 2,
  expiresOnTurn: 20,
);

const _pairTrade = ResourceTradeAgreement(
  id: 'sentinel_pair_trade',
  exporterPlayerId: _diplomacyTargetId,
  importerPlayerId: _diplomacyActorId,
  resource: ResourceType.horses,
  goldPerTurn: 3,
  remainingTurns: 5,
);

const _unrelatedTrade = ResourceTradeAgreement(
  id: 'sentinel_observer_trade',
  exporterPlayerId: _diplomacyObserverId,
  importerPlayerId: _diplomacyActorId,
  resource: ResourceType.iron,
  goldPerTurn: 1,
  remainingTurns: 4,
);

PersistentGameState _diplomacyParityBaseState(PersistentGameState source) {
  final diplomacy = _diplomacySentinelState();
  return source.copyWith(
    playerColors: {...source.playerColors, _diplomacyObserverId: 0xFF4A8F63},
    playerCountries: {
      ...source.playerCountries,
      _diplomacyObserverId: PlayerCountry.france,
    },
    playerGold: {...source.playerGold, _diplomacyObserverId: 31},
    playerWarWeariness: {...source.playerWarWeariness, _diplomacyObserverId: 6},
    playerStabilityNet: {...source.playerStabilityNet, _diplomacyObserverId: 7},
    units: _diplomacySentinelUnits(),
    fogOfWar: FogOfWarState(
      players: {
        _diplomacyActorId: PlayerFogOfWar(
          playerId: _diplomacyActorId,
          discoveredHexes: {const HexCoordinate(col: 9, row: 9)},
          visibleHexes: {const HexCoordinate(col: 9, row: 9)},
        ),
      },
    ),
    runtimeState: _diplomacySentinelRuntime(diplomacy),
  );
}

DiplomacyState _diplomacySentinelState() {
  final observerKey = DiplomacyState.relationKey(
    _diplomacyActorId,
    _diplomacyObserverId,
  );
  final observerEntry = DiplomaticScoreEntry.between(
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyObserverId,
    turn: 1,
    delta: 4,
    scoreAfter: 4,
    reason: DiplomaticScoreChangeReason.manual,
    sourceId: 'sentinel_score',
  );
  return DiplomacyState(
    contactKeys: {
      DiplomacyState.relationKey(_diplomacyActorId, _diplomacyTargetId),
      observerKey,
      DiplomacyState.relationKey(_diplomacyTargetId, _diplomacyObserverId),
    },
    relations: {
      observerKey: DiplomaticRelation.between(
        playerAId: _diplomacyActorId,
        playerBId: _diplomacyObserverId,
        relationScore: 4,
        lastChangedTurn: 1,
        lastChangeReason: DiplomaticRelationChangeReason.manual,
      ),
    },
    pendingProposals: const {'sentinel_proposal': _unrelatedProposal},
    messages: {_unrelatedMessage.id: _unrelatedMessage},
    scoreHistory: {
      observerKey: [observerEntry],
    },
  );
}

List<GameUnit> _diplomacySentinelUnits() {
  return [
    GameUnit.startingWarrior(ownerPlayerId: _diplomacyActorId, col: 0, row: 1),
    GameUnit.startingWarrior(ownerPlayerId: _diplomacyTargetId, col: 2, row: 1),
    GameUnit.startingWarrior(
      ownerPlayerId: _diplomacyObserverId,
      col: 1,
      row: 1,
    ),
  ];
}

GameRuntimeState _diplomacySentinelRuntime(DiplomacyState diplomacy) {
  return GameRuntimeState.snapshot(
    submittedPlayerIds: const {'sentinel_submitted'},
    timeoutStreaksByPlayerId: const {'sentinel_timeout': 2},
    afkPlayerIds: const {'sentinel_afk'},
    kickedPlayerIds: const {'sentinel_kicked'},
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'warrior_player_1',
        defenderCol: 2,
        defenderRow: 1,
        declaredAtTick: 41,
        declaringPlayerId: _diplomacyActorId,
      ),
      IntendedAttack(
        attackerUnitId: 'warrior_player_2',
        defenderCol: 0,
        defenderRow: 0,
        declaredAtTick: 42,
        declaringPlayerId: _diplomacyTargetId,
      ),
      IntendedAttack(
        attackerUnitId: 'warrior_player_1',
        defenderCol: 1,
        defenderRow: 1,
        declaredAtTick: 43,
        declaringPlayerId: _diplomacyActorId,
      ),
      IntendedAttack(
        attackerUnitId: 'missing_attacker',
        defenderCol: 2,
        defenderRow: 1,
        declaredAtTick: 44,
        declaringPlayerId: _diplomacyActorId,
      ),
    ],
    diplomacy: diplomacy,
    dominationHoldTurnsByPlayerId: const {'sentinel_domination': 3},
    culturalVictoryHoldTurnsByPlayerId: const {'sentinel_culture': 4},
    mapObjectiveHoldStatesByObjectiveId: const {
      'sentinel_objective': MapObjectiveHoldState(
        objectiveId: 'sentinel_objective',
        playerId: _diplomacyObserverId,
        holdTurns: 2,
      ),
    },
    resourceTradeAgreements: const [_pairTrade, _unrelatedTrade],
    turnStartedAt: DateTime.utc(2026, 7, 1, 12),
  );
}

ReducerParityFixture _rejectedDiplomacyFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required PersistentGameState state,
  required DiplomaticCommand command,
  required String reason,
  String actorPlayerId = _diplomacyActorId,
}) {
  return _diplomacyFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    actorPlayerId: actorPlayerId,
    state: state,
    command: command,
    accepted: false,
    reason: reason,
    expectedState: state,
    expectedEvents: const [],
  );
}

ReducerParityFixture _acceptedDiplomacyFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required PersistentGameState state,
  required DiplomaticCommand command,
  required PersistentGameState expectedState,
  required List<GameEvent> expectedEvents,
  String actorPlayerId = _diplomacyActorId,
}) {
  return _diplomacyFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    actorPlayerId: actorPlayerId,
    state: state,
    command: command,
    accepted: true,
    expectedState: expectedState,
    expectedEvents: expectedEvents,
  );
}

ReducerParityFixture _diplomacyFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required String actorPlayerId,
  required PersistentGameState state,
  required DiplomaticCommand command,
  required bool accepted,
  required PersistentGameState expectedState,
  required List<GameEvent> expectedEvents,
  String? reason,
}) {
  return ReducerParityFixture(
    id: id,
    family: 'diplomacy',
    now: template.now,
    actorPlayerId: actorPlayerId,
    tick: template.tick + tickOffset,
    mapData: template.mapData,
    match: template.match,
    save: template.save,
    state: state,
    command: command,
    expectedAccepted: accepted,
    expectedReason: reason,
    expectedSave: reducerParitySave(template.save),
    expectedState: expectedState.toJson(),
    expectedEvents: reducerParityEvents(expectedEvents),
  );
}

PersistentGameState _withoutPairContact(PersistentGameState state) {
  final key = DiplomacyState.relationKey(_diplomacyActorId, _diplomacyTargetId);
  final diplomacy = state.runtimeState.diplomacy;
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      contactKeys: {...diplomacy.contactKeys}..remove(key),
      relations: {...diplomacy.relations}..remove(key),
    ),
  );
}

PersistentGameState _withPairStatus(
  PersistentGameState state,
  DiplomaticRelationStatus status, {
  int? expiresOnTurn,
}) {
  return _withRelationOracle(
    state,
    playerAId: _diplomacyActorId,
    playerBId: _diplomacyTargetId,
    status: status,
    statusExpiresOnTurn: expiresOnTurn,
  );
}
