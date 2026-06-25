import 'package:aonw/game/application/services/ai_precompute_schedule.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiPrecomputeScheduleKey', () {
    test('ignores save and UI metadata but changes when the world changes', () {
      final baseState = GameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
      );
      final uiOnlyState = baseState.copyWith(
        activePlayerId: 'player_2',
        activePlayerCanAct: false,
        submittedPlayerIds: const {'player_1'},
        moveCommandActive: true,
      );
      final changedWorldState = baseState.copyWith(
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2', col: 1)],
      );

      final baseKey = AiPrecomputeScheduleKey.build(
        save: _save(),
        gameState: baseState,
        player: _aiPlayer,
      );
      final uiOnlyKey = AiPrecomputeScheduleKey.build(
        save: _save(savedAt: DateTime.utc(2026, 5, 18, 12, 30)),
        gameState: uiOnlyState,
        player: _aiPlayer,
      );
      final changedWorldKey = AiPrecomputeScheduleKey.build(
        save: _save(),
        gameState: changedWorldState,
        player: _aiPlayer,
      );

      expect(uiOnlyKey, baseKey);
      expect(changedWorldKey, isNot(baseKey));
    });
  });
}

GameSave _save({DateTime? savedAt}) {
  return GameSave(
    id: 'save_1',
    name: 'AI precompute schedule test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 4,
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    },
    savedAt: savedAt ?? DateTime.utc(2026, 5, 18, 12),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Human', colorValue: 0xFF2563EB),
      _aiPlayer,
    ],
    gameMode: GameMode.multiplayer,
  );
}

const _aiPlayer = Player(
  id: 'player_2',
  name: 'AI',
  colorValue: 0xFFDC2626,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 99),
);
