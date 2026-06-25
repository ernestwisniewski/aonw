import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/civilization/persona_weights.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/production_counter_pressure_scorer.dart';
import 'package:aonw_core/ai/production_map_scoring.dart';
import 'package:aonw_core/ai/production_models.dart';
import 'package:aonw_core/ai/production_scoring_cache.dart';
import 'package:aonw_core/ai/production_scoring_math.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'production_unit_policies.dart';
part 'production_unit_scorecard.dart';
part 'production_unit_situation.dart';

final class AiUnitProductionScorer {
  const AiUnitProductionScorer({
    this.counterPressureScorer = const AiProductionCounterPressureScorer(),
  });

  final AiProductionCounterPressureScorer counterPressureScorer;

  double score(
    GameUnitType unitType, {
    required GameCity city,
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiProductionPlanState planState,
    required AiProductionScoringCache cache,
  }) {
    final situation = _UnitProductionSituation(
      unitType: unitType,
      city: city,
      view: view,
      context: context,
      assessment: assessment,
      planState: planState,
      cache: cache,
      counterPressureScorer: counterPressureScorer,
    );

    return _UnitProductionScorecard(situation).score();
  }
}
