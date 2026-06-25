import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class WorkerImprovementScoreBalance {
  static const foodWeight = 1000;
  static const productionWeight = 300;
  static const goldWeight = 180;
  static const defenseWeight = 80;
  static const resourceSpecialistBonus = 700;
  static const baseFoodWeight = 20;
  static const baseProductionWeight = 5;
}

abstract final class WorkerImprovementScoring {
  static int scoreFor({
    required FieldImprovementType type,
    TileData? tile,
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final baseYield = tile == null
        ? TileYield.zero
        : CityTileYieldRules.forTile(tile, ruleset: ruleset);
    return scoreForYield(type: type, baseYield: baseYield, ruleset: ruleset);
  }

  static int scoreForYield({
    required FieldImprovementType type,
    required TileYield baseYield,
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final deltaYield = FieldImprovementRules.yieldFor(type, ruleset: ruleset);
    final specialist =
        FieldImprovementRules.isResourceSpecialist(type, ruleset: ruleset)
        ? 1
        : 0;
    return scoreTileYield(deltaYield) +
        specialist * WorkerImprovementScoreBalance.resourceSpecialistBonus +
        baseYield.food * WorkerImprovementScoreBalance.baseFoodWeight +
        baseYield.production *
            WorkerImprovementScoreBalance.baseProductionWeight;
  }

  static int scoreTileYield(TileYield yield) {
    return yield.food * WorkerImprovementScoreBalance.foodWeight +
        yield.production * WorkerImprovementScoreBalance.productionWeight +
        yield.gold * WorkerImprovementScoreBalance.goldWeight +
        yield.defense * WorkerImprovementScoreBalance.defenseWeight;
  }
}
