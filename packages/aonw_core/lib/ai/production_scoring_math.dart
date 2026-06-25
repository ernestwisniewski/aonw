import 'package:aonw_core/ai/production_scoring_cache.dart';
import 'package:aonw_core/game/domain/city.dart';

int productionPerTurnForTarget({
  required GameCity city,
  required CityProductionTarget target,
  required AiProductionScoringCache cache,
}) {
  final economy = cache.economyFor(city);
  return CitySpecializationRules.productionPerTurnForTarget(
    productionPerTurn: CityProductionRules.productionPerTurn(
      economy.netYield.production,
    ),
    target: target,
    specialization: city.specialization,
  );
}

double productionCostPenalty(int productionCost, int productionPerTurn) {
  if (productionCost <= 0) return 0;
  if (productionPerTurn <= 0) return productionCost / 18;
  return (productionCost / productionPerTurn).ceil() * 0.18;
}
