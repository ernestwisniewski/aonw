import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainTurnMovementResult {
  const DomainTurnMovementResult({required this.state, this.changed = false});

  final DomainState state;
  final bool changed;
}

/// Canonical-state adapter for the persistence-neutral turn-movement kernel.
abstract final class DomainTurnMovementProcessor {
  static DomainTurnMovementResult resetForPlayers({
    required DomainState state,
    required Iterable<String> playerIds,
    required MapTraversalView mapData,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final movement = TurnMovementOrchestrator.resetForPlayers(
      state: TurnMovementState(
        units: state.units,
        cities: state.cities,
        fogOfWar: state.fogOfWar,
      ),
      context: TurnMovementContext(
        playerIds: playerIds,
        phaseKnownPlayerIds: _knownPlayerIds(state),
        mapData: mapData,
        fogOfWarService: fogOfWarService,
      ),
    );
    if (!movement.changed) return DomainTurnMovementResult(state: state);
    return DomainTurnMovementResult(
      state: state.copyWith(
        units: movement.state.units,
        fogOfWar: movement.state.fogOfWar,
      ),
      changed: true,
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
