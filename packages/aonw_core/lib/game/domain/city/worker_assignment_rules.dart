import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

enum WorkerAssignmentBlocker {
  notWorker,
  workerBusy,
  noMovementPoints,
  queuedPathActive,
  missingTile,
  cityCenter,
  outsideOwnedTerritory,
  missingImprovement,
  alreadyAssigned,
  cityAssignmentLimitReached,
}

class WorkerAssignmentLegality {
  final bool allowed;
  final WorkerAssignmentBlocker? blocker;
  final GameCity? city;
  final FieldImprovement? improvement;

  const WorkerAssignmentLegality._({
    required this.allowed,
    this.blocker,
    this.city,
    this.improvement,
  });

  const WorkerAssignmentLegality.allowed({
    required GameCity city,
    required FieldImprovement improvement,
  }) : this._(allowed: true, city: city, improvement: improvement);

  const WorkerAssignmentLegality.blocked(WorkerAssignmentBlocker blocker)
    : this._(allowed: false, blocker: blocker);
}

abstract final class WorkerAssignmentRules {
  static const int bonusNumerator = 1;
  static const int bonusDenominator = 2;
  static const int baseAssignmentsPerCity = 1;
  static const int populationPerExtraAssignment = 4;

  static int maxAssignmentsForCity(GameCity city) {
    final population = city.population < 0 ? 0 : city.population;
    return baseAssignmentsPerCity + population ~/ populationPerExtraAssignment;
  }

  static WorkerAssignmentLegality evaluate({
    required GameUnit unit,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required Iterable<GameUnit> units,
    required MapData mapData,
    CityHex? targetHex,
    bool requireReadyWorker = true,
  }) {
    if (!unit.isWorker) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.notWorker,
      );
    }
    if (requireReadyWorker &&
        (unit.workerJob != null || unit.workerAssignment != null)) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.workerBusy,
      );
    }
    if (requireReadyWorker && unit.movementPoints <= 0) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.noMovementPoints,
      );
    }
    if (requireReadyWorker && unit.queuedPath != null) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.queuedPathActive,
      );
    }

    final hex = targetHex ?? CityHex(col: unit.col, row: unit.row);
    final tile = mapData.tileAt(hex.col, hex.row);
    if (tile == null) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.missingTile,
      );
    }

    GameCity? ownerCity;
    for (final city in cities) {
      if (city.ownerPlayerId != unit.ownerPlayerId) continue;
      if (city.center == hex) {
        return const WorkerAssignmentLegality.blocked(
          WorkerAssignmentBlocker.cityCenter,
        );
      }
      if (city.controlledHexes.contains(hex)) {
        ownerCity = city;
        break;
      }
    }
    if (ownerCity == null) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.outsideOwnedTerritory,
      );
    }

    FieldImprovement? improvementAtHex;
    for (final improvement in fieldImprovements) {
      if (improvement.hex == hex) {
        improvementAtHex = improvement;
        break;
      }
    }
    if (improvementAtHex == null) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.missingImprovement,
      );
    }

    for (final other in units) {
      if (other.id == unit.id) continue;
      if (other.ownerPlayerId != unit.ownerPlayerId) continue;
      if (other.workerAssignment?.targetHex == hex) {
        return const WorkerAssignmentLegality.blocked(
          WorkerAssignmentBlocker.alreadyAssigned,
        );
      }
    }

    final assignedToCity = _assignedWorkersForCity(
      ownerCity,
      units,
      excludingUnitId: unit.id,
    );
    if (assignedToCity >= maxAssignmentsForCity(ownerCity)) {
      return const WorkerAssignmentLegality.blocked(
        WorkerAssignmentBlocker.cityAssignmentLimitReached,
      );
    }

    return WorkerAssignmentLegality.allowed(
      city: ownerCity,
      improvement: improvementAtHex,
    );
  }

  static int _assignedWorkersForCity(
    GameCity city,
    Iterable<GameUnit> units, {
    required String excludingUnitId,
  }) {
    var count = 0;
    for (final unit in units) {
      if (unit.id == excludingUnitId) continue;
      if (unit.ownerPlayerId != city.ownerPlayerId) continue;
      final assignment = unit.workerAssignment;
      if (assignment == null) continue;
      final hex = assignment.targetHex;
      if (hex == city.center) continue;
      if (!city.controlsHex(hex)) continue;
      count++;
    }
    return count;
  }
}
