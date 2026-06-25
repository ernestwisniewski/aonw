import 'package:aonw/game/application/services/ai_precompute_targets.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiPrecomputeTargets', () {
    test(
      'selects consecutive active AI players while a local human can act',
      () {
        final targets = AiPrecomputeTargets.duringHumanTurn(
          save: _save(),
          control: const PlayerControlState(activePlayerId: 'player_1'),
          gameState: const GameState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
          ),
        );

        expect(targets.map((player) => player.id), const [
          'player_2',
          'player_3',
        ]);
      },
    );

    test('wraps turn order and skips finished AI players', () {
      final targets = AiPrecomputeTargets.duringHumanTurn(
        save: _save(
          players: const [_aiPlayer2, _aiPlayer3, _humanPlayer],
          playerStates: const {
            'player_1': PlayerTurnState.active,
            'player_2': PlayerTurnState.finished,
            'player_3': PlayerTurnState.active,
          },
        ),
        control: const PlayerControlState(activePlayerId: 'player_1'),
        gameState: const GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
      );

      expect(targets.map((player) => player.id), const ['player_3']);
    });

    test('stops when the next active player after AI chain is human', () {
      final targets = AiPrecomputeTargets.duringHumanTurn(
        save: _save(
          players: const [_humanPlayer, _aiPlayer2, _humanPlayer3, _aiPlayer4],
          playerStates: const {
            'player_1': PlayerTurnState.active,
            'player_2': PlayerTurnState.active,
            'player_3': PlayerTurnState.active,
            'player_4': PlayerTurnState.active,
          },
        ),
        control: const PlayerControlState(activePlayerId: 'player_1'),
        gameState: const GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
      );

      expect(targets.map((player) => player.id), const ['player_2']);
    });

    test('does not precompute when the next active player is human', () {
      final targets = AiPrecomputeTargets.duringHumanTurn(
        save: _save(
          players: const [_humanPlayer, _humanPlayer2, _aiPlayer3],
          playerStates: const {
            'player_1': PlayerTurnState.active,
            'player_2': PlayerTurnState.active,
            'player_3': PlayerTurnState.active,
          },
        ),
        control: const PlayerControlState(activePlayerId: 'player_1'),
        gameState: const GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        ),
      );

      expect(targets, isEmpty);
    });

    test('does not precompute during UI or turn-control mismatch', () {
      final targets = AiPrecomputeTargets.duringHumanTurn(
        save: _save(),
        control: const PlayerControlState(activePlayerId: 'player_1'),
        gameState: const GameState(
          activePlayerId: 'player_2',
          activePlayerCanAct: true,
        ),
      );

      expect(targets, isEmpty);
    });
  });
}

GameSave _save({
  List<Player> players = const [_humanPlayer, _aiPlayer2, _aiPlayer3],
  Map<String, PlayerTurnState> playerStates = const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
    'player_3': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save_1',
    name: 'AI precompute target test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 4,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 5, 18, 12),
    camera: CameraState.zero,
    players: players,
    gameMode: GameMode.multiplayer,
  );
}

const _humanPlayer = Player(
  id: 'player_1',
  name: 'Human',
  colorValue: 0xFF2563EB,
);

const _humanPlayer2 = Player(
  id: 'player_2',
  name: 'Human 2',
  colorValue: 0xFF16A34A,
);

const _humanPlayer3 = Player(
  id: 'player_3',
  name: 'Human 3',
  colorValue: 0xFFF59E0B,
);

const _aiPlayer2 = Player(
  id: 'player_2',
  name: 'AI 2',
  colorValue: 0xFFDC2626,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 99),
);

const _aiPlayer3 = Player(
  id: 'player_3',
  name: 'AI 3',
  colorValue: 0xFFF97316,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 199),
);

const _aiPlayer4 = Player(
  id: 'player_4',
  name: 'AI 4',
  colorValue: 0xFF9333EA,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 299),
);
