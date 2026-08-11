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
    final updatedCities = List<GameCity>.of(cities);
    final updatedUnits = List<GameUnit>.of(units);
    var updatedImprovements = List<FieldImprovement>.of(fieldImprovements);
    var updatedTransport = transportNetwork;
    var changed = false;

    for (var i = 0; i < updatedUnits.length; i++) {
      final unit = updatedUnits[i];
      if (unit.ownerPlayerId != playerId) continue;

      final job = unit.workerJob;
      if (job == null) continue;

      changed = true;

      final tile = mapData.tileAt(job.targetHex.col, job.targetHex.row);
      final hasExistingImprovement = updatedImprovements.any(
        (improvement) => improvement.hex == job.targetHex,
      );
      final jobTargetInvalid = switch (job.kind) {
        WorkerJobKind.fieldImprovement => hasExistingImprovement,
        WorkerJobKind.roadConstruction =>
          updatedTransport.at(job.targetHex.col, job.targetHex.row) != null,
      };
      if (!unit.occupies(job.targetHex.col, job.targetHex.row) ||
          tile == null ||
          jobTargetInvalid) {
        updatedUnits[i] = unit.copyWithWorkerJob(null).copyWithQueuedPath(null);
        continue;
      }

      if (job.remainingTurns > 1) {
        updatedUnits[i] = unit.copyWithWorkerJob(
          job.copyWith(remainingTurns: job.remainingTurns - 1),
        );
        continue;
      }

      switch (job.kind) {
        case WorkerJobKind.fieldImprovement:
          final city = WorkerImprovementRules.cityForImprovementHex(
            playerId: unit.ownerPlayerId,
            hex: job.targetHex,
            cities: updatedCities,
          );
          if (city == null) {
            updatedUnits[i] = unit
                .copyWithWorkerJob(null)
                .copyWithQueuedPath(null);
            continue;
          }
          updatedImprovements = [
            ...updatedImprovements,
            FieldImprovement(
              hex: job.targetHex,
              type: job.improvementType!,
              builtByCityId: city.id,
            ),
          ];
          final remainingCharges =
              WorkerImprovementChargeRules.remainingAfterImprovement(
                unit.workerBuildCharges,
              );
          if (remainingCharges <= 0) {
            updatedUnits.removeAt(i);
            i -= 1;
          } else {
            updatedUnits[i] = unit
                .copyWithWorkerJob(null)
                .copyWithQueuedPath(null)
                .copyWithWorkerBuildCharges(remainingCharges);
          }
        case WorkerJobKind.roadConstruction:
          final legality = RoadConstructionRules.evaluate(
            unit: unit,
            cities: updatedCities,
            network: updatedTransport,
            mapTiles: mapData,
            requireReadyWorker: false,
          );
          if (!legality.allowed) {
            updatedUnits[i] = unit
                .copyWithWorkerJob(null)
                .copyWithQueuedPath(null);
            continue;
          }
          final cityId = _ownedCityIdAt(
            playerId: unit.ownerPlayerId,
            hex: job.targetHex,
            cities: updatedCities,
          );
          updatedTransport = updatedTransport.put(
            TransportSegment(
              hex: HexCoord(col: job.targetHex.col, row: job.targetHex.row),
              builtByPlayerId: unit.ownerPlayerId,
              builtByCityId: cityId,
            ),
          );
          updatedUnits[i] = unit
              .copyWithWorkerJob(null)
              .copyWithQueuedPath(null);
      }
    }

    return WorkerTurnBatchResult(
      cities: List<GameCity>.unmodifiable(updatedCities),
      units: List<GameUnit>.unmodifiable(updatedUnits),
      fieldImprovements: List<FieldImprovement>.unmodifiable(
        updatedImprovements,
      ),
      transportNetwork: updatedTransport,
      changed: changed,
    );
  }

  static String? _ownedCityIdAt({
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
}
