import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';

abstract final class AiPrecomputeScheduleKey {
  static String build({
    required GameSave save,
    required GameClientState gameState,
    required Player player,
  }) {
    final ai = player.ai;
    return '${save.id}:${save.turn}:${save.gameMode.name}:${player.id}:'
        '${player.country.name}:${ai?.strategyId.name}:${ai?.difficulty.name}:'
        '${ai?.persona.name}:${ai?.seed}:${save.matchRules.hashCode}:'
        '${worldStateHash(gameState)}';
  }

  static int worldStateHash(GameClientState state) {
    return state
        .copyWith(
          activePlayerId: '',
          activePlayerCanAct: true,
          submittedPlayerIds: const {},
          interaction: InteractionState.empty,
          intendedAttacks: const <IntendedAttack>[],
        )
        .hashCode;
  }
}
