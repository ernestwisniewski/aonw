import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';

abstract final class DiplomaticActionGuardAdapter {
  static bool canIssue(
    GameState state,
    String playerId,
    GameCommandContext context,
  ) {
    return DiplomaticActionGuard.canIssue(
      playerId: playerId,
      canAct: context.canAct,
      actorPlayerId: context.hasActor ? context.actorPlayerId : null,
      activePlayerId: state.activePlayerId,
    );
  }

  static bool canTargetDiscoveredPlayer(
    GameState state,
    String playerId,
    String targetPlayerId,
  ) {
    return DiplomaticActionGuard.canTargetDiscovered(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
      knownPlayerIds: knownPlayerIds(state),
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
    );
  }
}
