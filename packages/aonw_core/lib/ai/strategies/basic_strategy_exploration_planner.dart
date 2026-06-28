import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_map_objective_planner.dart';
import 'package:aonw_core/ai/strategies/random_strategy.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class BasicStrategyExplorationPlanner {
  const BasicStrategyExplorationPlanner({
    this.fallbackStrategy = const RandomStrategy(),
    this.mapObjectivePlanner = const BasicStrategyMapObjectivePlanner(),
  });

  final AiStrategy fallbackStrategy;
  final BasicStrategyMapObjectivePlanner mapObjectivePlanner;

  AiTurnPlan plan(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
    final objectiveCommands = mapObjectivePlanner.plan(
      view,
      context,
      usedUnitIds,
      reservedHexes,
    );
    if (objectiveCommands.isNotEmpty) {
      return AiTurnPlan(
        commands: objectiveCommands,
        debug: AiDebugInfo(
          strategyId: 'map-objectives',
          notes: ['planned ${objectiveCommands.length} objective moves'],
        ),
      );
    }

    final frontierCommands = _planFrontierExploration(
      view,
      context,
      usedUnitIds,
      reservedHexes,
    );
    if (frontierCommands.isNotEmpty) {
      return AiTurnPlan(
        commands: frontierCommands,
        debug: AiDebugInfo(
          strategyId: 'frontier-exploration',
          notes: ['planned ${frontierCommands.length} frontier moves'],
        ),
      );
    }

    if (usedUnitIds.isEmpty && reservedHexes.isEmpty) {
      return fallbackStrategy.plan(view, context);
    }
    return RandomStrategy(
      excludedUnitIds: usedUnitIds,
      reservedHexes: reservedHexes,
    ).plan(view, context);
  }

  List<GameCommand> _planFrontierExploration(
    GameView view,
    AiContext context,
    Set<String> usedUnitIds,
    Set<HexCoordinate> reservedHexes,
  ) {
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
    final explorers = [
      for (final unit in view.ownUnits)
        if (_canExploreFrontier(unit, usedUnitIds)) unit,
    ]..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in explorers) {
      final move = _frontierMoveFor(
        unit: unit,
        view: view,
        context: context,
        occupied: occupied,
        pathfinder: pathfinder,
      );
      if (move == null) continue;

      commands.add(move.command);
      occupied
        ..remove(_key(unit.col, unit.row))
        ..addAll(move.reservedHexes.map((hex) => _key(hex.col, hex.row)));
      reservedHexes.addAll(move.reservedHexes);
      usedUnitIds.add(unit.id);
    }

    return List.unmodifiable(commands);
  }

  bool _canExploreFrontier(GameUnit unit, Set<String> usedUnitIds) {
    if (usedUnitIds.contains(unit.id)) return false;
    return AiUnitRoles.isMilitaryUnit(unit) && unit.isReadyToAct;
  }

  _PlannedExplorationMove? _frontierMoveFor({
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    final citySiteDiscoveryFocus =
        AiFrontierExplorationScorer.needsCitySiteDiscovery(
          view: view,
          plan: context.strategicPlan,
        ) &&
        (AiUnitRoles.isReconUnit(unit) ||
            !_hasAvailableReconFrontierExplorer(view));
    final currentScore = _frontierScore(
      HexCoordinate(col: unit.col, row: unit.row),
      view,
      citySiteDiscoveryFocus: citySiteDiscoveryFocus,
    );
    final candidates = <_ExplorationMoveCandidate>[];

    final movementCosts = pathfinder.movementCostsFrom(
      unit: unit,
      maxCost: unit.movementPoints,
    );
    for (final entry in movementCosts.entries) {
      final coords = entry.key;
      final movementCost = entry.value;
      if (occupied.contains(_key(coords.col, coords.row))) continue;
      if (!view.visibility.canSeeDynamicAt(coords.col, coords.row)) continue;
      final tile = view.mapData.tileAt(coords.col, coords.row);
      if (tile == null) continue;

      final hex = HexCoordinate.fromTile(tile);
      final score = _frontierScore(
        hex,
        view,
        citySiteDiscoveryFocus: citySiteDiscoveryFocus,
      );
      if (score <= currentScore) continue;
      candidates.add(
        _ExplorationMoveCandidate(
          tile: tile,
          score: score,
          movementCost: movementCost,
          nearestOwnCityDistance: _nearestOwnCityDistance(hex, view),
        ),
      );
    }

    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final distanceCompare = b.nearestOwnCityDistance.compareTo(
        a.nearestOwnCityDistance,
      );
      if (distanceCompare != 0) return distanceCompare;
      final costCompare = b.movementCost.compareTo(a.movementCost);
      if (costCompare != 0) return costCompare;
      final colCompare = a.tile.col.compareTo(b.tile.col);
      if (colCompare != 0) return colCompare;
      return a.tile.row.compareTo(b.tile.row);
    });

    if (candidates.isEmpty) return null;
    final candidate = candidates.first;
    final plan = pathfinder.plan(unit: unit, targetTile: candidate.tile);
    if (plan == null || plan.totalCost > unit.movementPoints) return null;
    return _PlannedExplorationMove(
      command: MoveUnitCommand(unit.id, candidate.tile.col, candidate.tile.row),
      reservedHexes: _reservedHexesFor(plan),
    );
  }

  double _frontierScore(
    HexCoordinate origin,
    GameView view, {
    bool citySiteDiscoveryFocus = false,
  }) {
    return const AiFrontierExplorationScorer().score(
      view: view,
      origin: origin,
      citySiteDiscoveryFocus: citySiteDiscoveryFocus,
    );
  }

  int _nearestOwnCityDistance(HexCoordinate origin, GameView view) {
    var nearest = 1 << 30;
    for (final city in view.ownCities) {
      final distance = HexDistance.between(origin, city.center.toCoordinate());
      if (distance < nearest) nearest = distance;
    }
    if (nearest != 1 << 30) return nearest;

    for (final unit in view.ownUnits) {
      if (CityFoundingRules.canFoundCityWith(unit)) continue;
      final distance = HexDistance.between(
        origin,
        HexCoordinate(col: unit.col, row: unit.row),
      );
      if (distance < nearest) nearest = distance;
    }
    return nearest == 1 << 30 ? 0 : nearest;
  }

  bool _hasAvailableReconFrontierExplorer(GameView view) {
    for (final unit in view.ownUnits) {
      if (AiUnitRoles.isReconUnit(unit) && unit.isReadyToAct) {
        return true;
      }
    }
    return false;
  }

  Set<HexCoordinate> _reservedHexesFor(UnitMovementPlan plan) {
    return {
      for (final step in plan.reachableSteps.skip(1))
        HexCoordinate(col: step.col, row: step.row),
    };
  }

  String _key(int col, int row) => '$col:$row';
}

final class _PlannedExplorationMove {
  const _PlannedExplorationMove({
    required this.command,
    required this.reservedHexes,
  });

  final MoveUnitCommand command;
  final Set<HexCoordinate> reservedHexes;
}

final class _ExplorationMoveCandidate {
  const _ExplorationMoveCandidate({
    required this.tile,
    required this.score,
    required this.movementCost,
    required this.nearestOwnCityDistance,
  });

  final TileData tile;
  final double score;
  final int movementCost;
  final int nearestOwnCityDistance;
}
