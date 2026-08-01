part of 'reducer_parity_diplomacy_characterization.dart';

const _diplomacyActorId = 'player_1';
const _diplomacyTargetId = 'player_2';
const _diplomacyObserverId = 'player_3';
const _diplomacyTurn = 7;

const _diplomacyObserver = Player(
  id: _diplomacyObserverId,
  name: _diplomacyObserverId,
  colorValue: 0xFF4A8F63,
  country: PlayerCountry.france,
);

const _diplomacyWireObserver = WirePlayer(
  id: _diplomacyObserverId,
  userId: 'user_3',
  name: _diplomacyObserverId,
  colorValue: 0xFF4A8F63,
  country: PlayerCountry.france,
  kind: WirePlayerKind.human,
  connectionState: WirePlayerConnectionState.connected,
  ready: true,
);

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

DomainState _diplomacyParityBaseState(DomainState source) {
  final diplomacy = _diplomacySentinelState();
  final base = source.copyWith(
    participants: [...source.participants, _diplomacyObserver],
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
  );
  return _withDiplomacySentinelRuntime(base, diplomacy);
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

DomainState _withDiplomacySentinelRuntime(
  DomainState source,
  DiplomacyState diplomacy,
) {
  return source.copyWith(
    submittedPlayerIds: const {_diplomacyObserverId},
    timeoutStreaksByPlayerId: const {_diplomacyObserverId: 2},
    afkPlayerIds: const {_diplomacyObserverId},
    kickedPlayerIds: const {_diplomacyObserverId},
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
    dominationHoldTurnsByPlayerId: const {_diplomacyObserverId: 3},
    culturalVictoryHoldTurnsByPlayerId: const {_diplomacyObserverId: 4},
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
  required DomainState state,
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
  required DomainState state,
  required DiplomaticCommand command,
  required DomainState expectedState,
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
  required DomainState state,
  required DiplomaticCommand command,
  required bool accepted,
  required DomainState expectedState,
  required List<GameEvent> expectedEvents,
  String? reason,
}) {
  final match = template.match.copyWith(
    players: [...template.match.players, _diplomacyWireObserver],
    maxPlayers: template.match.maxPlayers + 1,
  );
  final save = template.save.copyWith(
    players: [...template.save.players, _diplomacyObserver],
    playerStates: {
      ...template.save.playerStates,
      _diplomacyObserverId: PlayerTurnState.active,
    },
  );
  return ReducerParityFixture(
    id: id,
    family: 'diplomacy',
    now: template.now,
    actorPlayerId: actorPlayerId,
    tick: template.tick + tickOffset,
    mapData: template.mapData,
    match: match,
    save: save,
    state: state,
    command: command,
    expectedAccepted: accepted,
    expectedReason: reason,
    expectedSave: reducerParitySave(save),
    expectedState: CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
    expectedEvents: reducerParityEvents(expectedEvents),
  );
}

DomainState _withoutPairContact(DomainState state) {
  final key = DiplomacyState.relationKey(_diplomacyActorId, _diplomacyTargetId);
  final diplomacy = state.diplomacy;
  return _withDiplomacyOracle(
    state,
    diplomacy.copyWith(
      contactKeys: {...diplomacy.contactKeys}..remove(key),
      relations: {...diplomacy.relations}..remove(key),
    ),
  );
}

DomainState _withPairStatus(
  DomainState state,
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
