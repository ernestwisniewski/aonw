import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

bool isStaleEconomySimulationCommand({
  required GameCommand command,
  required PersistentGameState state,
  required String actorPlayerId,
  required GameRuleset ruleset,
  required MapDefinition mapDefinition,
}) {
  return _isStaleMoveCommand(command, state) ||
      _isStaleAttackCommand(
        command,
        state,
        actorPlayerId,
        ruleset,
        mapDefinition,
      );
}

bool _isStaleMoveCommand(GameCommand command, PersistentGameState state) {
  if (command is! MoveUnitCommand) return false;

  GameUnit? movingUnit;
  for (final unit in state.units) {
    if (unit.id == command.unitId) {
      movingUnit = unit;
    } else if (unit.col == command.targetCol && unit.row == command.targetRow) {
      return true;
    }
  }
  if (movingUnit == null) return false;
  return movingUnit.col == command.targetCol &&
      movingUnit.row == command.targetRow;
}

bool _isStaleAttackCommand(
  GameCommand command,
  PersistentGameState state,
  String actorPlayerId,
  GameRuleset ruleset,
  MapDefinition mapDefinition,
) {
  if (command is! AttackHexCommand) return false;

  GameUnit? attacker;
  for (final unit in state.units) {
    if (unit.id == command.attackerUnitId) {
      attacker = unit;
      break;
    }
  }
  if (attacker == null || attacker.ownerPlayerId != actorPlayerId) {
    return true;
  }
  if (attacker.isWorking) return true;

  final attackerTile = _tileDataAt(mapDefinition, attacker.col, attacker.row);
  if (attackerTile == null) return true;
  final attackerResearch = state.research.forPlayer(actorPlayerId);
  final attackerBaseStats = UnitCombatStats.derive(
    attacker,
    ruleset: ruleset.combat,
  );
  final targetHex = HexCoordinate(
    col: command.defenderCol,
    row: command.defenderRow,
  );
  final attackerHex = HexCoordinate(col: attacker.col, row: attacker.row);

  for (final unit in state.units) {
    if (unit.col != command.defenderCol || unit.row != command.defenderRow) {
      continue;
    }
    if (unit.ownerPlayerId == actorPlayerId) return true;

    final defenderTile = _tileDataAt(mapDefinition, unit.col, unit.row);
    final attackerEffective = attackerBaseStats.applyAll(
      CombatModifierCollector.forAttacker(
        unit: attacker,
        tile: attackerTile,
        research: attackerResearch,
        defender: unit,
        defenderTile: defenderTile,
        ruleset: ruleset.combat,
        technologyRuleset: ruleset.technology,
      ),
    );
    if (attackerEffective.attack <= 0 ||
        HexDistance.between(attackerHex, targetHex) > attackerEffective.range) {
      return true;
    }
    return _isProtectedAttack(state, actorPlayerId, unit.ownerPlayerId);
  }

  for (final city in state.cities) {
    if (city.center.col == command.defenderCol &&
        city.center.row == command.defenderRow &&
        city.ownerPlayerId != actorPlayerId) {
      final attackerEffective = attackerBaseStats.applyAll(
        CombatModifierCollector.forAttacker(
          unit: attacker,
          tile: attackerTile,
          research: attackerResearch,
          ruleset: ruleset.combat,
          technologyRuleset: ruleset.technology,
        ),
      );
      if (attackerEffective.attack <= 0 ||
          HexDistance.between(attackerHex, targetHex) >
              attackerEffective.range) {
        return true;
      }
      return _isProtectedAttack(state, actorPlayerId, city.ownerPlayerId);
    }
  }
  return true;
}

bool _isProtectedAttack(
  PersistentGameState state,
  String attackerPlayerId,
  String defenderPlayerId,
) {
  final status = state.runtimeState.diplomacy.statusBetween(
    attackerPlayerId,
    defenderPlayerId,
  );
  return status == DiplomaticRelationStatus.friendly ||
      status == DiplomaticRelationStatus.truce;
}

TileData? _tileDataAt(MapDefinition mapDefinition, int col, int row) {
  final tile = mapDefinition.tileAt(col, row);
  if (tile == null) return null;
  return TileData(
    col: tile.col,
    row: tile.row,
    terrains: tile.terrains,
    resources: tile.resources,
    height: tile.height,
  );
}
