import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';

/// Stability terms used by the MCTS evaluators: the state-level band score
/// and the order-building production bonus.
abstract final class MctsStabilityScores {
  static double stateScore(SimulatedState state, AiContext? context) {
    if (context == null) return 0.0;
    final view = state.view;
    final forPlayerId = view.forPlayerId;
    if (forPlayerId.isEmpty) return 0.0;
    final ruleset = context.ruleset.stability;
    // Project the AI's own empire into a minimal state and reuse the real
    // calculator so the heuristic tracks the same net the turn processor
    // caches. Luxuries are skipped to keep this off the per-tile scan on the
    // hot path.
    final projectedState = PersistentGameState(
      playerWarWeariness: {forPlayerId: view.ownWarWeariness},
      cities: state.ownCities,
      artifacts: view.artifacts,
      research: ResearchState(players: {forPlayerId: state.ownResearch}),
    );
    final inputs = StabilityInputBuilder.forPlayer(
      state: projectedState,
      playerId: forPlayerId,
      mapData: context.mapData,
      ruleset: ruleset,
      includeLuxuries: false,
    );
    final net = StabilityCalculator.calculate(
      inputs: inputs,
      ruleset: ruleset,
    ).net;
    return switch (StabilityPolicy.bandFor(net, ruleset: ruleset)) {
      StabilityBand.content => 0.5,
      StabilityBand.stable => 0.0,
      StabilityBand.strained => -0.6,
      StabilityBand.unrest => -1.0,
    };
  }

  static double buildingScore(
    CityBuildingType buildingType,
    SimulatedState state,
  ) {
    const base = 0.11;
    if (!StabilitySourceCatalog.orderBuildings.contains(buildingType)) {
      return base;
    }
    return base +
        switch (StabilityPolicy.bandFor(
          state.view.ownStabilityNet,
          ruleset: state.view.ruleset.stability,
        )) {
          StabilityBand.content => 0.0,
          StabilityBand.stable => 0.02,
          StabilityBand.strained => 0.10,
          StabilityBand.unrest => 0.18,
        };
  }
}
