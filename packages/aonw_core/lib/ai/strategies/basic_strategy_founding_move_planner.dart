import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/city_founding_safety.dart';
import 'package:aonw_core/ai/city_site_scorer.dart';
import 'package:aonw_core/ai/frontier_exploration_scorer.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_military_awareness.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'basic_strategy_founding_move_candidates.dart';
part 'basic_strategy_founding_move_queries.dart';
part 'basic_strategy_founding_safety_policy.dart';

const _veryFarEnemyDistance = 1 << 20;
const _unreachableDistance = 1 << 30;

final class BasicStrategyFoundingMovePlanner {
  const BasicStrategyFoundingMovePlanner({
    this.frontierScorer = const AiFrontierExplorationScorer(),
    this.militaryAwareness = const BasicStrategyMilitaryAwareness(),
  });

  final AiFrontierExplorationScorer frontierScorer;
  final BasicStrategyMilitaryAwareness militaryAwareness;

  _FounderSafetyPolicy get _safetyPolicy =>
      _FounderSafetyPolicy(militaryAwareness);

  BasicStrategyFoundingMovePlan? revealAssignedSiteMove({
    required GameUnit unit,
    required GameView view,
    required CityHex center,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    if (unit.movementPoints <= 0) return null;
    if (AiCityFoundingSafety.unknownCenterExclusionTiles(
      view: view,
      center: center,
    ).isEmpty) {
      return null;
    }

    final candidates = <_FounderRevealMoveCandidate>[];
    for (final move in _reachableImmediateMoves(
      unit: unit,
      view: view,
      occupied: occupied,
      pathfinder: pathfinder,
    )) {
      if (!isFounderMoveSafe(target: move.target, view: view)) continue;
      if (_safetyPolicy.shouldWaitForEscort(
        current: unit.hex,
        target: move.target,
        view: view,
        requireDestinationEscort: view.ownCities.length >= 2,
      )) {
        continue;
      }

      final observer = unit.copyWith(col: move.tile.col, row: move.tile.row);
      final revealGain =
          AiCityFoundingSafety.revealableUnknownCenterExclusionTileCount(
            view: view,
            center: center,
            observer: observer,
          );
      if (revealGain <= 0) continue;

      final centerDistance = HexDistance.between(
        move.target,
        center.toCoordinate(),
      );
      candidates.add(
        _FounderRevealMoveCandidate(
          move: move,
          revealGain: revealGain,
          centerDistance: centerDistance,
        ),
      );
    }

    candidates.sort();

    if (candidates.isEmpty) return null;
    return candidates.first.toPlan(unit);
  }

  BasicStrategyFoundingMovePlan? moveTowardSite({
    required GameUnit unit,
    required AiCitySiteScore site,
    required GameView view,
    required UnitMovementPathfinder pathfinder,
  }) {
    if (unit.movementPoints <= 0) return null;
    final targetTile = view.mapData.tileAt(site.center.col, site.center.row);
    if (targetTile == null) return null;

    final plan = pathfinder.plan(unit: unit, targetTile: targetTile);
    if (plan == null || !_canEventuallyUsePlan(unit: unit, plan: plan)) {
      return null;
    }

    final current = unit.hex;
    final target = site.center.toCoordinate();
    final fullPathSafe = _isFounderPathSafe(plan: plan, view: view);
    if (fullPathSafe) {
      if (_safetyPolicy.shouldWaitForEscort(
        current: current,
        target: target,
        view: view,
        requireDestinationEscort: view.ownCities.length >= 2,
      )) {
        return null;
      }
      return BasicStrategyFoundingMovePlan(
        command: MoveUnitCommand(unit.id, site.center.col, site.center.row),
        reservedHexes: plan.reservedHexes,
      );
    }

    final step = _furthestSafeReachableStep(plan: plan, view: view, unit: unit);
    if (step == null) return null;
    final stepTarget = HexCoordinate(col: step.col, row: step.row);
    if (_safetyPolicy.shouldWaitForEscort(
      current: current,
      target: stepTarget,
      view: view,
      requireDestinationEscort: view.ownCities.length >= 2,
    )) {
      return null;
    }
    return BasicStrategyFoundingMovePlan(
      command: MoveUnitCommand(unit.id, step.col, step.row),
      reservedHexes: {stepTarget},
    );
  }

  BasicStrategyFoundingMovePlan? retreatMove({
    required GameUnit unit,
    required GameView view,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
  }) {
    if (unit.movementPoints <= 0) return null;
    final currentThreat = _safetyPolicy.visibleEnemyMilitaryDistance(
      unit.hex,
      view,
    );
    if (!_safetyPolicy.shouldRetreatFrom(currentThreat, view)) return null;

    final candidates = <_FounderRetreatCandidate>[];
    for (final move in _reachableImmediateMoves(
      unit: unit,
      view: view,
      occupied: occupied,
      pathfinder: pathfinder,
      requireVisibleDestination: true,
    )) {
      final candidate = _retreatCandidateFor(
        move: move,
        currentThreat: currentThreat!,
        view: view,
      );
      if (candidate != null) candidates.add(candidate);
    }

    candidates.sort();

    if (candidates.isEmpty) return null;
    return candidates.first.toPlan(unit);
  }

  BasicStrategyFoundingMovePlan? frontierMove({
    required GameUnit unit,
    required GameView view,
    required AiContext context,
    required Set<String> occupied,
    required UnitMovementPathfinder pathfinder,
    bool forceMove = false,
  }) {
    if (unit.movementPoints <= 0) return null;
    final citySiteDiscoveryFocus = _needsFounderLedCitySiteDiscovery(
      view: view,
      context: context,
    );
    final current = unit.hex;
    final currentScore = forceMove
        ? double.negativeInfinity
        : _foundingFrontierScore(
            current,
            view,
            citySiteDiscoveryFocus: citySiteDiscoveryFocus,
          );
    final candidates = <_FrontierMoveCandidate>[];

    for (final move in _reachableImmediateMoves(
      unit: unit,
      view: view,
      occupied: occupied,
      pathfinder: pathfinder,
    )) {
      if (!isFounderMoveSafe(target: move.target, view: view)) continue;
      if (_safetyPolicy.shouldWaitForEscort(
        current: current,
        target: move.target,
        view: view,
        requireDestinationEscort: view.ownCities.length >= 2,
      )) {
        continue;
      }
      final nearestOwnCityDistance = _nearestOwnCityDistance(move.target, view);
      if (view.ownCities.length >= 2 &&
          nearestOwnCityDistance < CityFoundingRules.minimumCenterDistance) {
        continue;
      }
      final score = _foundingFrontierScore(
        move.target,
        view,
        citySiteDiscoveryFocus: citySiteDiscoveryFocus,
      );
      if (score <= currentScore) continue;
      candidates.add(
        _FrontierMoveCandidate(
          move: move,
          score: score,
          nearestOwnCityDistance: nearestOwnCityDistance,
        ),
      );
    }

    candidates.sort();

    if (candidates.isEmpty) return null;
    return candidates.first.toPlan(unit);
  }

  bool isFounderThreatened({required GameUnit unit, required GameView view}) {
    return _safetyPolicy.isThreatened(unit.hex, view);
  }

  bool isFounderMoveSafe({
    required HexCoordinate target,
    required GameView view,
  }) {
    return _safetyPolicy.canEnter(target, view);
  }
}

final class BasicStrategyFoundingMovePlan {
  const BasicStrategyFoundingMovePlan({
    required this.command,
    required this.reservedHexes,
  });

  final MoveUnitCommand command;
  final Set<HexCoordinate> reservedHexes;
}
