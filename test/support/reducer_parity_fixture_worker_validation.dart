part of 'reducer_parity_fixture.dart';

const _workerParitySentinelId = 'worker_sentinel';

const _workerAcceptanceModes = <Type, String>{
  SelectWorkerImprovementCommand: 'select',
  ConfirmWorkerImprovementCommand: 'confirm',
  CancelWorkerJobCommand: 'cancel-job',
  AssignWorkerToHexCommand: 'assign',
  CancelWorkerAssignmentCommand: 'cancel-assignment',
  AutomateWorkerCommand: 'automate',
};

String _workerAcceptanceMode(ReducerParityFixture fixture) =>
    _workerAcceptanceModes[fixture.command.runtimeType] ?? 'unexpected';

String _workerInteractionMode(ReducerParityFixture fixture) {
  final runtime = fixture.state;
  final pending = runtime.actions.pendingAction;
  final unitId = _workerCommandUnitId(fixture.command);
  if (fixture.command is ConfirmWorkerImprovementCommand &&
      pending is PendingWorkerActionSelection &&
      pending.ownerPlayerId == fixture.actorPlayerId &&
      pending.unitId == unitId &&
      pending.improvementType != null &&
      runtime.actions.cityFoundingDraft == null) {
    return 'matching-pending-cleared';
  }
  if (_isWorkerCancellation(fixture.command) &&
      _hasReviewedUnrelatedWorkerInteraction(fixture, unitId)) {
    return 'unrelated-interaction-preserved';
  }
  return 'none';
}

bool _permitsReviewedWorkerInteraction(ReducerParityFixture fixture) {
  if (fixture.family != 'worker' || !fixture.expectedAccepted) return false;
  return _workerInteractionMode(fixture) != 'none';
}

bool _isWorkerCancellation(DomainCommand command) {
  return command is CancelWorkerJobCommand ||
      command is CancelWorkerAssignmentCommand;
}

bool _hasReviewedUnrelatedWorkerInteraction(
  ReducerParityFixture fixture,
  String unitId,
) {
  final runtime = fixture.state;
  final pending = runtime.actions.pendingAction;
  final draft = runtime.actions.cityFoundingDraft;
  if (pending is! PendingWorkerActionSelection ||
      pending.ownerPlayerId != fixture.actorPlayerId ||
      pending.unitId == unitId ||
      draft == null ||
      draft.ownerPlayerId != fixture.actorPlayerId ||
      draft.unitId == unitId) {
    return false;
  }
  final pendingUnit = fixture.state.units.byId(pending.unitId);
  final draftUnit = fixture.state.units.byId(draft.unitId);
  return pendingUnit?.type == GameUnitType.worker &&
      pendingUnit?.ownerPlayerId == fixture.actorPlayerId &&
      draftUnit?.type == GameUnitType.settler &&
      draftUnit?.ownerPlayerId == fixture.actorPlayerId;
}

void _requireWorkerAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (!summary.workerAcceptanceModes.containsAll(const {
    'select',
    'confirm',
    'cancel-job',
    'assign',
    'cancel-assignment',
    'automate',
  })) {
    throw StateError(
      '$family needs accepted fixtures for all authoritative worker commands.',
    );
  }
  if (!summary.workerInteractionModes.containsAll(const {
    'matching-pending-cleared',
    'unrelated-interaction-preserved',
  })) {
    throw StateError(
      '$family needs matching-clear and unrelated-preserve interaction fixtures.',
    );
  }
}

void _requireAcceptedParityWorker(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  if (!_jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save)) ||
      events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata without emitting events',
    );
  }
  final unitId = _workerCommandUnitId(fixture.command);
  final workerIndex = fixture.state.units.indexWhere(
    (unit) => unit.id == unitId,
  );
  if (workerIndex < 0 ||
      fixture.state.units.where((unit) => unit.id == unitId).length != 1) {
    ReducerParityCorpus._fail(fixture, 'must target one existing worker');
  }
  _requireWorkerSentinel(fixture, unitId);

  final expectedWorker = _expectedWorkerAfterCommand(
    fixture,
    fixture.state.units[workerIndex],
  );
  final expectedUnits = [
    for (var index = 0; index < fixture.state.units.length; index++)
      if (index == workerIndex) expectedWorker else fixture.state.units[index],
  ];
  final expectedState = fixture.state.copyWith(
    units: expectedUnits,
    actions: _expectedWorkerActions(fixture, unitId),
  );
  final exactUnits =
      state.units.length == fixture.state.units.length &&
      _sameWorkerUnitOrder(fixture.state.units, state.units) &&
      _unrelatedWorkerUnitsPreserved(fixture.state, state, unitId);
  if (!exactUnits ||
      !_jsonDeepEquals(
        fixture.expectedState,
        CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
      ) ||
      !_jsonDeepEquals(
        CanonicalGameSnapshotCodec.encodeDomainState(state),
        CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
      )) {
    ReducerParityCorpus._fail(
      fixture,
      'must apply only the independently derived worker transition',
    );
  }
}

void _requireWorkerSentinel(ReducerParityFixture fixture, String unitId) {
  final sentinel = fixture.state.units.byId(_workerParitySentinelId);
  if (sentinel == null ||
      sentinel.id == unitId ||
      sentinel.type != GameUnitType.worker ||
      sentinel.ownerPlayerId != fixture.actorPlayerId ||
      sentinel.movementPoints <= 0) {
    ReducerParityCorpus._fail(
      fixture,
      'must contain the controlled unrelated worker sentinel',
    );
  }
}

GameUnit _expectedWorkerAfterCommand(
  ReducerParityFixture fixture,
  GameUnit worker,
) {
  final command = fixture.command;
  return switch (command) {
    SelectWorkerImprovementCommand(:final improvementType) =>
      _workerStartingReviewedJob(fixture, worker, improvementType),
    ConfirmWorkerImprovementCommand() => _workerStartingReviewedJob(
      fixture,
      worker,
      _confirmedWorkerImprovement(fixture, command),
    ),
    CancelWorkerJobCommand() =>
      worker.copyWithWorkerJob(null).copyWithQueuedPath(null),
    AssignWorkerToHexCommand() =>
      worker
          .copyWith(movementPoints: 0)
          .copyWithQueuedPath(null)
          .copyWithWorkerAssignment(
            WorkerAssignment(
              targetHex: CityHex(col: worker.col, row: worker.row),
            ),
          ),
    CancelWorkerAssignmentCommand() =>
      worker.copyWithWorkerAssignment(null).copyWithQueuedPath(null),
    AutomateWorkerCommand() => _workerStartingReviewedJob(
      fixture,
      worker,
      FieldImprovementType.farm,
    ),
    _ => throw StateError('Unexpected worker command in ${fixture.id}.'),
  };
}

FieldImprovementType _confirmedWorkerImprovement(
  ReducerParityFixture fixture,
  ConfirmWorkerImprovementCommand command,
) {
  if (command.improvementType case final improvement?) return improvement;
  final pending = fixture.state.actions.pendingAction;
  final pendingImprovement =
      pending is PendingWorkerActionSelection &&
          pending.ownerPlayerId == fixture.actorPlayerId &&
          pending.unitId == command.unitId
      ? pending.improvementType
      : null;
  if (pendingImprovement != null) return pendingImprovement;
  ReducerParityCorpus._fail(
    fixture,
    'accepted confirm must independently identify its improvement',
  );
}

GameUnit _workerStartingReviewedJob(
  ReducerParityFixture fixture,
  GameUnit worker,
  FieldImprovementType improvementType,
) {
  final totalTurns = FieldImprovementRules.buildTurnsFor(
    improvementType,
    ruleset: CityRulesets.standard,
    paceBalance: fixture.save.matchRules.paceBalance,
  );
  return worker
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(null)
      .copyWithWorkerAssignment(null)
      .copyWithWorkerJob(
        WorkerJob(
          targetHex: CityHex(col: worker.col, row: worker.row),
          improvementType: improvementType,
          remainingTurns: totalTurns,
          totalTurns: totalTurns,
        ),
      );
}

DomainActionState _expectedWorkerActions(
  ReducerParityFixture fixture,
  String unitId,
) {
  final actions = fixture.state.actions;
  final pending = actions.pendingAction;
  final clearsMatchingPending =
      fixture.command is SelectWorkerImprovementCommand ||
      fixture.command is ConfirmWorkerImprovementCommand ||
      fixture.command is AssignWorkerToHexCommand;
  if (clearsMatchingPending &&
      pending is PendingWorkerActionSelection &&
      pending.ownerPlayerId == fixture.actorPlayerId &&
      pending.unitId == unitId) {
    return actions.copyWith(pendingAction: null);
  }
  return actions;
}

String _workerCommandUnitId(DomainCommand command) =>
    command is UnitDomainCommand ? command.unitId : '';

bool _sameWorkerUnitOrder(List<GameUnit> before, List<GameUnit> after) {
  if (before.length != after.length) return false;
  for (var index = 0; index < before.length; index++) {
    if (before[index].id != after[index].id) return false;
  }
  return true;
}

bool _unrelatedWorkerUnitsPreserved(
  DomainState before,
  DomainState after,
  String workerId,
) {
  for (var index = 0; index < before.units.length; index++) {
    if (before.units[index].id == workerId) continue;
    if (after.units[index] != before.units[index]) return false;
  }
  return true;
}
