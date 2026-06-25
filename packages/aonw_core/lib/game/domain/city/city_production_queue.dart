import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_project_type.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';

class CityProductionQueue {
  final CityProductionTarget target;
  final int investedProduction;

  CityProductionQueue.building({
    required CityBuildingType buildingType,
    required this.investedProduction,
  }) : target = BuildingProductionTarget(buildingType);

  CityProductionQueue.unit({
    required GameUnitType unitType,
    required this.investedProduction,
  }) : target = UnitProductionTarget(unitType);

  CityProductionQueue.project({
    required CityProjectType projectType,
    this.investedProduction = 0,
  }) : target = ProjectProductionTarget(projectType);

  const CityProductionQueue.target({
    required this.target,
    required this.investedProduction,
  });

  bool get isComplete => isCompleteFor(CityRulesets.standard);

  bool isCompleteFor(
    CityRuleset ruleset, {
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (target is ProjectProductionTarget) return false;
    return investedProduction >=
        CityProductionRules.targetCost(
          target,
          ruleset: ruleset,
          paceBalance: paceBalance,
        );
  }

  CityProductionQueue advancedBy(int production) {
    if (production <= 0) return this;
    return CityProductionQueue.target(
      target: target,
      investedProduction: investedProduction + production,
    );
  }

  factory CityProductionQueue.fromJson(Map<String, dynamic> json) =>
      CityProductionQueue.target(
        target: CityProductionTarget.fromJson(
          json['target'] as Map<String, dynamic>,
        ),
        investedProduction: (json['investedProduction'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'target': target.toJson(),
    'investedProduction': investedProduction,
  };

  @override
  bool operator ==(Object other) =>
      other is CityProductionQueue &&
      other.target == target &&
      other.investedProduction == investedProduction;

  @override
  int get hashCode => Object.hash(target, investedProduction);
}

abstract final class CityProductionRules {
  static const int rushGoldPerProduction = 2;

  static int targetCost(
    CityProductionTarget target, {
    CityRuleset ruleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return switch (target) {
      BuildingProductionTarget(:final buildingType) => buildingProductionCost(
        buildingType,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
      UnitProductionTarget(:final unitType) => unitProductionCost(
        unitType,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
      ProjectProductionTarget() => 0,
    };
  }

  static int buildingProductionCost(
    CityBuildingType type, {
    CityRuleset ruleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return paceBalance.buildingProductionCost(
      ruleset.buildingDefinitionFor(type).productionCost,
    );
  }

  static int unitProductionCost(
    GameUnitType type, {
    CityRuleset ruleset = CityRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return paceBalance.unitProductionCost(
      ruleset.unitDefinitionFor(type).productionCost,
    );
  }

  static bool canRush(CityProductionTarget target) {
    return target is! ProjectProductionTarget;
  }

  static int productionPerTurn(int productionYield) {
    return productionYield < 0 ? 0 : productionYield;
  }

  static int rushProductionAmount({
    required int productionCost,
    required int investedProduction,
    required int productionPerTurn,
  }) {
    final remaining = productionCost - investedProduction;
    if (remaining <= 0) return 0;
    final pace = productionPerTurn <= 0 ? 1 : productionPerTurn;
    return remaining < pace ? remaining : pace;
  }

  static int rushGoldCost({
    required int productionCost,
    required int investedProduction,
    required int productionPerTurn,
  }) {
    return rushProductionAmount(
          productionCost: productionCost,
          investedProduction: investedProduction,
          productionPerTurn: productionPerTurn,
        ) *
        rushGoldPerProduction;
  }

  static int completionOverflow({
    required int productionCost,
    required int investedProduction,
  }) {
    final overflow = investedProduction - productionCost;
    return overflow <= 0 ? 0 : overflow;
  }

  static int rolloverInvestment({
    required int storedOverflow,
    required int productionCost,
  }) {
    if (storedOverflow <= 0 || productionCost <= 1) return 0;
    final cap = productionCost ~/ 2;
    return storedOverflow < cap ? storedOverflow : cap;
  }

  static int? estimatedTurnsRemaining({
    required int productionCost,
    required int investedProduction,
    required int productionPerTurn,
  }) {
    final remaining = productionCost - investedProduction;
    if (remaining <= 0) return 0;
    if (productionPerTurn <= 0) return null;
    return (remaining / productionPerTurn).ceil();
  }

  static bool canBuild(
    Set<CityBuildingType> buildings,
    CityBuildingType type, {
    CityRuleset ruleset = CityRulesets.standard,
    bool technologyUnlocked = true,
    bool requirementsMet = true,
  }) {
    ruleset.buildingDefinitionFor(type);
    return technologyUnlocked && requirementsMet && !buildings.contains(type);
  }

  static bool canProduceUnit(
    GameUnitType type, {
    CityRuleset ruleset = CityRulesets.standard,
    bool technologyUnlocked = true,
    bool requirementsMet = true,
  }) {
    if (!technologyUnlocked ||
        !requirementsMet ||
        !type.canBeProducedByCities) {
      return false;
    }
    ruleset.unitDefinitionFor(type);
    return true;
  }
}
