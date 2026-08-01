part of 'unit_action_command_resolver_test.dart';

void _expectFortifyRejected(
  List<GameUnit> units,
  List<WorldArtifact> artifacts,
  DomainActionState interaction, {
  required String unitId,
  required String actorPlayerId,
  required String reason,
}) {
  _expectRejected(
    UnitActionCommandResolver.fortifyUnit(
      units: units,
      artifacts: artifacts,
      interaction: interaction,
      command: FortifyUnitCommand(unitId),
      actorPlayerId: actorPlayerId,
    ),
    units: units,
    artifacts: artifacts,
    interaction: interaction,
    reason: reason,
  );
}

void _expectRejected(
  UnitActionCommandResult result, {
  required List<GameUnit> units,
  required List<WorldArtifact> artifacts,
  required DomainActionState interaction,
  required String reason,
}) {
  expect((result.accepted, result.reason), (false, reason));
  expect(identical(result.units, units), isTrue);
  expect(identical(result.artifacts, artifacts), isTrue);
  expect(identical(result.interaction, interaction), isTrue);
}

void _expectChangedCollectionsImmutable(UnitActionCommandResult result) {
  expect(() => result.units.clear(), throwsUnsupportedError);
  expect(() => result.artifacts.clear(), throwsUnsupportedError);
}

void _expectChangedUnitsImmutable(UnitActionCommandResult result) {
  expect(() => result.units.clear(), throwsUnsupportedError);
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

WorldArtifact _mapArtifact() {
  return const WorldArtifact(
    id: 'artifact_map',
    type: WorldArtifactType.astronomersTablets,
    location: WorldArtifactLocation.map(col: 6, row: 1),
  );
}
