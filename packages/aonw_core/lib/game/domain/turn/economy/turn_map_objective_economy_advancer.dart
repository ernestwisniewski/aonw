import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_event_factory.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';

abstract final class TurnMapObjectiveEconomyAdvancer {
  static TurnEconomyResult advance({
    required TurnEconomyState state,
    required TurnEconomyContext context,
  }) {
    final previous = state.mapObjectiveHoldStatesByObjectiveId;
    final next = context.mapObjectives.isEmpty
        ? previous
        : MapObjectiveRules.advanceHoldStates(
            objectives: context.mapObjectives,
            cities: state.cities,
            units: state.units,
            previousHoldStatesByObjectiveId: previous,
          );
    final events = context.mapObjectives.isEmpty
        ? const <MapObjectiveSecuredEvent>[]
        : TurnEconomyEventFactory.securedMapObjectives(
            objectives: context.mapObjectives,
            previous: previous,
            next: next,
          );
    final withHolds = state.copyWith(mapObjectiveHoldStatesByObjectiveId: next);
    return TurnEconomyResult(
      state: _applyGold(
        state: withHolds,
        playerIds: context.playerIds,
        objectives: context.mapObjectives,
        holds: next,
      ),
      events: events,
    );
  }

  static TurnEconomyState _applyGold({
    required TurnEconomyState state,
    required Iterable<String> playerIds,
    required Iterable<MapObjectiveDefinition> objectives,
    required Map<String, MapObjectiveHoldState> holds,
  }) {
    final eligible = playerIds.toSet();
    if (eligible.isEmpty) return state;
    final gold = Map<String, int>.from(state.playerGold);
    var changed = false;
    for (final objective in objectives) {
      final hold = holds[objective.id];
      if (objective.goldPerTurn <= 0 ||
          hold == null ||
          !eligible.contains(hold.playerId) ||
          hold.holdTurns < objective.requiredHoldTurns) {
        continue;
      }
      gold[hold.playerId] = (gold[hold.playerId] ?? 0) + objective.goldPerTurn;
      changed = true;
    }
    return changed ? state.copyWith(playerGold: Map.unmodifiable(gold)) : state;
  }
}
