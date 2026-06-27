import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_military_context.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

const _military = StrategyAwareMilitaryContext();

int distanceImprovement({
  required int fromCol,
  required int fromRow,
  required int toCol,
  required int toRow,
  required HexCoordinate target,
}) {
  final before = HexDistance.between(
    HexCoordinate(col: fromCol, row: fromRow),
    target,
  );
  final after = HexDistance.between(
    HexCoordinate(col: toCol, row: toRow),
    target,
  );
  return before - after;
}

GameUnit? ownUnitById(GameView view, String unitId) {
  return view.ownUnits.byId(unitId);
}

GameCity? ownCityById(GameView view, String cityId) {
  return view.ownCities.byId(cityId);
}

GameCity? nearestOwnCity(GameView view, int col, int row) {
  GameCity? best;
  var bestDistance = 1 << 30;
  for (final city in view.ownCities) {
    final distance = HexDistance.between(
      HexCoordinate(col: col, row: row),
      city.center.toCoordinate(),
    );
    if (distance < bestDistance ||
        (distance == bestDistance &&
            (best == null || city.id.compareTo(best.id) < 0))) {
      best = city;
      bestDistance = distance;
    }
  }
  return best;
}

int nearestOwnCityDistance(GameView view, int col, int row) {
  var best = 1 << 30;
  for (final city in view.ownCities) {
    final distance = HexDistance.between(
      HexCoordinate(col: col, row: row),
      city.center.toCoordinate(),
    );
    if (distance < best) best = distance;
  }
  return best;
}

bool isNearOwnCity(GameView view, int col, int row, int maxDistance) {
  return nearestOwnCityDistance(view, col, row) <= maxDistance;
}

GameUnit? enemyAt(GameView view, int col, int row) {
  for (final unit in view.visibleTargetableEnemyUnits) {
    if (unit.col == col && unit.row == row) return unit;
  }
  return null;
}

GameCity? enemyCityAt(GameView view, int col, int row) {
  for (final city in view.rememberedTargetableEnemyCities) {
    if (city.occupiesCenter(col, row)) return city;
  }
  return null;
}

bool visibleMilitaryNear(GameView view, int col, int row, int maxDistance) {
  final nearest = nearestVisibleMilitaryDistance(view, col, row);
  return nearest != null && nearest <= maxDistance;
}

int? nearestVisibleMilitaryDistance(GameView view, int col, int row) {
  final target = HexCoordinate(col: col, row: row);
  int? nearest;
  for (final enemy in view.visibleTargetableEnemyUnits) {
    if (!_military.isUnitInView(enemy, view)) {
      continue;
    }
    final distance = HexDistance.between(
      target,
      HexCoordinate(col: enemy.col, row: enemy.row),
    );
    if (nearest == null || distance < nearest) nearest = distance;
  }
  return nearest;
}

bool ownMilitaryNear(
  GameView view,
  int col,
  int row,
  int maxDistance,
  AiContext context,
) {
  final target = HexCoordinate(col: col, row: row);
  for (final unit in view.ownUnits) {
    if (!_military.isUnit(unit, context)) {
      continue;
    }
    if (HexDistance.between(
          target,
          HexCoordinate(col: unit.col, row: unit.row),
        ) <=
        maxDistance) {
      return true;
    }
  }
  return false;
}

bool hasAvailableReconCitySiteScout(GameView view, StrategicPlan plan) {
  for (final unit in view.ownUnits) {
    if (!isReconUnit(unit) ||
        unit.isWorking ||
        unit.movementPoints <= 0 ||
        unit.queuedPath != null) {
      continue;
    }
    if (assignedDefenseFor(plan, unit.id) != null) continue;
    if (plan.frontierClearingAssignments.containsKey(unit.id)) continue;
    if (plan.warGoals.any((goal) => goal.assignedUnitIds.contains(unit.id))) {
      continue;
    }
    return true;
  }
  return false;
}

bool isReconUnit(GameUnit unit) {
  return isReconType(unit.type);
}

bool isReconType(GameUnitType type) {
  return switch (type) {
    GameUnitType.scout ||
    GameUnitType.scoutShip ||
    GameUnitType.reconPlane => true,
    _ => false,
  };
}

bool isMilitaryBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.barracks ||
    CityBuildingType.stable ||
    CityBuildingType.trainingGrounds ||
    CityBuildingType.walls ||
    CityBuildingType.armory ||
    CityBuildingType.siegeWorkshop ||
    CityBuildingType.citadel ||
    CityBuildingType.warCollege ||
    CityBuildingType.conscriptionOffice ||
    CityBuildingType.borderFort ||
    CityBuildingType.airfield ||
    CityBuildingType.shipyard ||
    CityBuildingType.dryDock ||
    CityBuildingType.navalAcademy => true,
    _ => false,
  };
}

bool isEconomicBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.merchantHall ||
    CityBuildingType.marketplace ||
    CityBuildingType.bank ||
    CityBuildingType.workshop ||
    CityBuildingType.stonemason ||
    CityBuildingType.forge ||
    CityBuildingType.buildersGuild ||
    CityBuildingType.factory ||
    CityBuildingType.artisansGuild ||
    CityBuildingType.masterWorkshop ||
    CityBuildingType.steelworks ||
    CityBuildingType.railDepot ||
    CityBuildingType.powerPlant ||
    CityBuildingType.assemblyPlant ||
    CityBuildingType.refinery ||
    CityBuildingType.harborCustoms => true,
    _ => false,
  };
}

bool isScienceBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.archive ||
    CityBuildingType.academy ||
    CityBuildingType.university ||
    CityBuildingType.observatory ||
    CityBuildingType.laboratory ||
    CityBuildingType.reactor ||
    CityBuildingType.courthouse ||
    CityBuildingType.court ||
    CityBuildingType.ministries ||
    CityBuildingType.broadcastTower => true,
    _ => false,
  };
}

bool isGrowthBuilding(CityBuildingType type) {
  return switch (type) {
    CityBuildingType.granary ||
    CityBuildingType.waterMill ||
    CityBuildingType.storehouse ||
    CityBuildingType.housing ||
    CityBuildingType.aqueduct ||
    CityBuildingType.lighthouse ||
    CityBuildingType.apothecary ||
    CityBuildingType.publicBaths ||
    CityBuildingType.hospital => true,
    _ => false,
  };
}

String? unitIdForCommand(GameCommand command) {
  return switch (command) {
    AttackHexCommand(:final attackerUnitId) => attackerUnitId,
    MoveUnitCommand(:final unitId) => unitId,
    CancelUnitActionCommand(:final unitId) => unitId,
    FortifyUnitCommand(:final unitId) => unitId,
    FoundCityCommand(:final founderId) => founderId,
    SelectWorkerImprovementCommand(:final unitId) => unitId,
    AssignWorkerToHexCommand(:final unitId) => unitId,
    _ => null,
  };
}

StrategicDefenseAssignment? assignedDefenseFor(
  StrategicPlan plan,
  String unitId,
) {
  for (final defense in plan.defenses.values) {
    if (defense.assignedUnitIds.contains(unitId)) return defense;
  }
  return null;
}

bool needsEarlyCityDefense(
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  if (view.ownCities.isEmpty || view.ownCities.length > 2) return false;
  final militaryCount = _military.countWithQueues(view, context);
  final defenseNeedsAction = plan.defenses.values.any(
    (defense) =>
        defense.threatLevel > 0 ||
        (!defense.hasAssignedGarrison && militaryCount < view.ownCities.length),
  );
  if (defenseNeedsAction) return true;

  return view.ownCities.length == 2 &&
      visibleTargetableMilitaryNearOwnCity(view, context, 3);
}

int coreDefenseMilitaryTarget(
  GameView view,
  AiContext context,
  StrategicPlan plan,
) {
  final cityCount = view.ownCities.length;
  if (cityCount <= 0) return 0;
  final militaryCount = _military.countWithQueues(view, context);
  final activePressure =
      plan.defenses.values.any(
        (defense) =>
            defense.threatLevel > 0 ||
            (!defense.hasAssignedGarrison && militaryCount < cityCount),
      ) ||
      visibleTargetableMilitaryNearOwnCity(view, context, 3);
  if (!activePressure) return cityCount <= 1 ? 2 : cityCount;
  return switch (cityCount) {
    <= 1 => 2,
    2 => 3,
    _ => cityCount,
  };
}

bool visibleTargetableMilitaryNearOwnCity(
  GameView view,
  AiContext context,
  int maxDistance,
) {
  for (final enemy in view.visibleTargetableEnemyUnits) {
    if (!_military.isUnit(enemy, context)) {
      continue;
    }
    if (isNearOwnCity(view, enemy.col, enemy.row, maxDistance)) return true;
  }
  return false;
}

bool coreDefenseCovered(GameView view, AiContext context, StrategicPlan plan) {
  return _military.countWithQueues(view, context) >=
      coreDefenseMilitaryTarget(view, context, plan);
}

bool needsMilitaryReserve(GameView view, AiContext context) {
  if (view.ownCities.isEmpty) return false;
  return _military.count(view, context) <= 1;
}

bool needsReserveDefenderProduction(GameView view, AiContext context) {
  final defenses = context.strategicPlan?.defenses.values ?? const [];
  for (final defense in defenses) {
    if (defense.threatLevel > 0 || !defense.hasAssignedGarrison) return true;
  }
  for (final enemy in view.visibleTargetableEnemyUnits) {
    if (!_military.isUnit(enemy, context)) {
      continue;
    }
    if (isNearOwnCity(view, enemy.col, enemy.row, 3)) return true;
  }
  return false;
}
