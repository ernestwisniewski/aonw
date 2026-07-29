import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_phase.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainAutoExploreCommandResult {
  const DomainAutoExploreCommandResult({
    required this.accepted,
    required this.state,
    required this.interaction,
    this.events = const [],
    this.execution,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final PersistedInteractionState interaction;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
  final String? reason;
}

/// Canonical-state adapter for direct auto-exploration.
final class DomainAutoExploreCommandResolver {
  const DomainAutoExploreCommandResolver({
    this.commandResolver = const AutoExploreCommandResolver(),
  });

  final AutoExploreCommandResolver commandResolver;

  DomainAutoExploreCommandResult resolve({
    required DomainState state,
    required PersistedInteractionState interaction,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    bool canAct = true,
  }) {
    final result = commandResolver.resolve(
      state: AutoExploreCommandState(
        movement: MovementCommandState(
          units: state.units,
          cities: state.cities,
          fogOfWar: state.fogOfWar,
          diplomacy: state.diplomacy,
          playerIds: state.participants.map((player) => player.id),
        ),
        interaction: interaction,
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      phase: AutoExploreCommandPhase.direct,
      canAct: canAct,
    );
    if (!result.accepted) {
      return DomainAutoExploreCommandResult(
        accepted: false,
        state: state,
        interaction: interaction,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final fogChanged = !identical(result.fogOfWar, state.fogOfWar);
    final diplomacyChanged = !identical(result.diplomacy, state.diplomacy);
    return DomainAutoExploreCommandResult(
      accepted: true,
      state: unitsChanged || fogChanged || diplomacyChanged
          ? state.copyWith(
              units: unitsChanged ? result.units : null,
              fogOfWar: fogChanged ? result.fogOfWar : null,
              diplomacy: diplomacyChanged ? result.diplomacy : null,
            )
          : state,
      interaction: result.interaction,
      events: result.events,
      execution: result.execution,
    );
  }
}
