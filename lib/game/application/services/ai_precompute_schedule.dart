import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/player.dart';

abstract final class AiPrecomputeScheduleKey {
  static String build({
    required GameSave save,
    required GameState gameState,
    required Player player,
  }) {
    final ai = player.ai;
    return '${save.id}:${save.turn}:${save.gameMode.name}:${player.id}:'
        '${player.country.name}:${ai?.strategyId.name}:${ai?.difficulty.name}:'
        '${ai?.persona.name}:${ai?.seed}:${save.matchRules.hashCode}:'
        '${worldStateHash(gameState)}';
  }

  static int worldStateHash(GameState state) {
    return state
        .copyWith(
          activePlayerId: '',
          activePlayerCanAct: true,
          submittedPlayerIds: const {},
          interaction: GameInteractionState.empty,
          intendedAttacks: const <IntendedAttack>[],
        )
        .hashCode;
  }
}
