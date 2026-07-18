part of 'reducer_parity_fixture.dart';

bool _permitsReviewedUnitActionPendingAction(ReducerParityFixture fixture) {
  final pendingAction = fixture.state.runtimeState.pendingAction;
  return fixture.family == 'unit-actions' &&
      fixture.expectedAccepted &&
      switch (fixture.command) {
        CancelUnitActionCommand(:final unitId) =>
          pendingAction is PendingUnitTurnSkip &&
              pendingAction.unitId == unitId,
        FortifyUnitCommand(:final unitId) =>
          pendingAction != null && !pendingAction.ownsUnit(unitId),
        _ => false,
      };
}

String _unitActionAcceptanceMode(ReducerParityFixture fixture) {
  final pendingAction = fixture.state.runtimeState.pendingAction;
  return switch (fixture.command) {
    final CancelUnitActionCommand command
        when pendingAction is PendingUnitTurnSkip &&
            pendingAction.unitId == command.unitId =>
      'cancel-skipped',
    final CancelUnitActionCommand command
        when fixture.state.units.byId(command.unitId)?.cityFoundingJob !=
                null &&
            fixture.state.units.byId(command.unitId)?.merchantTradeRoute !=
                null =>
      'cancel-active-orders',
    SkipUnitTurnCommand() => 'skip',
    final FortifyUnitCommand command
        when pendingAction != null && !pendingAction.ownsUnit(command.unitId) =>
      'fortify-unrelated-pending',
    _ => 'unexpected',
  };
}

void _requireUnitActionAcceptanceCoverage(
  _ReducerParityCorpusSummary summary,
  String family,
) {
  if (!summary.unitActionAcceptanceModes.containsAll(const {
    'cancel-skipped',
    'cancel-active-orders',
    'skip',
    'fortify-unrelated-pending',
  })) {
    throw StateError(
      '$family needs accepted cancel-skipped, cancel-active-orders, skip, '
      'and fortify-unrelated-pending fixtures.',
    );
  }
}

void _requireAcceptedParityUnitAction(
  ReducerParityFixture fixture,
  PersistentGameState state,
  List<GameEvent> events,
) {
  if (!_jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save)) ||
      events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata without emitting events',
    );
  }
  final failure = validateAcceptedUnitActionCommand(
    command: fixture.command,
    before: fixture.state,
    after: state,
    events: events,
  );
  if (failure != null) ReducerParityCorpus._fail(fixture, failure);
}
