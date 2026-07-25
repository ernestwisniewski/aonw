import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_auto_explore_advancer.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_unit_movement_advancer.dart';

abstract final class TurnMovementOrchestrator {
  static TurnMovementResult resetForPlayers({
    required TurnMovementState state,
    required TurnMovementContext context,
  }) {
    if (context.playerIds.isEmpty) return TurnMovementResult(state: state);
    final advanced = TurnUnitMovementAdvancer.advance(
      units: state.units,
      cities: state.cities,
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      playerIds: context.playerIds,
      mapData: context.mapData,
    );
    var fogOfWar = state.fogOfWar;
    if (advanced.changed) {
      fogOfWar = context.fogOfWarService.recompute(
        current: state.fogOfWar,
        mapData: context.mapData,
        playerIds: context.phaseKnownPlayerIds,
        units: advanced.units,
        cities: state.cities,
      );
    }
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.diplomacy,
      fogOfWar: fogOfWar,
      units: advanced.units,
      cities: state.cities,
      playerIds: context.phaseKnownPlayerIds,
    );
    final autoExplore = TurnAutoExploreAdvancer.advance(
      units: advanced.units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      interaction: state.interaction,
      cities: state.cities,
      playerIds: context.playerIds,
      phaseKnownPlayerIds: context.phaseKnownPlayerIds,
      mapData: context.mapData,
      fogOfWarService: context.fogOfWarService,
    );
    final changed =
        advanced.changed ||
        !identical(diplomacy, state.diplomacy) ||
        autoExplore.changed;
    if (!changed) return TurnMovementResult(state: state);
    return TurnMovementResult(
      state: TurnMovementState(
        units: List.unmodifiable(autoExplore.units),
        cities: state.cities,
        diplomacy: autoExplore.diplomacy,
        fogOfWar: autoExplore.fogOfWar,
        interaction: autoExplore.interaction,
      ),
      changed: true,
      events: autoExplore.events,
      executions: [...advanced.executions, ...autoExplore.executions],
    );
  }
}
