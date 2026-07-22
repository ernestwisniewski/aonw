import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/movement_command_result.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainMoveUnitResult {
  const DomainMoveUnitResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.execution,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
  final String? reason;
}

/// Canonical-state adapter for the state-neutral movement resolver.
final class DomainMoveUnitResolver {
  const DomainMoveUnitResolver({
    this.commandResolver = const MovementCommandResolver(),
  });

  final MovementCommandResolver commandResolver;

  DomainMoveUnitResult resolve({
    required DomainState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    bool canAct = true,
    MovementCommandVisibilityMode visibilityMode =
        MovementCommandVisibilityMode.authoritative,
  }) {
    final result = commandResolver.resolve(
      state: MovementCommandState(
        units: state.units,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
        diplomacy: state.diplomacy,
        playerIds: _playerIds(state),
      ),
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      canAct: canAct,
      visibilityMode: visibilityMode,
    );
    return _apply(state, result);
  }

  static DomainMoveUnitResult _apply(
    DomainState state,
    MovementCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainMoveUnitResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final fogChanged = !identical(result.fogOfWar, state.fogOfWar);
    final diplomacyChanged = !identical(result.diplomacy, state.diplomacy);
    final nextState = unitsChanged || fogChanged || diplomacyChanged
        ? state.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            diplomacy: diplomacyChanged ? result.diplomacy : null,
          )
        : state;
    return DomainMoveUnitResult(
      accepted: true,
      state: nextState,
      events: result.events,
      execution: result.execution,
    );
  }

  static Set<String> _playerIds(DomainState state) => {
    for (final player in state.participants) player.id,
    ...state.playerGold.keys,
    ...state.playerWarWeariness.keys,
    ...state.playerStabilityNet.keys,
    ...state.fogOfWar.playerIds,
    ...state.wonderRegistry.completedBy.values,
    ...state.dominationHoldTurnsByPlayerId.keys,
    ...state.culturalVictoryHoldTurnsByPlayerId.keys,
    for (final unit in state.units) unit.ownerPlayerId,
    for (final city in state.cities) city.ownerPlayerId,
    for (final city in state.cities) ?city.foundingOwnerPlayerId,
    for (final relation in state.diplomacy.relations.values) relation.playerAId,
    for (final relation in state.diplomacy.relations.values) relation.playerBId,
  }..removeWhere((playerId) => playerId.isEmpty);
}
