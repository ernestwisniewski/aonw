import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/military_assessment.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class StrategyAwareMilitaryContext {
  const StrategyAwareMilitaryContext({
    this.assessment = const AiMilitaryAssessment(),
  });

  final AiMilitaryAssessment assessment;

  bool isType(GameUnitType type, AiContext context) {
    return assessment.isMilitaryTypeInContext(type, context);
  }

  bool isUnit(GameUnit unit, AiContext context) {
    return assessment.canServeAsMilitaryUnitInContext(unit, context);
  }

  bool isUnitInView(GameUnit unit, GameView view) {
    return assessment.canServeAsMilitaryUnit(unit, view.ruleset.combat);
  }

  int count(GameView view, AiContext context) {
    return assessment.ownMilitaryCount(view, context.ruleset.combat);
  }

  int countWithQueues(GameView view, AiContext context) {
    return assessment.ownMilitaryCountWithQueues(view, context.ruleset.combat);
  }

  bool isOnly(GameUnit unit, GameView view, AiContext context) {
    return assessment.isOnlyMilitaryUnit(unit, view, context.ruleset.combat);
  }

  bool lastMilitarySurvivesAttack({
    required GameUnit attacker,
    required GameUnit defender,
    required AiContext context,
  }) {
    return assessment.lastMilitarySurvivesAttack(
      attacker: attacker,
      defender: defender,
      ruleset: context.ruleset.combat,
    );
  }

  bool isSafeLastMilitaryAttack(AiAttackEvaluation evaluation) {
    return assessment.isSafeLastMilitaryAttack(evaluation);
  }
}
