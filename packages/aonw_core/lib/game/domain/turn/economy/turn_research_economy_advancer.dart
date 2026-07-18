import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/technology/research_turn_processor.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/technology/strategic_resource_discovery_rules.dart';

import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnResearchEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required String playerId,
    required TurnEconomyContext context,
    required ScienceYieldBreakdown bonusScience,
  }) {
    final result = ResearchTurnProcessor.advanceForPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      mapData: context.mapData.mapTiles,
      ruleset: context.ruleset.technology,
      cityRuleset: context.ruleset.city,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: context.ruleset.wonders,
      bonusScience: bonusScience,
      paceBalance: context.ruleset.paceBalance,
    );
    final completed = result.completedTechnologyId;
    return TurnEconomyResult(
      state: state.copyWith(research: result.research),
      events: <GameEvent>[
        if (result.scienceYield.total > 0)
          ResearchPointsGainedEvent(
            playerId: playerId,
            points: result.scienceYield.total,
          ),
        if (completed != null)
          TechnologyResearchedEvent(
            playerId: playerId,
            technologyId: completed,
          ),
        if (completed != null)
          ...StrategicResourceDiscoveryRules.eventsForTechnologyFromCities(
            playerId: playerId,
            technologyId: completed,
            cities: state.cities,
            mapData: context.mapData,
          ),
      ],
    );
  }
}
