import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainTurnMovementResult {
  factory DomainTurnMovementResult({
    required DomainState state,
    bool changed = false,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> executions = const [],
  }) {
    return DomainTurnMovementResult._(
      state: state,
      changed: changed,
      events: events.isEmpty ? const [] : List.unmodifiable(events),
      executions: executions.isEmpty ? const [] : List.unmodifiable(executions),
    );
  }

  const DomainTurnMovementResult._({
    required this.state,
    required this.changed,
    required this.events,
    required this.executions,
  });

  final DomainState state;
  final bool changed;
  final List<GameEvent> events;
  final List<MovementCommandExecution> executions;
}

/// Canonical-state adapter for the persistence-neutral turn-movement kernel.
abstract final class DomainTurnMovementProcessor {
  static DomainTurnMovementResult resetForPlayers({
    required DomainState state,
    required Iterable<String> playerIds,
    required MapTraversalView mapData,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    final movement = TurnMovementOrchestrator.resetForPlayers(
      state: TurnMovementState(
        units: state.units,
        cities: state.cities,
        diplomacy: state.diplomacy,
        fogOfWar: state.fogOfWar,
        interaction: state.actions,
        fieldImprovements: state.fieldImprovements,
        research: state.research,
      ),
      context: TurnMovementContext(
        playerIds: playerIds,
        phaseKnownPlayerIds: _knownPlayerIds(state),
        mapData: mapData,
        fogOfWarService: fogOfWarService,
        ruleset: ruleset,
      ),
    );
    if (!movement.changed) {
      return DomainTurnMovementResult(state: state);
    }
    final unitsChanged = !identical(movement.state.units, state.units);
    final fogChanged = !identical(movement.state.fogOfWar, state.fogOfWar);
    final diplomacyChanged = !identical(
      movement.state.diplomacy,
      state.diplomacy,
    );
    return DomainTurnMovementResult(
      state: unitsChanged || fogChanged || diplomacyChanged
          ? state.copyWith(
              units: unitsChanged ? movement.state.units : null,
              fogOfWar: fogChanged ? movement.state.fogOfWar : null,
              diplomacy: diplomacyChanged ? movement.state.diplomacy : null,
              actions: movement.state.interaction,
            )
          : state.copyWith(actions: movement.state.interaction),
      changed: true,
      events: movement.events,
      executions: movement.executions,
    );
  }

  static Set<String> _knownPlayerIds(DomainState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
  }
}
