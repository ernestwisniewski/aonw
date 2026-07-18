part of 'reducer_parity_accepted_semantics.dart';

String? validateAcceptedUnitActionCommand({
  required GameCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  if (events.isNotEmpty) {
    return 'must not emit events for unit actions';
  }
  return switch (command) {
    final CancelUnitActionCommand command => _validateAcceptedUnitActionCancel(
      command,
      before,
      after,
    ),
    final SkipUnitTurnCommand command => _validateAcceptedUnitActionSkip(
      command,
      before,
      after,
    ),
    final FortifyUnitCommand command => _validateAcceptedUnitActionFortify(
      command,
      before,
      after,
    ),
    _ => 'uses an unsupported unit-action command',
  };
}

String? _validateAcceptedUnitActionCancel(
  CancelUnitActionCommand command,
  PersistentGameState before,
  PersistentGameState after,
) {
  final unit = before.units.byId(command.unitId);
  if (unit == null) return 'must cancel an existing unit action';

  final pendingSkip = before.runtimeState.pendingAction;
  final restoredMovementPoints =
      pendingSkip is PendingUnitTurnSkip && pendingSkip.unitId == unit.id
      ? pendingSkip.restoreMovementPoints
      : unit.isFortified
      ? UnitMovementBalance.maxMovementPointsFor(
          type: unit.type,
          carriedArtifactId: unit.carriedArtifactId,
        )
      : unit.movementPoints;
  final updated = unit
      .copyWith(movementPoints: restoredMovementPoints)
      .copyWithQueuedPath(null)
      .copyWithWorkerJob(null)
      .copyWithCityFoundingJob(null)
      .copyWithWorkerAssignment(null)
      .copyWithExcavatingArtifact(null)
      .copyWithMerchantTradeRoute(null)
      .copyWithPosture(UnitPosture.active);
  final expected = before.copyWith(
    units: _replaceUnitActionFixtureUnit(before.units, updated),
    artifacts: _cancelUnitActionFixtureArtifactExcavation(
      before.artifacts,
      unit,
    ),
    runtimeState: _clearUnitActionFixtureRuntime(before.runtimeState, unit.id),
  );
  return after == expected
      ? null
      : 'must only cancel the reviewed unit orders and owned runtime action';
}

String? _validateAcceptedUnitActionSkip(
  SkipUnitTurnCommand command,
  PersistentGameState before,
  PersistentGameState after,
) {
  final unit = before.units.byId(command.unitId);
  if (unit == null) return 'must skip an existing unit';

  final updated = unit
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(null)
      .copyWithPosture(UnitPosture.active);
  final expected = before.copyWith(
    units: _replaceUnitActionFixtureUnit(before.units, updated),
    runtimeState: before.runtimeState.copyWith(
      cityFoundingDraft:
          before.runtimeState.cityFoundingDraft?.unitId == unit.id
          ? null
          : before.runtimeState.cityFoundingDraft,
      pendingAction: PendingUnitTurnSkip(
        ownerPlayerId: unit.ownerPlayerId,
        unitId: unit.id,
        restoreMovementPoints: unit.movementPoints,
      ),
    ),
  );
  return after == expected
      ? null
      : 'must consume movement, clear the path, and set the exact turn skip';
}

String? _validateAcceptedUnitActionFortify(
  FortifyUnitCommand command,
  PersistentGameState before,
  PersistentGameState after,
) {
  final unit = before.units.byId(command.unitId);
  if (unit == null || unit.isWorking) {
    return 'must fortify an existing idle unit';
  }

  final expected = before.copyWith(
    units: _replaceUnitActionFixtureUnit(
      before.units,
      UnitFortificationRules.fortify(unit),
    ),
    runtimeState: _clearUnitActionFixtureRuntime(before.runtimeState, unit.id),
  );
  return after == expected
      ? null
      : 'must fortify only the unit and clear only its owned runtime action';
}

GameRuntimeState _clearUnitActionFixtureRuntime(
  GameRuntimeState runtime,
  String unitId,
) {
  final clearPending = runtime.pendingAction?.ownsUnit(unitId) ?? false;
  final clearDraft = runtime.cityFoundingDraft?.unitId == unitId;
  if (!clearPending && !clearDraft) return runtime;
  return runtime.copyWith(
    cityFoundingDraft: clearDraft ? null : runtime.cityFoundingDraft,
    pendingAction: clearPending ? null : runtime.pendingAction,
  );
}

List<GameUnit> _replaceUnitActionFixtureUnit(
  List<GameUnit> units,
  GameUnit updated,
) {
  return [
    for (final unit in units)
      if (unit.id == updated.id) updated else unit,
  ];
}

List<WorldArtifact> _cancelUnitActionFixtureArtifactExcavation(
  List<WorldArtifact> artifacts,
  GameUnit unit,
) {
  final artifactId = unit.excavatingArtifactId;
  if (artifactId == null) return artifacts;
  return [
    for (final artifact in artifacts)
      if (artifact.id == artifactId && artifact.location.isBeingExcavated)
        artifact.copyWith(
          location: WorldArtifactLocation.map(
            col: artifact.location.col ?? unit.col,
            row: artifact.location.row ?? unit.row,
          ),
        )
      else
        artifact,
  ];
}
