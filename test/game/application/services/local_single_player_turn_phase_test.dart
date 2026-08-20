import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/local_single_player_turn_phase.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalSinglePlayerTurnPhasePolicy', () {
    test('keeps local AI in planning until the human submits', () {
      expect(
        LocalSinglePlayerTurnPhasePolicy.resolve(
          save: _save(),
          networkSession: null,
        ),
        LocalSinglePlayerTurnPhase.humanPlanning,
      );
    });

    test('enters AI resolution after the human submits', () {
      expect(
        LocalSinglePlayerTurnPhasePolicy.resolve(
          save: _save(humanState: PlayerTurnState.finished),
          networkSession: null,
        ),
        LocalSinglePlayerTurnPhase.aiResolving,
      );
    });

    test('does not apply to a network-backed save', () {
      expect(
        LocalSinglePlayerTurnPhasePolicy.resolve(
          save: _save(origin: GameSaveOrigin.network),
          networkSession: null,
        ),
        LocalSinglePlayerTurnPhase.notApplicable,
      );
    });

    test('does not apply to a save attached to a network match', () {
      expect(
        LocalSinglePlayerTurnPhasePolicy.resolve(
          save: _save(),
          networkSession: NetworkSession(
            userId: 'user_1',
            token: AuthToken('token'),
            matchId: 'save_1',
          ),
        ),
        LocalSinglePlayerTurnPhase.notApplicable,
      );
    });

    test('does not apply to local multiplayer with multiple humans', () {
      expect(
        LocalSinglePlayerTurnPhasePolicy.resolve(
          save: _save(players: const [_human, _otherHuman, _ai]),
          networkSession: null,
        ),
        LocalSinglePlayerTurnPhase.notApplicable,
      );
    });

    test('does not apply to hot-seat', () {
      expect(
        LocalSinglePlayerTurnPhasePolicy.resolve(
          save: _save(gameMode: GameMode.hotSeat),
          networkSession: null,
        ),
        LocalSinglePlayerTurnPhase.notApplicable,
      );
    });

    test('AI resolution and turn opening both block human input', () {
      expect(
        LocalSinglePlayerTurnPhase.humanPlanning.blocksHumanInput,
        isFalse,
      );
      expect(LocalSinglePlayerTurnPhase.aiResolving.blocksHumanInput, isTrue);
      expect(LocalSinglePlayerTurnPhase.turnOpening.blocksHumanInput, isTrue);
    });
  });
}

GameSave _save({
  PlayerTurnState humanState = PlayerTurnState.active,
  GameMode gameMode = GameMode.multiplayer,
  GameSaveOrigin origin = GameSaveOrigin.local,
  List<Player> players = const [_human, _ai],
}) {
  return GameSave(
    id: 'save_1',
    name: 'Local AI phase test',
    mapName: 'verdantia',
    turn: 4,
    playerStates: {'human': humanState, 'ai': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 8, 20),
    camera: CameraState.zero,
    players: players,
    gameMode: gameMode,
    origin: origin,
  );
}

const _human = Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB);

const _otherHuman = Player(
  id: 'other_human',
  name: 'Other human',
  colorValue: 0xFF16A34A,
);

const _ai = Player(
  id: 'ai',
  name: 'AI',
  colorValue: 0xFFDC2626,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1001),
);
