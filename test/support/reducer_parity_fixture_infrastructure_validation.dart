part of 'reducer_parity_fixture.dart';

void _requireAcceptedParityInfrastructure(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  final command = fixture.command as BuildRoadCommand;
  if (!_jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save)) ||
      events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata without emitting events',
    );
  }

  final workerIndex = fixture.state.units.indexWhere(
    (unit) => unit.id == command.unitId,
  );
  if (workerIndex < 0 ||
      fixture.state.units.where((unit) => unit.id == command.unitId).length !=
          1) {
    ReducerParityCorpus._fail(fixture, 'must target one existing worker');
  }
  _requireWorkerSentinel(fixture, command.unitId);

  final worker = fixture.state.units[workerIndex];
  final totalTurns = RoadConstructionRules.buildTurns(
    fixture.save.matchRules.paceBalance,
  );
  final expectedWorker = worker
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(null)
      .copyWithWorkerAssignment(null)
      .copyWithPosture(UnitPosture.active)
      .copyWithWorkerJob(
        WorkerJob.roadConstruction(
          targetHex: CityHex(col: worker.col, row: worker.row),
          remainingTurns: totalTurns,
          totalTurns: totalTurns,
        ),
      );
  final expectedState = fixture.state.copyWith(
    units: [
      for (var index = 0; index < fixture.state.units.length; index++)
        if (index == workerIndex)
          expectedWorker
        else
          fixture.state.units[index],
    ],
  );

  if (!_jsonDeepEquals(
        fixture.expectedState,
        CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
      ) ||
      !_jsonDeepEquals(
        CanonicalGameSnapshotCodec.encodeDomainState(state),
        CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
      )) {
    ReducerParityCorpus._fail(
      fixture,
      'must start only the independently derived road-construction job',
    );
  }
}
