import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class AiEmpireAssessment {
  final String playerId;
  final int cityCount;
  final int workerCount;
  final int settlerCount;
  final int militaryCount;
  final int visibleEnemyMilitaryCount;
  final int goldReserve;
  final int netGoldPerTurn;
  final int desiredCityCount;
  final int desiredWorkerCount;
  final int desiredMilitaryCount;

  const AiEmpireAssessment({
    required this.playerId,
    required this.cityCount,
    required this.workerCount,
    required this.settlerCount,
    required this.militaryCount,
    required this.visibleEnemyMilitaryCount,
    required this.goldReserve,
    required this.netGoldPerTurn,
    required this.desiredCityCount,
    required this.desiredWorkerCount,
    required this.desiredMilitaryCount,
  });

  factory AiEmpireAssessment.fromView(GameView view, AiContext context) {
    final cityCount = view.ownCities.length;
    final queuedUnits = [
      for (final city in view.ownCities)
        if (city.productionQueue?.target case UnitProductionTarget(
          :final unitType,
        ))
          unitType,
    ];
    final workerCount =
        view.ownUnits.where((unit) => unit.isWorker).length +
        queuedUnits.where((type) => type == GameUnitType.worker).length;
    final settlerCount =
        view.ownUnits
            .where(
              (unit) => unit.type == GameUnitType.settler || unit.hasSettlers,
            )
            .length +
        queuedUnits.where((type) => type == GameUnitType.settler).length;
    final actualMilitaryCount = view.ownUnits
        .where((unit) => _isMilitaryUnit(unit, context))
        .length;
    final queuedMilitaryCount = queuedUnits
        .where((type) => _isMilitaryType(type, context))
        .length;
    final visibleEnemyMilitaryCount = view.visibleTargetableEnemyUnits
        .where((unit) => _isMilitaryUnit(unit, context))
        .length;

    return AiEmpireAssessment(
      playerId: view.forPlayerId,
      cityCount: cityCount,
      workerCount: workerCount,
      settlerCount: settlerCount,
      militaryCount: actualMilitaryCount + queuedMilitaryCount,
      visibleEnemyMilitaryCount: visibleEnemyMilitaryCount,
      goldReserve: view.ownGold,
      netGoldPerTurn: _netGoldPerTurn(view),
      desiredCityCount: _desiredCityCount(view, context),
      desiredWorkerCount: _desiredWorkerCount(cityCount),
      desiredMilitaryCount: _desiredMilitaryCount(view, context),
    );
  }

  bool get wantsExpansion => cityCount + settlerCount < desiredCityCount;

  bool get needsWorkers => workerCount < desiredWorkerCount;

  bool get enemyMilitaryPressure =>
      visibleEnemyMilitaryCount > militaryCount + _enemyMilitaryTolerance;

  bool get needsMilitary =>
      militaryCount < desiredMilitaryCount || enemyMilitaryPressure;

  bool get needsGoldReserve {
    final minimumReserve = 6 + cityCount * 2;
    if (netGoldPerTurn < 0) return true;
    return goldReserve <= minimumReserve && netGoldPerTurn <= 0;
  }

  static int _desiredCityCount(GameView view, AiContext context) {
    final weights = context.effectiveWeights;
    final personaTarget = weights.expansion >= 1.2 ? 3 : 2;
    final terrainRoom = _mapExpansionRoom(view.mapData.tiles.length);
    final civRoomBonus = weights.expansion >= 1.45 && terrainRoom > 0 ? 1 : 0;
    return personaTarget + terrainRoom + civRoomBonus;
  }

  static int _desiredWorkerCount(int cityCount) {
    if (cityCount <= 0) return 0;
    return cityCount;
  }

  int get _enemyMilitaryTolerance {
    if (cityCount <= 0) return 1;
    return cityCount < 2 ? 2 : cityCount;
  }

  static int _mapExpansionRoom(int tileCount) {
    if (tileCount >= 96) return 3;
    if (tileCount >= 48) return 2;
    if (tileCount >= 24) return 1;
    return 0;
  }

  static int _desiredMilitaryCount(GameView view, AiContext context) {
    if (view.ownCities.isEmpty) return 1;
    return (view.ownCities.length *
            context.effectiveWeights.aggression *
            context.civProfile.belligerence)
        .ceil();
  }

  static int _netGoldPerTurn(GameView view) {
    var cityGoldIncome = 0;
    var wealthProjectIncome = 0;
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: view.forPlayerId,
      research: ResearchState(players: {view.forPlayerId: view.ownResearch}),
      ruleset: view.ruleset.technology,
    );

    for (final city in view.ownCities) {
      final tileYield = CityYieldCalculator.totalFor(
        city,
        view.mapData,
        fieldImprovements: view.ownImprovements,
        units: view.ownUnits,
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
      cityGoldIncome += economy.netYield.gold < 0 ? 0 : economy.netYield.gold;
      if (city.productionQueue?.target case ProjectProductionTarget(
        projectType: CityProjectType.wealth,
      )) {
        wealthProjectIncome += CityProjectRules.outputFor(
          type: CityProjectType.wealth,
          productionPerTurn: CityProductionRules.productionPerTurn(
            economy.netYield.production,
          ),
        );
      }
    }

    final upkeep = UnitUpkeepRules.forPlayer(
      playerId: view.forPlayerId,
      units: view.ownUnits,
      cities: view.ownCities,
    );
    return cityGoldIncome + wealthProjectIncome - upkeep.total;
  }

  static bool _isMilitaryUnit(GameUnit unit, AiContext context) {
    return _isMilitaryType(unit.type, context);
  }

  static bool _isMilitaryType(GameUnitType unitType, AiContext context) {
    if (unitType == GameUnitType.settler || unitType == GameUnitType.worker) {
      return false;
    }
    final stats = context.ruleset.combat.baseStatsFor(unitType);
    return stats.attack > 0 || stats.defense > 0;
  }
}
