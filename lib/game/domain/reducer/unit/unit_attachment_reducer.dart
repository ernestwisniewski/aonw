import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class UnitAttachmentReducer {
  static GameStateTransition detachTroop(
    GameState state,
    DetachTroopCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final unitIndex = state.units.indexWhere((u) => u.id == command.unitId);
    if (unitIndex == -1) return GameStateTransition(state: state);

    final source = state.units[unitIndex];
    if (!context.canControlUnit(state, source)) {
      return GameStateTransition(state: state);
    }

    final result = DetachTroopResolver.detachTroop(
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
      playerIds: knownPlayerIds(state),
      command: command,
      actorPlayerId: source.ownerPlayerId,
      mapTiles: mapTiles,
      visibility: context.visibilityFor(state),
      fogOfWarService: fogOfWarService,
    );
    if (!result.accepted) return GameStateTransition(state: state);

    final sourceTile = mapTiles.tileAt(source.col, source.row);
    final updatedSource = result.units.firstWhere(
      (unit) => unit.id == source.id,
    );
    final next = state
        .copyWith(
          units: result.units,
          fogOfWar: result.fogOfWar,
          diplomacy: result.diplomacy,
        )
        .copyWithInteraction(
          moveCommandActive: false,
          movePreview: null,
          cityFoundingDraft: null,
          selection: GameSelection.unit(updatedSource, tile: sourceTile),
        );

    return GameStateTransition(state: next);
  }
}
