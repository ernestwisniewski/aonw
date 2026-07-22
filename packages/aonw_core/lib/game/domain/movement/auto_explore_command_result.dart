import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Immutable output of state-container-neutral auto-explore resolution.
final class AutoExploreCommandResult {
  factory AutoExploreCommandResult.accepted({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required PersistedInteractionState interaction,
    Iterable<GameEvent> events = const [],
    MovementCommandExecution? execution,
  }) {
    return AutoExploreCommandResult._owned(
      accepted: true,
      reason: null,
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: interaction,
      events: events.isEmpty ? const [] : List<GameEvent>.unmodifiable(events),
      execution: execution,
    );
  }

  const AutoExploreCommandResult.rejected({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    required this.interaction,
    required this.reason,
  }) : accepted = false,
       events = const [],
       execution = null;

  const AutoExploreCommandResult._owned({
    required this.accepted,
    required this.reason,
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    required this.interaction,
    required this.events,
    required this.execution,
  });

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
  final PersistedInteractionState interaction;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
}
