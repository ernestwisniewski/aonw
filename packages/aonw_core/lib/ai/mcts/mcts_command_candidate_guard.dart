import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';

bool isLegalMctsCommandCandidate(
  GameCommand command,
  GameView view, {
  bool allowNonVisibleMoveTarget = false,
}) {
  return switch (command) {
    FoundCityCommand() => _canApplyFoundCityCandidate(command, view),
    AttackHexCommand() => _canApplyAttackCandidate(command, view),
    MoveUnitCommand() => _canApplyMoveCandidate(
      command,
      view,
      allowNonVisibleTarget: allowNonVisibleMoveTarget,
    ),
    _ => true,
  };
}

bool _canApplyAttackCandidate(AttackHexCommand command, GameView view) {
  final unit = view.ownUnits.byId(command.attackerUnitId);
  if (unit == null || unit.isWorking || unit.movementPoints <= 0) {
    return false;
  }
  final targetTile = view.mapData.tileAt(
    command.defenderCol,
    command.defenderRow,
  );
  if (targetTile == null) return false;
  for (final ownUnit in view.ownUnits) {
    if (ownUnit.id == unit.id) continue;
    if (ownUnit.col == command.defenderCol &&
        ownUnit.row == command.defenderRow) {
      return false;
    }
  }
  final stats = UnitCombatStats.derive(unit, ruleset: view.ruleset.combat);
  if (stats.attack <= 0) return false;
  final distance = HexDistance.between(
    HexCoordinate(col: unit.col, row: unit.row),
    HexCoordinate(col: command.defenderCol, row: command.defenderRow),
  );
  if (distance > stats.range) return false;

  for (final enemy in view.visibleEnemyUnits) {
    if (enemy.ownerPlayerId == unit.ownerPlayerId) continue;
    if (!view.canTargetPlayer(enemy.ownerPlayerId)) continue;
    if (enemy.col == command.defenderCol && enemy.row == command.defenderRow) {
      return true;
    }
  }
  for (final city in view.rememberedEnemyCities) {
    if (city.ownerPlayerId == unit.ownerPlayerId) continue;
    if (!view.canTargetPlayer(city.ownerPlayerId)) continue;
    if (city.occupiesCenter(command.defenderCol, command.defenderRow)) {
      return true;
    }
  }
  return false;
}

bool _canApplyMoveCandidate(
  MoveUnitCommand command,
  GameView view, {
  bool allowNonVisibleTarget = false,
}) {
  final unit = view.ownUnits.byId(command.unitId);
  if (unit == null || unit.isWorking || unit.movementPoints <= 0) {
    return false;
  }
  if (unit.col == command.targetCol && unit.row == command.targetRow) {
    return false;
  }

  final targetTile = view.mapData.tileAt(command.targetCol, command.targetRow);
  if (targetTile == null) return false;
  if (allowNonVisibleTarget) {
    if (!view.visibility.canInspectTile(targetTile)) return false;
  } else if (!view.visibility.canSeeDynamicAt(targetTile.col, targetTile.row)) {
    return false;
  }
  if (_isRememberedEnemyCityCenter(
    view,
    command.targetCol,
    command.targetRow,
  )) {
    return false;
  }

  final knownUnits = view.movementBlockingUnits;
  for (final other in knownUnits) {
    if (other.id == unit.id) continue;
    if (other.col == command.targetCol && other.row == command.targetRow) {
      return false;
    }
  }

  final pathfinder = UnitMovementPathfinder(
    mapData: view.mapData,
    units: knownUnits,
  );
  final plan = pathfinder.plan(unit: unit, targetTile: targetTile);
  return plan != null &&
      UnitMovementFeasibility.canEventuallyTraverse(unit: unit, plan: plan);
}

bool _canApplyFoundCityCandidate(FoundCityCommand command, GameView view) {
  final founder = view.ownUnits.byId(command.founderId);
  if (founder == null || founder.isWorking) return false;

  final cities = _knownCities(view);
  final centerTile = view.mapData.tileAt(founder.col, founder.row);
  final startFailure = CityFoundingRules.startFailure(
    unit: founder,
    centerTile: centerTile,
    cities: cities,
  );
  if (startFailure != null) return false;
  final center = CityHex(col: founder.col, row: founder.row);
  if (!AiCityFoundingSafety.hasKnownCenterExclusionZone(
    view: view,
    center: center,
  )) {
    return false;
  }

  final draft = CityFoundingDraft(
    unitId: founder.id,
    ownerPlayerId: founder.ownerPlayerId,
    center: center,
    controlledHexes: command.controlledHexes,
  );
  if (CityFoundingRules.confirmFailure(draft) != null) return false;

  final uniqueControlledHexes = command.controlledHexes.toSet();
  if (uniqueControlledHexes.length != command.controlledHexes.length) {
    return false;
  }

  for (final hex in command.controlledHexes) {
    final tile = view.mapData.tileAt(hex.col, hex.row);
    if (tile == null) return false;
    if (!CityFoundingRules.isControlledHexCandidate(
      draft: draft,
      tile: tile,
      mapData: view.mapData,
      cities: cities,
    )) {
      return false;
    }
  }

  return true;
}

List<GameCity> _knownCities(GameView view) {
  return [...view.ownCities, ...view.rememberedEnemyCities];
}

bool _isRememberedEnemyCityCenter(GameView view, int col, int row) {
  for (final city in view.rememberedEnemyCities) {
    if (city.occupiesCenter(col, row)) return true;
  }
  return false;
}
