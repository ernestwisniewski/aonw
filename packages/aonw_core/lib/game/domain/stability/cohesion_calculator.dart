import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/hex/hex_distance.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';

abstract final class CohesionCalculator {
  static int cityCohesionCost({
    required HexCoordinate cityCenter,
    required HexCoordinate nearestCoreCenter,
    required bool isConnected,
    required StabilityRuleset ruleset,
  }) {
    final distance = HexDistance.between(cityCenter, nearestCoreCenter);
    final beyondReach = distance - ruleset.reachRadius;
    final frontierCost = beyondReach <= 0
        ? 0
        : beyondReach * ruleset.frontierCostPerHexBeyondReach;
    final disconnectedCost = isConnected ? 0 : ruleset.disconnectedCityCost;
    return frontierCost + disconnectedCost;
  }
}
