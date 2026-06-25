import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/technology_scorer.dart';
import 'package:aonw_core/game/domain/command.dart';

final class BasicStrategyResearchPlanner {
  const BasicStrategyResearchPlanner({
    this.technologyScorer = const AiTechnologyScorer(),
  });

  final AiTechnologyScorer technologyScorer;

  List<GameCommand> plan(
    GameView view,
    AiContext context,
    AiEmpireAssessment assessment,
  ) {
    if (view.ownResearch.activeTechnologyId != null) return const [];
    final technologyId = technologyScorer.pickTechnology(
      view: view,
      context: context,
      assessment: assessment,
    );
    if (technologyId == null) return const [];
    return [SelectTechnologyCommand(view.forPlayerId, technologyId)];
  }
}
