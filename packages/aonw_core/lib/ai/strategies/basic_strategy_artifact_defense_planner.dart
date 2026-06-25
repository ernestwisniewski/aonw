import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_defense_movement.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class BasicStrategyArtifactDefensePlanner {
  const BasicStrategyArtifactDefensePlanner({
    this.defenseMovement = const BasicStrategyDefenseMovement(),
  });

  final BasicStrategyDefenseMovement defenseMovement;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    final artifactCities = _ownArtifactCities(view);
    if (artifactCities.length < 4) return const [];

    final commands = <GameCommand>[];
    final occupied = <String>{
      for (final unit in view.ownUnits) _key(unit.col, unit.row),
      for (final unit in view.visibleEnemyUnits) _key(unit.col, unit.row),
      for (final hex in reservedHexes) _key(hex.col, hex.row),
    };
    final pathfinder = UnitMovementPathfinder(
      mapData: context.mapData,
      units: view.movementBlockingUnits,
      canEnterTile: (tile) =>
          view.visibility.canSeeDynamicAt(tile.col, tile.row) &&
          !occupied.contains(_key(tile.col, tile.row)),
    );
    final units = [
      for (final unit in view.ownUnits)
        if (!usedUnitIds.contains(unit.id) &&
            !unit.isCarryingArtifact &&
            defenseMovement.canHold(unit, context.ruleset.combat))
          unit,
    ];
    final guardedCityIds = {
      for (final city in artifactCities)
        if (units.any((unit) => defenseMovement.isInArea(unit, city))) city.id,
    };

    for (final city in artifactCities) {
      if (guardedCityIds.contains(city.id)) continue;
      final availableUnits = [
        for (final unit in units)
          if (!usedUnitIds.contains(unit.id)) unit,
      ];
      final move = _nearestArtifactDefenseMove(
        city: city,
        units: availableUnits,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move == null) continue;
      commands.add(move.command);
      usedUnitIds.add(move.command.unitId);
      occupied
        ..remove(_key(move.origin.col, move.origin.row))
        ..addAll(move.reservedHexes.map((hex) => _key(hex.col, hex.row)));
      reservedHexes.addAll(move.reservedHexes);
      if (commands.length >= 3) break;
    }

    return List.unmodifiable(commands);
  }

  _ArtifactDefenseMove? _nearestArtifactDefenseMove({
    required GameCity city,
    required List<GameUnit> units,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final candidates = <_ArtifactDefenseMove>[];
    for (final unit in units) {
      final move = defenseMovement.moveFor(
        unit: unit,
        city: city,
        view: view,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move == null) continue;
      candidates.add(
        _ArtifactDefenseMove(
          command: move.command,
          origin: HexCoordinate(col: unit.col, row: unit.row),
          reservedHexes: move.reservedHexes,
          distance: HexDistance.between(
            HexCoordinate(col: unit.col, row: unit.row),
            city.center.toCoordinate(),
          ),
        ),
      );
    }
    candidates.sort((a, b) {
      final distance = a.distance.compareTo(b.distance);
      if (distance != 0) return distance;
      return a.command.unitId.compareTo(b.command.unitId);
    });
    return candidates.isEmpty ? null : candidates.first;
  }

  List<GameCity> _ownArtifactCities(GameView view) {
    final cityById = {for (final city in view.ownCities) city.id: city};
    final cities = <GameCity>[];
    final seen = <String>{};
    for (final artifact in view.artifacts) {
      final cityId = artifact.location.cityId;
      if (!artifact.location.isStored || cityId == null) continue;
      final city = cityById[cityId];
      if (city != null && seen.add(city.id)) cities.add(city);
    }
    cities.sort((a, b) => a.id.compareTo(b.id));
    return cities;
  }

  String _key(int col, int row) => '$col:$row';
}

final class _ArtifactDefenseMove {
  const _ArtifactDefenseMove({
    required this.command,
    required this.origin,
    required this.reservedHexes,
    required this.distance,
  });

  final MoveUnitCommand command;
  final HexCoordinate origin;
  final Set<HexCoordinate> reservedHexes;
  final int distance;
}
