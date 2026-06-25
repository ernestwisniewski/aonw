import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/civilization/tech_branch_preferences.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/scoring.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/technology_branch_classifier.dart';
import 'package:aonw_core/ai/technology_persona_scorer.dart';
import 'package:aonw_core/ai/technology_score_snapshot.dart';
import 'package:aonw_core/ai/technology_state_scorer.dart';
import 'package:aonw_core/game/domain/technology.dart';

class AiTechnologyScoreInput {
  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final StrategicMode? mode;

  const AiTechnologyScoreInput({
    required this.view,
    required this.context,
    required this.assessment,
    this.mode,
  });
}

class AiTechnologyScorer
    implements Scorer<TechnologyId, AiTechnologyScoreInput> {
  const AiTechnologyScorer({
    this.personaScorer = const AiTechnologyPersonaScorer(),
    this.stateScorer = const AiTechnologyStateScorer(),
  });

  final AiTechnologyPersonaScorer personaScorer;
  final AiTechnologyStateScorer stateScorer;

  @override
  ScoreBreakdown score(TechnologyId candidate, AiTechnologyScoreInput context) {
    return scoreTechnologyBreakdown(
      view: context.view,
      id: candidate,
      context: context.context,
      assessment: context.assessment,
      mode: context.mode,
    );
  }

  TechnologyId? pickTechnology({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    StrategicMode? mode,
  }) {
    final ranked = rankTechnologies(
      view: view,
      context: context,
      assessment: assessment,
      mode: mode,
    );
    return ranked.isEmpty ? null : ranked.first;
  }

  List<TechnologyId> rankTechnologies({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    StrategicMode? mode,
  }) {
    if (view.availableTechnologyIds.isEmpty) return const [];
    final snapshot = AiTechnologyScoreSnapshot.from(view);
    final effectiveMode = mode ?? context.strategicPlan?.mode;
    final candidates = [...view.availableTechnologyIds];
    final scores = <TechnologyId, double>{
      for (final id in candidates)
        id: _scoreWithSnapshot(
          view: view,
          id: id,
          context: context,
          assessment: assessment,
          snapshot: snapshot,
          mode: effectiveMode,
        ),
    };

    candidates.sort((a, b) {
      final scoreCompare = scores[b]!.compareTo(scores[a]!);
      if (scoreCompare != 0) return scoreCompare;
      return compareTechnologyOrder(view, a, b);
    });
    return List.unmodifiable(candidates);
  }

  double scoreTechnology({
    required GameView view,
    required TechnologyId id,
    required AiContext context,
    required AiEmpireAssessment assessment,
    StrategicMode? mode,
  }) {
    return scoreTechnologyBreakdown(
      view: view,
      id: id,
      context: context,
      assessment: assessment,
      mode: mode,
    ).total;
  }

  ScoreBreakdown scoreTechnologyBreakdown({
    required GameView view,
    required TechnologyId id,
    required AiContext context,
    required AiEmpireAssessment assessment,
    StrategicMode? mode,
  }) {
    return _scoreBreakdownWithSnapshot(
      view: view,
      id: id,
      context: context,
      assessment: assessment,
      snapshot: AiTechnologyScoreSnapshot.from(view),
      mode: mode ?? context.strategicPlan?.mode,
    );
  }

  static int compareTechnologyOrder(
    GameView view,
    TechnologyId a,
    TechnologyId b,
  ) {
    final aPosition = view.ruleset.technology.definitionFor(a).treePosition;
    final bPosition = view.ruleset.technology.definitionFor(b).treePosition;
    final columnCompare = aPosition.column.compareTo(bPosition.column);
    if (columnCompare != 0) return columnCompare;
    final rowCompare = aPosition.row.compareTo(bPosition.row);
    if (rowCompare != 0) return rowCompare;
    return a.name.compareTo(b.name);
  }

  static TechBranch branchFor(TechnologyId id) {
    return const AiTechnologyBranchClassifier().branchFor(id);
  }

  double _scoreWithSnapshot({
    required GameView view,
    required TechnologyId id,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiTechnologyScoreSnapshot snapshot,
    required StrategicMode? mode,
  }) {
    return _scoreBreakdownWithSnapshot(
      view: view,
      id: id,
      context: context,
      assessment: assessment,
      snapshot: snapshot,
      mode: mode,
    ).total;
  }

  ScoreBreakdown _scoreBreakdownWithSnapshot({
    required GameView view,
    required TechnologyId id,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required AiTechnologyScoreSnapshot snapshot,
    required StrategicMode? mode,
  }) {
    final definition = view.ruleset.technology.definitionFor(id);
    final persona = personaScorer.score(
      definition: definition,
      weights: context.effectiveWeights,
      techBias: context.civProfile.techBias,
      mode: mode,
    );
    final state = stateScorer.score(
      view: view,
      definition: definition,
      context: context,
      assessment: assessment,
      snapshot: snapshot,
      mode: mode,
    );
    return ScoreBreakdown.fromComponents({'persona': persona, 'state': state});
  }
}
