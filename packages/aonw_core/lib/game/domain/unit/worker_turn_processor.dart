import 'package:aonw_core/domain/hex_coord.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_rules.dart';
import 'package:aonw_core/game/domain/transport.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/worker_improvement_charge_rules.dart';
import 'package:aonw_core/game/domain/unit/worker_job.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class WorkerTurnBatchResult {
  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<FieldImprovement> fieldImprovements;
  final TransportNetworkState transportNetwork;
  final bool changed;

  const WorkerTurnBatchResult({
    required this.cities,
    required this.units,
    required this.fieldImprovements,
    required this.transportNetwork,
    required this.changed,
  });
}

abstract final class WorkerTurnProcessor {
  static WorkerTurnBatchResult advanceForPlayer({
    required String playerId,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    TransportNetworkState transportNetwork = TransportNetworkState.empty,
    required MapTileLookup mapData,
  }) {
    final batch = _WorkerTurnBatch(
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      transportNetwork: transportNetwork,
    );
    for (var i = 0; i < batch.units.length; i++) {
      final unit = batch.units[i];
      if (unit.ownerPlayerId != playerId) continue;
      final job = unit.workerJob;
      if (job == null) continue;
      batch.changed = true;
      if (batch.jobTargetInvalid(unit, job, mapData)) {
        batch.clearOrders(i);
        continue;
      }
      if (job.remainingTurns > 1) {
        batch.units[i] = unit.copyWithWorkerJob(
          job.copyWith(remainingTurns: job.remainingTurns - 1),
        );
        continue;
      }
      switch (job.kind) {
        case WorkerJobKind.fieldImprovement:
          if (batch.completeFieldImprovement(i, unit, job)) i -= 1;
        case WorkerJobKind.roadConstruction:
          batch.completeRoad(i, unit, job, mapData);
      }
    }
    return batch.result();
  }
}

final class _WorkerTurnBatch {
  _WorkerTurnBatch({
    required List<GameCity> cities,
    required List<GameUnit> units,
    required List<FieldImprovement> fieldImprovements,
    required this.transportNetwork,
  }) : cities = List.of(cities),
       units = List.of(units),
       fieldImprovements = List.of(fieldImprovements);

  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<FieldImprovement> fieldImprovements;
  TransportNetworkState transportNetwork;
  bool changed = false;

  bool jobTargetInvalid(GameUnit unit, WorkerJob job, MapTileLookup mapData) {
    if (!unit.occupies(job.targetHex.col, job.targetHex.row) ||
        mapData.tileAt(job.targetHex.col, job.targetHex.row) == null) {
      return true;
    }
    return switch (job.kind) {
      WorkerJobKind.fieldImprovement => fieldImprovements.any(
        (improvement) => improvement.hex == job.targetHex,
      ),
      WorkerJobKind.roadConstruction =>
        transportNetwork.at(job.targetHex.col, job.targetHex.row) != null,
    };
  }

  void clearOrders(int index) {
    units[index] = units[index]
        .copyWithWorkerJob(null)
        .copyWithQueuedPath(null);
  }

  bool completeFieldImprovement(int index, GameUnit unit, WorkerJob job) {
    final city = WorkerImprovementRules.cityForImprovementHex(
      playerId: unit.ownerPlayerId,
      hex: job.targetHex,
      cities: cities,
    );
    if (city == null) {
      clearOrders(index);
      return false;
    }
    fieldImprovements.add(
      FieldImprovement(
        hex: job.targetHex,
        type: job.improvementType!,
        builtByCityId: city.id,
      ),
    );
    final remainingCharges =
        WorkerImprovementChargeRules.remainingAfterImprovement(
          unit.workerBuildCharges,
        );
    if (remainingCharges <= 0) {
      units.removeAt(index);
      return true;
    }
    units[index] = unit
        .copyWithWorkerJob(null)
        .copyWithQueuedPath(null)
        .copyWithWorkerBuildCharges(remainingCharges);
    return false;
  }

  void completeRoad(
    int index,
    GameUnit unit,
    WorkerJob job,
    MapTileLookup mapData,
  ) {
    final legality = RoadConstructionRules.evaluate(
      unit: unit,
      cities: cities,
      network: transportNetwork,
      mapTiles: mapData,
      requireReadyWorker: false,
    );
    if (!legality.allowed) {
      clearOrders(index);
      return;
    }
    transportNetwork = transportNetwork.put(
      TransportSegment(
        hex: HexCoord(col: job.targetHex.col, row: job.targetHex.row),
        builtByPlayerId: unit.ownerPlayerId,
        builtByCityId: _ownedCityIdAt(
          playerId: unit.ownerPlayerId,
          hex: job.targetHex,
          cities: cities,
        ),
      ),
    );
    clearOrders(index);
  }

  WorkerTurnBatchResult result() {
    return WorkerTurnBatchResult(
      cities: List.unmodifiable(cities),
      units: List.unmodifiable(units),
      fieldImprovements: List.unmodifiable(fieldImprovements),
      transportNetwork: transportNetwork,
      changed: changed,
    );
  }
}

String? _ownedCityIdAt({
  required String playerId,
  required CityHex hex,
  required Iterable<GameCity> cities,
}) {
  for (final city in cities) {
    if (city.ownerPlayerId == playerId && city.controlsHex(hex)) {
      return city.id;
    }
  }
  return null;
}
