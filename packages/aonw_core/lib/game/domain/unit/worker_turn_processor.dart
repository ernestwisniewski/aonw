import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/city/worker_improvement_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/worker_improvement_charge_rules.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class WorkerTurnBatchResult {
  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<FieldImprovement> fieldImprovements;
  final bool changed;

  const WorkerTurnBatchResult({
    required this.cities,
    required this.units,
    required this.fieldImprovements,
    required this.changed,
  });
}

abstract final class WorkerTurnProcessor {
  static WorkerTurnBatchResult advanceForPlayer({
    required String playerId,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<FieldImprovement> fieldImprovements,
    required MapData mapData,
  }) {
    final updatedCities = List<GameCity>.of(cities);
    final updatedUnits = List<GameUnit>.of(units);
    var updatedImprovements = List<FieldImprovement>.of(fieldImprovements);
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
      if (!unit.occupies(job.targetHex.col, job.targetHex.row) ||
          tile == null ||
          hasExistingImprovement) {
        updatedUnits[i] = unit.copyWithWorkerJob(null).copyWithQueuedPath(null);
        continue;
      }

      if (job.remainingTurns > 1) {
        updatedUnits[i] = unit.copyWithWorkerJob(
          job.copyWith(remainingTurns: job.remainingTurns - 1),
        );
        continue;
      }

      final city = WorkerImprovementRules.cityForImprovementHex(
        playerId: unit.ownerPlayerId,
        hex: job.targetHex,
        cities: updatedCities,
      );
      if (city == null) {
        updatedUnits[i] = unit.copyWithWorkerJob(null).copyWithQueuedPath(null);
        continue;
      }

      updatedImprovements = [
        ...updatedImprovements,
        FieldImprovement(
          hex: job.targetHex,
          type: job.improvementType,
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
    }

    return WorkerTurnBatchResult(
      cities: List<GameCity>.unmodifiable(updatedCities),
      units: List<GameUnit>.unmodifiable(updatedUnits),
      fieldImprovements: List<FieldImprovement>.unmodifiable(
        updatedImprovements,
      ),
      changed: changed,
    );
  }
}
