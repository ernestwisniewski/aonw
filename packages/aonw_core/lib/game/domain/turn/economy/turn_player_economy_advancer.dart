import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';

import 'package:aonw_core/game/domain/turn/economy/turn_artifact_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_city_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_city_founding_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_science.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_research_economy_advancer.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_worker_economy_advancer.dart';

abstract final class TurnPlayerEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required String playerId,
    required TurnEconomyContext context,
  }) {
    final city = TurnCityEconomyAdvancer.advance(
      state: state,
      playerId: playerId,
      context: context,
    );
    final research = TurnResearchEconomyAdvancer.advance(
      state: city.state,
      playerId: playerId,
      context: context,
      bonusScience: city.scienceGained,
    );
    final worker = TurnWorkerEconomyAdvancer.advance(
      state: research.state,
      playerId: playerId,
      context: context,
    );
    final founding = TurnCityFoundingEconomyAdvancer.advance(
      state: worker.state,
      playerId: playerId,
      context: context,
    );
    final artifact = TurnArtifactEconomyAdvancer.advance(
      state: founding.state,
      playerId: playerId,
    );
    return TurnEconomyResult(
      state: artifact.state,
      events: [
        ...city.events,
        ...research.events,
        ...worker.events,
        ...founding.events,
        ...artifact.events,
      ],
      scienceGained: city.scienceGained,
    );
  }
}

abstract final class TurnPlayerEconomyBatchAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required TurnEconomyContext context,
  }) {
    var current = state;
    final events = <GameEvent>[];
    var science = ScienceYieldBreakdown.empty;
    for (final playerId in context.playerIds) {
      final player = TurnPlayerEconomyAdvancer.advance(
        state: current,
        playerId: playerId,
        context: context,
      );
      current = player.state;
      events.addAll(player.events);
      science = TurnEconomyScience.combine(science, player.scienceGained);
    }
    return TurnEconomyResult(
      state: current,
      events: events,
      scienceGained: science,
    );
  }
}
