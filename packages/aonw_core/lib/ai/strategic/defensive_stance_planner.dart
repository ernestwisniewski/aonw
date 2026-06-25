import 'dart:math' as math;

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/rival_snapshot.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/threat_assessor.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'defensive_stance_garrison_assignment.dart';
part 'defensive_stance_planning_engine.dart';
part 'defensive_stance_policies.dart';
part 'defensive_stance_threat_profiles.dart';

class DefensiveStancePlanner {
  static const int defaultThreatRange = 5;

  const DefensiveStancePlanner({this.threatRange = defaultThreatRange});

  final int threatRange;

  DefensiveStancePlan compute({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<PlayerThreatScore> threats,
    required StrategicMode mode,
  }) {
    return _DefensiveStancePlanningEngine(threatRange: threatRange).compute(
      view: view,
      context: context,
      assessment: assessment,
      threats: threats,
      mode: mode,
    );
  }
}
