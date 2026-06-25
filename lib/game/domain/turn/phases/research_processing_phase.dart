import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/technology.dart';

class ResearchProcessingPhase extends TurnPhase {
  const ResearchProcessingPhase();

  @override
  TurnContext apply(TurnContext context) {
    final state = context.state;
    final result = ResearchTurnProcessor.advanceForPlayer(
      playerId: context.playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      mapData: context.mapData,
      ruleset: context.ruleset.technology,
      cityRuleset: context.ruleset.city,
      bonusScience: context.bonusScience,
      paceBalance: context.ruleset.paceBalance,
    );

    final events = <GameEvent>[
      if (result.scienceYield.total > 0)
        ResearchPointsGainedEvent(
          playerId: context.playerId,
          points: result.scienceYield.total,
        ),
      if (result.completedTechnologyId != null)
        TechnologyResearchedEvent(
          playerId: context.playerId,
          technologyId: result.completedTechnologyId!,
        ),
    ];

    return context.copyWith(
      state: state.copyWith(research: result.research),
      events: [...context.events, ...events],
      bonusScience: ScienceYieldBreakdown.empty,
    );
  }
}
