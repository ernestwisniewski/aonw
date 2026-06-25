import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

class AiProductionYieldWeights {
  final double food;
  final double production;
  final double gold;
  final double defense;
  final double science;

  const AiProductionYieldWeights({
    required this.food,
    required this.production,
    required this.gold,
    required this.defense,
    required this.science,
  });
}

AiProductionYieldWeights productionYieldWeights({
  required CityEconomyBreakdown economy,
  required AiContext context,
  required AiEmpireAssessment assessment,
}) {
  final weights = context.effectiveWeights;
  return AiProductionYieldWeights(
    food:
        (economy.netYield.food <= 0 ? 2.2 : 1.15) +
        (weights.expansion - 1) * 0.7,
    production:
        1.25 +
        (assessment.wantsExpansion ? 0.2 : 0.0) +
        (assessment.needsMilitary ? 0.25 : 0.0),
    gold: assessment.needsGoldReserve ? 2.1 : 0.8 * weights.economy,
    defense: assessment.needsMilitary ? 1.7 : 0.75 * weights.aggression,
    science: 0.85 * weights.science,
  );
}

double weightedProductionYield(
  TileYield yield,
  AiProductionYieldWeights weights,
) {
  return yield.food * weights.food +
      yield.production * weights.production +
      yield.gold * weights.gold +
      yield.defense * weights.defense;
}
