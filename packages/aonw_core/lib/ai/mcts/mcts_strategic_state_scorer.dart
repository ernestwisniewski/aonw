import 'dart:math' as math;

import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class MctsStrategicStateScorer {
  const MctsStrategicStateScorer();

  double score(SimulatedState state, PersonaWeights weights) {
    return _weightedAverage([
      _HeuristicComponent(
        value: _positiveSaturation(_cityScore(state), scale: 1.35),
        weight: weights.expansion,
      ),
      _HeuristicComponent(
        value: _positiveSaturation(_economyScore(state), scale: 0.9),
        weight: weights.economy,
      ),
      _HeuristicComponent(
        value: _militaryScore(state),
        weight: weights.aggression,
      ),
      _HeuristicComponent(
        value: _positiveSaturation(_researchScore(state), scale: 0.55),
        weight: weights.science,
      ),
      _HeuristicComponent(
        value: _positiveSaturation(_goldScore(state.view.ownGold), scale: 0.08),
        weight: weights.economy * 0.35,
      ),
    ]);
  }

  double _cityScore(SimulatedState state) {
    var score = 0.0;
    for (final city in state.ownCities) {
      score += 0.12;
      score += city.population * 0.025;
      score += city.buildings.length * 0.018;
      if (city.productionQueue != null) score += 0.012;
      if (city.specialization != null) score += 0.016;
    }
    return score;
  }

  double _economyScore(SimulatedState state) {
    final view = state.view;
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: view.forPlayerId,
      research: ResearchState(players: {view.forPlayerId: view.ownResearch}),
      ruleset: view.ruleset.technology,
    );
    var score = 0.0;
    for (final city in state.ownCities) {
      final tileYield = CityYieldCalculator.totalFor(
        city,
        view.mapData,
        fieldImprovements: view.ownImprovements,
        units: state.ownUnits,
        ruleset: view.ruleset.city,
      );
      final economy = CityEconomyBreakdown.from(
        city: city,
        tileYield: tileYield,
        mapData: view.mapData,
        ruleset: view.ruleset.city,
        paceBalance: view.ruleset.paceBalance,
        technologyEffects: technologyEffects,
      );
      score += economy.netYield.production * 0.018;
      score += economy.netYield.gold * 0.012;
      score += economy.netYield.food * 0.008;
      if (economy.willGrow) score += 0.02;
    }
    return score;
  }

  double _militaryScore(SimulatedState state) {
    final ownPower = _unitPower(
      state.ownUnits,
      ruleset: state.view.ruleset.combat,
    );
    final enemyPower = _unitPower(
      state.visibleTargetableEnemyUnits,
      ruleset: state.view.ruleset.combat,
    );
    return _tanh((ownPower - enemyPower) / 85.0);
  }

  double _researchScore(SimulatedState state) {
    final research = state.view.ownResearch;
    final progress = research.progressByTechnologyId.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return research.unlockedTechnologyIds.length * 0.035 +
        (research.activeTechnologyId == null ? 0 : 0.04) +
        progress * 0.003 +
        research.scienceOverflow * 0.002;
  }

  double _goldScore(int ownGold) {
    return (ownGold / 200).clamp(0.0, 0.08).toDouble();
  }

  double _unitPower(
    Iterable<GameUnit> units, {
    required CombatRuleset ruleset,
  }) {
    var power = 0.0;
    for (final unit in units) {
      final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
      final hp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
      power +=
          stats.attack * 2.0 +
          stats.defense * 1.4 +
          hp * 0.55 +
          stats.range * 0.6 +
          stats.mobility * 0.3;
    }
    return power;
  }

  double _positiveSaturation(double value, {required double scale}) {
    if (value <= 0) return 0.0;
    return _tanh(value / scale);
  }

  double _weightedAverage(List<_HeuristicComponent> components) {
    var weightedScore = 0.0;
    var totalWeight = 0.0;
    for (final component in components) {
      final weight = component.weight <= 0 ? 0.05 : component.weight;
      weightedScore += component.value * weight;
      totalWeight += weight;
    }
    if (totalWeight <= 0) return 0.0;
    return (weightedScore / totalWeight).clamp(-1.0, 1.0).toDouble();
  }

  double _tanh(double value) {
    final clamped = value.clamp(-20.0, 20.0).toDouble();
    final exponent = math.exp(2 * clamped);
    return (exponent - 1) / (exponent + 1);
  }
}

class _HeuristicComponent {
  final double value;
  final double weight;

  const _HeuristicComponent({required this.value, required this.weight});
}
