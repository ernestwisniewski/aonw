part of 'unit_action_command_resolver_parity_test.dart';

typedef _StateBoundaries = ({
  PersistentGameState persistent,
  DomainState domain,
  PersistedInteractionState interaction,
});

_StateBoundaries _states({
  List<GameUnit> units = const [],
  List<WorldArtifact> artifacts = const [],
  PersistedInteractionState interaction = PersistedInteractionState.empty,
}) {
  final runtime = GameRuntimeState.snapshot(
    cityFoundingDraft: interaction.cityFoundingDraft,
    pendingAction: interaction.pendingAction,
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
    mapObjectiveHoldStatesByObjectiveId: const {
      'objective_1': MapObjectiveHoldState(
        objectiveId: 'objective_1',
        playerId: _playerId,
        holdTurns: 2,
      ),
    },
    turnStartedAt: DateTime.utc(2026, 7, 18),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _otherPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _otherPlayerId: PlayerCountry.france,
      },
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      units: units,
      artifacts: artifacts,
      runtimeState: runtime,
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
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      units: units,
      artifacts: artifacts,
      mapObjectiveHoldStatesByObjectiveId:
          runtime.mapObjectiveHoldStatesByObjectiveId,
    ),
    interaction: interaction,
  );
}

void _expectAcceptedParity(
  _StateBoundaries before,
  PersistentUnitActionResult persistent,
  DomainUnitActionCommandResult domain,
) {
  _expectParity(persistent, domain, accepted: true);
  expect(
    persistent.state,
    before.persistent.copyWith(
      units: persistent.state.units,
      artifacts: persistent.state.artifacts,
      runtimeState: before.persistent.runtimeState.copyWith(
        cityFoundingDraft: domain.interaction.cityFoundingDraft,
        pendingAction: domain.interaction.pendingAction,
      ),
    ),
  );
  expect(
    domain.state,
    before.domain.copyWith(
      units: domain.state.units,
      artifacts: domain.state.artifacts,
    ),
  );
  _expectDomainBoundaries(domain);
}

void _expectRejectedIdentity(
  _StateBoundaries before,
  PersistentUnitActionResult persistent,
  DomainUnitActionCommandResult domain, {
  required String reason,
}) {
  _expectParity(persistent, domain, accepted: false, reason: reason);
  expect(identical(persistent.state, before.persistent), isTrue);
  expect(identical(domain.state, before.domain), isTrue);
  expect(identical(domain.interaction, before.interaction), isTrue);
  _expectDomainBoundaries(domain);
}

void _expectParity(
  PersistentUnitActionResult persistent,
  DomainUnitActionCommandResult domain, {
  required bool accepted,
  String? reason,
}) {
  expect(persistent.accepted, accepted);
  expect(domain.accepted, accepted);
  expect(persistent.reason, reason);
  expect(domain.reason, reason);
  expect(persistent.events, isEmpty);
  expect(persistent.state.units, domain.state.units);
  expect(persistent.state.artifacts, domain.state.artifacts);
  expect(
    persistent.state.runtimeState.cityFoundingDraft,
    domain.interaction.cityFoundingDraft,
  );
  expect(
    persistent.state.runtimeState.pendingAction,
    domain.interaction.pendingAction,
  );
}

void _expectDomainBoundaries(DomainUnitActionCommandResult result) {
  final DomainState state = result.state;
  final PersistedInteractionState interaction = result.interaction;
  expect(state, same(result.state));
  expect(interaction, same(result.interaction));
}

GameUnit _unit({
  String id = 'unit_1',
  int col = 1,
  int movementPoints = 3,
  QueuedMovePath? queuedPath,
  WorkerJob? workerJob,
  CityFoundingJob? cityFoundingJob,
  WorkerAssignment? workerAssignment,
  MerchantTradeRoute? merchantTradeRoute,
  String? excavatingArtifactId,
  UnitPosture posture = UnitPosture.active,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: 1,
    movementPoints: movementPoints,
    queuedPath: queuedPath,
    workerJob: workerJob,
    cityFoundingJob: cityFoundingJob,
    workerAssignment: workerAssignment,
    merchantTradeRoute: merchantTradeRoute,
    excavatingArtifactId: excavatingArtifactId,
    posture: posture,
  );
}

QueuedMovePath _queuedPath() {
  return QueuedMovePath(
    targetCol: 2,
    targetRow: 1,
    steps: const [
      UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
    ],
  );
}

CityFoundingDraft _draft(String unitId) {
  return CityFoundingDraft(
    unitId: unitId,
    ownerPlayerId: _playerId,
    center: const CityHex(col: 1, row: 1),
  );
}

const _artifact = WorldArtifact(
  id: 'artifact_map',
  type: WorldArtifactType.astronomersTablets,
  location: WorldArtifactLocation.map(col: 6, row: 1),
);
