import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class BasicStrategyIdleSweepPlanner {
  const BasicStrategyIdleSweepPlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
  });

  final BasicStrategyDefenseMovement defenseMovement;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    if (view.ownUnits.isEmpty) return const [];

    final commands = <GameCommand>[];
    final localUsedUnitIds = {...usedUnitIds};
    final localReservedHexes = {...reservedHexes};
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in localReservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );
    final units = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      if (localUsedUnitIds.contains(unit.id) || !_canSweep(unit)) continue;
      final action = _idleActionFor(
        unit: unit,
        view: view,
        pathfinder: pathfinder,
        occupied: occupied,
      );
      if (action == null) continue;

      commands.add(action.command);
      localUsedUnitIds.add(unit.id);
      if (action.command case MoveUnitCommand()) {
        occupied
          ..remove(_key(unit.col, unit.row))
          ..addAll(action.reservedHexes.map((hex) => _key(hex.col, hex.row)));
        localReservedHexes.addAll(action.reservedHexes);
      }
    }

    return List.unmodifiable(commands);
  }

  bool _canSweep(GameUnit unit) {
    return unit.isReadyToAct && !unit.isFortified;
  }

  ({GameCommand command, Set<HexCoordinate> reservedHexes})? _idleActionFor({
    required GameUnit unit,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
    required Set<String> occupied,
  }) {
    final shouldHoldDefensively =
        AiUnitRoles.isMilitaryUnit(unit) || unit.isCarryingArtifact;
    if (!shouldHoldDefensively) {
      return (command: SkipUnitTurnCommand(unit.id), reservedHexes: const {});
    }

    if (_isFriendlyHoldingArea(unit, view) ||
        _standsOnDefensibleTerrain(unit, view)) {
      return (command: FortifyUnitCommand(unit.id), reservedHexes: const {});
    }

    final city = defenseMovement.nearestOwnCity(unit, view);
    if (city != null) {
      final move = defenseMovement.moveFor(
        unit: unit,
        city: city,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move != null) {
        return (command: move.command, reservedHexes: move.reservedHexes);
      }
      return (command: SkipUnitTurnCommand(unit.id), reservedHexes: const {});
    }

    return (command: FortifyUnitCommand(unit.id), reservedHexes: const {});
  }

  bool _isFriendlyHoldingArea(GameUnit unit, GameView view) {
    for (final city in view.ownCities) {
      if (defenseMovement.isInArea(unit, city)) return true;
    }
    return false;
  }

  bool _standsOnDefensibleTerrain(GameUnit unit, GameView view) {
    final tile = view.mapData.tileAt(unit.col, unit.row);
    if (tile == null) return false;
    return tile.terrains.any(
      (terrain) =>
          terrain == TerrainType.hills ||
          terrain == TerrainType.forest ||
          terrain == TerrainType.jungle ||
          terrain == TerrainType.wetlands,
    );
  }

  String _key(int col, int row) => '$col:$row';
}
