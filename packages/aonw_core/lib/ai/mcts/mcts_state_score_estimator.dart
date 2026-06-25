import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/unit.dart';

class MctsStateScoreEstimator {
  const MctsStateScoreEstimator();

  int estimate(SimulatedState state) {
    final cities = state.ownCities;
    final units = state.ownUnits;
    final research = state.ownResearch;
    final improvements = state.view.ownImprovements;
    final gold = state.view.ownGold;

    return cities.length * EmpireScoreCalculator.cityWeight +
        _population(cities) * EmpireScoreCalculator.populationWeight +
        _territory(cities) * EmpireScoreCalculator.territoryHexWeight +
        _buildings(cities) * EmpireScoreCalculator.buildingWeight +
        _unitScore(units) +
        research.unlockedTechnologyIds.length *
            EmpireScoreCalculator.technologyWeight +
        improvements.length * EmpireScoreCalculator.improvementWeight +
        EmpireScoreCalculator.goldScoreFor(gold);
  }

  int _population(Iterable<GameCity> cities) {
    var total = 0;
    for (final city in cities) {
      total += city.population;
    }
    return total;
  }

  int _territory(Iterable<GameCity> cities) {
    var total = 0;
    for (final city in cities) {
      total += city.territoryHexCount;
    }
    return total;
  }

  int _buildings(Iterable<GameCity> cities) {
    var total = 0;
    for (final city in cities) {
      total += city.buildings.length;
    }
    return total;
  }

  int _unitScore(Iterable<GameUnit> units) {
    var total = 0;
    for (final unit in units) {
      total += EmpireScoreCalculator.unitTypeScore(unit.type);
      total += unit.experiencePoints ~/ 5;
    }
    return total;
  }
}
