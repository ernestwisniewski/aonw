import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/movement_command_result.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentMoveUnitResult {
  const PersistentMoveUnitResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.execution,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
  final String? reason;
}

/// Persistence adapter for the state-container-neutral movement resolver.
final class PersistentMoveUnitResolver {
  const PersistentMoveUnitResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentMoveUnitResult resolve({
    required PersistentGameState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    bool canAct = true,
    MovementCommandVisibilityMode visibilityMode =
        MovementCommandVisibilityMode.authoritative,
  }) {
    final result = MovementCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: MovementCommandState(
            units: state.units,
            cities: state.cities,
            fogOfWar: state.fogOfWar,
            diplomacy: state.runtimeState.diplomacy,
            playerIds: state.knownPlayerIds,
          ),
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: mapData,
          canAct: canAct,
          visibilityMode: visibilityMode,
        );
    return _apply(state, result);
  }

  static PersistentMoveUnitResult _apply(
    PersistentGameState state,
    MovementCommandResult result,
  ) {
    if (!result.accepted) {
      return PersistentMoveUnitResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final fogChanged = !identical(result.fogOfWar, state.fogOfWar);
    final diplomacyChanged = !identical(
      result.diplomacy,
      state.runtimeState.diplomacy,
    );
    final nextState = unitsChanged || fogChanged || diplomacyChanged
        ? state.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            runtimeState: diplomacyChanged
                ? state.runtimeState.copyWith(diplomacy: result.diplomacy)
                : null,
          )
        : state;
    return PersistentMoveUnitResult(
      accepted: true,
      state: nextState,
      events: result.events,
      execution: result.execution,
    );
  }
}
