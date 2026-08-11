import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Persistence-neutral state used by the movement phase of a turn.
final class TurnMovementState {
  const TurnMovementState({
    required this.units,
    required this.cities,
    required this.diplomacy,
    required this.fogOfWar,
    required this.interaction,
    this.fieldImprovements = const [],
    this.research = ResearchState.empty,
    this.transportNetwork = TransportNetworkState.empty,
  });

  final List<GameUnit> units;
  final List<GameCity> cities;
  final DiplomacyState diplomacy;
  final FogOfWarState fogOfWar;
  final DomainActionState interaction;
  final List<FieldImprovement> fieldImprovements;
  final ResearchState research;
  final TransportNetworkState transportNetwork;
}

/// Persistence-neutral output of the movement phase of a turn.
final class TurnMovementResult {
  factory TurnMovementResult({
    required TurnMovementState state,
    bool changed = false,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> executions = const [],
  }) {
    return TurnMovementResult._(
      state: state,
      changed: changed,
      events: events.isEmpty ? const [] : List.unmodifiable(events),
      executions: executions.isEmpty ? const [] : List.unmodifiable(executions),
    );
  }

  const TurnMovementResult._({
    required this.state,
    required this.changed,
    required this.events,
    required this.executions,
  });

  final TurnMovementState state;
  final bool changed;
  final List<GameEvent> events;
  final List<MovementCommandExecution> executions;
}
