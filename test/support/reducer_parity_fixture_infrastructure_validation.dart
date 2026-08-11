import 'package:aonw_core/domain.dart';

import 'reducer_parity_json.dart';

String? validateAcceptedRoadInfrastructure({
  required BuildRoadCommand command,
  required GameSave save,
  required DomainState before,
  required DomainState after,
  required List<GameEvent> events,
  required Map<String, dynamic> expectedSave,
  required Map<String, dynamic> actualSave,
  required Map<String, dynamic> expectedState,
}) {
  if (!jsonDeepEquals(expectedSave, actualSave) || events.isNotEmpty) {
    return 'must preserve save metadata without emitting events';
  }

  final workerIndex = before.units.indexWhere(
    (unit) => unit.id == command.unitId,
  );
  if (workerIndex < 0 ||
      before.units.where((unit) => unit.id == command.unitId).length != 1) {
    return 'must target one existing worker';
  }

  final worker = before.units[workerIndex];
  final totalTurns = RoadConstructionRules.buildTurns(
    save.matchRules.paceBalance,
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
  final derivedState = before.copyWith(
    units: [
      for (var index = 0; index < before.units.length; index++)
        if (index == workerIndex) expectedWorker else before.units[index],
    ],
  );

  if (!jsonDeepEquals(
        expectedState,
        CanonicalGameSnapshotCodec.encodeDomainState(derivedState),
      ) ||
      !jsonDeepEquals(
        CanonicalGameSnapshotCodec.encodeDomainState(after),
        CanonicalGameSnapshotCodec.encodeDomainState(derivedState),
      )) {
    return 'must start only the independently derived road-construction job';
  }
  return null;
}
