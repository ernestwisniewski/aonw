import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability/stability_policy.dart';
import 'package:aonw_core/game/domain/turn/city_hit_point_recovery_processor.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_event_factory.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/game/domain/unit/unit_upkeep_rules.dart';
import 'package:aonw_core/game/domain/wonder/wonder_completion_resolver.dart';

abstract final class TurnCityEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required String playerId,
    required TurnEconomyContext context,
  }) {
    final cityTurn = _advanceCityRules(state, playerId, context);
    final wonder = WonderCompletionResolver.resolveCompletedForPlayer(
      playerId: playerId,
      cities: cityTurn.cities,
      registry: state.wonderRegistry,
      playerGold: state.playerGold,
      research: state.research,
      ruleset: context.ruleset.wonders,
      paceBalance: context.ruleset.paceBalance,
    );
    final nextCities = CityHitPointRecoveryProcessor.recoverForPlayer(
      cities: wonder.cities,
      artifacts: state.artifacts,
      events: context.priorEvents,
      combatRuleset: context.ruleset.combat,
      playerId: playerId,
    );
    final upkeep = UnitUpkeepRules.forPlayer(
      playerId: playerId,
      units: cityTurn.units,
      cities: nextCities,
    );
    return TurnEconomyResult(
      state: state.copyWith(
        units: List.unmodifiable(cityTurn.units),
        cities: nextCities,
        fieldImprovements: List.unmodifiable(cityTurn.fieldImprovements),
        playerGold: _addGoldDelta(
          wonder.playerGold,
          playerId,
          cityTurn.goldGained - upkeep.total,
        ),
        research: wonder.research,
        wonderRegistry: wonder.registry,
      ),
      events: [
        ...TurnEconomyEventFactory.fromCityTurn(
          previousCities: state.cities,
          cityEvents: cityTurn.events,
          updatedCities: nextCities,
        ),
        ...wonder.events,
      ],
      scienceGained: cityTurn.scienceGained,
    );
  }

  static CityTurnBatchResult _advanceCityRules(
    TurnEconomyState state,
    String playerId,
    TurnEconomyContext context,
  ) {
    return CityTurnProcessor.advanceForPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: context.mapData.mapTiles,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: context.ruleset.city,
      research: state.research,
      technologyRuleset: context.ruleset.technology,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: context.ruleset.wonders,
      stabilityModifier: StabilityPolicy.modifierForNet(
        state.playerStabilityNet[playerId] ?? 0,
        ruleset: context.ruleset.stability,
      ),
      paceBalance: context.ruleset.paceBalance,
    );
  }

  static Map<String, int> _addGoldDelta(
    Map<String, int> playerGold,
    String playerId,
    int amount,
  ) {
    if (playerId.isEmpty || amount == 0) return playerGold;
    final nextGold = (playerGold[playerId] ?? 0) + amount;
    return {...playerGold, playerId: nextGold < 0 ? 0 : nextGold};
  }
}
