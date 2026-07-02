import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/unit.dart';

/// Projects how founding a city at the command target would shift the
/// empire's stability net, and converts the projected band into a score
/// penalty for the settler rankers.
abstract final class SettlerFoundingStabilityPolicy {
  static double foundingPenalty({
    required FoundCityCommand command,
    required GameUnit founder,
    required GameView view,
  }) {
    final coreCity = CoreCityLocator.coreCityFor(
      playerId: view.forPlayerId,
      cities: view.ownCities,
    );
    if (coreCity == null) return 0.0;
    final ruleset = view.ruleset.stability;
    final center = CityHex(col: founder.col, row: founder.row);
    final cohesionCost = CohesionCalculator.cityCohesionCost(
      cityCenter: center.toCoordinate(),
      nearestCoreCenter: coreCity.center.toCoordinate(),
      isConnected: CityTerritoryRules.isConnected(
        center: center,
        controlledHexes: command.controlledHexes,
      ),
      ruleset: ruleset,
    );
    final projectedNet =
        view.ownStabilityNet - ruleset.costPerCity - cohesionCost;
    return switch (StabilityPolicy.bandFor(projectedNet, ruleset: ruleset)) {
      StabilityBand.content || StabilityBand.stable => 0.0,
      StabilityBand.strained => 50.0,
      StabilityBand.unrest => 240.0,
    };
  }
}
