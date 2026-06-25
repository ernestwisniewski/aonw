import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/production_scorer.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';

final class BasicStrategyProductionPlanner {
  const BasicStrategyProductionPlanner({
    this.scorer = const AiProductionScorer(),
  });

  final AiProductionScorer scorer;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    AiEmpireAssessment assessment, {
    required bool hasPlannedResearch,
  }) {
    if (view.citiesWithReassignableProduction.isEmpty) return const [];

    var planState = AiProductionPlanState.fromAssessment(
      assessment,
      hasPlannedResearch: hasPlannedResearch,
      cities: view.ownCities,
      reconCount: _reconCount(view),
    );
    final cities = [...view.citiesWithReassignableProduction]
      ..sort((a, b) => a.id.compareTo(b.id));
    final commands = <GameCommand>[];

    for (final city in cities) {
      final recommendation = scorer.recommend(
        city: city,
        view: view,
        context: context,
        assessment: assessment,
        planState: planState,
      );
      planState = planState.afterReplacing(
        city.productionQueue?.target,
        recommendation.target,
      );
      if (city.productionQueue?.target == recommendation.target) continue;
      commands.add(_commandFor(city.id, recommendation.target));
    }

    return List.unmodifiable(commands);
  }

  GameCommand _commandFor(String cityId, CityProductionTarget target) {
    return switch (target) {
      UnitProductionTarget(:final unitType) => StartUnitProductionCommand(
        cityId,
        unitType,
      ),
      BuildingProductionTarget(:final buildingType) => StartBuildingCommand(
        cityId,
        buildingType,
      ),
      ProjectProductionTarget(:final projectType) => StartCityProjectCommand(
        cityId,
        projectType,
      ),
    };
  }

  int _reconCount(GameView view) {
    return view.ownUnits.where(AiUnitRoles.isReconUnit).length +
        view.ownCities.where((city) {
          final target = city.productionQueue?.target;
          return target is UnitProductionTarget &&
              AiUnitRoles.isReconType(target.unitType);
        }).length;
  }
}
