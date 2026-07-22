import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class PersistentTurnMovementResult {
  final PersistentGameState state;
  final bool changed;

  const PersistentTurnMovementResult({
    required this.state,
    this.changed = false,
  });
}

/// Persistence adapter for the neutral turn-movement kernel.
abstract final class PersistentTurnMovementProcessor {
  static PersistentTurnMovementResult resetForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapTraversalView mapData,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final movement = TurnMovementOrchestrator.resetForPlayers(
      state: TurnMovementState(
        units: state.units,
        cities: state.cities,
        diplomacy: state.runtimeState.diplomacy,
        fogOfWar: state.fogOfWar,
      ),
      context: TurnMovementContext(
        playerIds: playerIds,
        phaseKnownPlayerIds: _knownPlayerIds(state),
        mapData: mapData,
        fogOfWarService: fogOfWarService,
      ),
    );
    if (!movement.changed) return PersistentTurnMovementResult(state: state);
    return PersistentTurnMovementResult(
      state: state.copyWith(
        units: movement.state.units,
        fogOfWar: movement.state.fogOfWar,
      ),
      changed: true,
    );
  }

  static Set<String> _knownPlayerIds(PersistentGameState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
  }
}
