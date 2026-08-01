part of 'reducer_parity_resource_trade_characterization.dart';

const _tradeActorId = 'player_1';
const _tradeTargetId = 'player_2';

const _parityUnrelatedTrade = ResourceTradeAgreement(
  id: 'parity_unrelated_trade',
  exporterPlayerId: 'player_3',
  importerPlayerId: 'player_4',
  resource: ResourceType.coal,
  goldPerTurn: 7,
  remainingTurns: 9,
);

const _parityRequestedTrade = ResourceTradeAgreement(
  id: 'parity_requested_horses',
  exporterPlayerId: _tradeTargetId,
  importerPlayerId: _tradeActorId,
  resource: ResourceType.horses,
  goldPerTurn: 2,
  remainingTurns: 4,
);

const _parityOfferedTrade = ResourceTradeAgreement(
  id: 'parity_offered_iron',
  exporterPlayerId: _tradeActorId,
  importerPlayerId: _tradeTargetId,
  resource: ResourceType.iron,
  goldPerTurn: 0,
  remainingTurns: 4,
);

DomainState _tradeParityBaseState(DomainState source) {
  return source.copyWith(
    submittedPlayerIds: const {'sentinel'},
    timeoutStreaksByPlayerId: const {'sentinel': 2},
    afkPlayerIds: const {'sentinel'},
    kickedPlayerIds: const {'removed_player'},
    intendedAttacks: const [
      IntendedAttack(
        attackerUnitId: 'sentinel_attacker',
        defenderCol: 2,
        defenderRow: 0,
        declaredAtTick: 41,
        declaringPlayerId: 'sentinel',
      ),
    ],
    diplomacy: source.diplomacy,
    dominationHoldTurnsByPlayerId: const {'sentinel': 3},
    culturalVictoryHoldTurnsByPlayerId: const {'sentinel': 4},
    mapObjectiveHoldStatesByObjectiveId: const {
      'sentinel_objective': MapObjectiveHoldState(
        objectiveId: 'sentinel_objective',
        playerId: 'sentinel',
        holdTurns: 2,
      ),
    },
    resourceTradeAgreements: const [_parityUnrelatedTrade],
    turnStartedAt: DateTime.utc(2026, 7, 1, 12),
  );
}

DomainState _tradeParityAtWar(DomainState state) {
  return state.copyWith(
    diplomacy: state.diplomacy.setStatus(
      _tradeActorId,
      _tradeTargetId,
      DiplomaticRelationStatus.war,
    ),
  );
}

DomainState _tradeParityWithGold(DomainState state, int gold) {
  return state.copyWith(playerGold: {...state.playerGold, _tradeActorId: gold});
}

DomainState _tradeParityWithoutTargetHorses(DomainState state) {
  return state.copyWith(
    research: state.research.updatePlayer(
      _tradeTargetId,
      PlayerResearchState.empty,
    ),
  );
}

DomainState _tradeParityWithAgreements(
  DomainState state,
  List<ResourceTradeAgreement> agreements,
) {
  return state.copyWith(resourceTradeAgreements: agreements);
}

ReducerParityFixture _rejectedTradeParityFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required DomainState state,
  required DomainCommand command,
  required String reason,
}) {
  return _tradeParityFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    state: state,
    command: command,
    accepted: false,
    reason: reason,
    expectedState: state,
  );
}

ReducerParityFixture _acceptedTradeParityFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required DomainState state,
  required DomainCommand command,
  required DomainState expectedState,
}) {
  return _tradeParityFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    state: state,
    command: command,
    accepted: true,
    expectedState: expectedState,
  );
}

ReducerParityFixture _tradeParityFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required DomainState state,
  required DomainCommand command,
  required bool accepted,
  required DomainState expectedState,
  String? reason,
}) {
  return ReducerParityFixture(
    id: id,
    family: 'resource-trade',
    now: template.now,
    actorPlayerId: _tradeActorId,
    tick: template.tick + tickOffset,
    mapData: template.mapData,
    match: template.match,
    save: template.save,
    state: state,
    command: command,
    expectedAccepted: accepted,
    expectedReason: reason,
    expectedSave: reducerParitySave(template.save),
    expectedState: CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
    expectedEvents: const [],
  );
}
