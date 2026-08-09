import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/multiplayer_save_origin.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit local origin wins even for a multi-prefixed campaign', () {
    final save = _save(
      name: 'multi campaign',
      origin: GameSaveOrigin.local,
      players: const [_human, _otherHuman],
    );

    expect(isNetworkBackedGameSave(save: save, networkSession: null), isFalse);
  });

  test('explicit network origin wins for one-human and AI roster', () {
    final save = _save(
      origin: GameSaveOrigin.network,
      players: const [_human, _ai],
    );

    expect(isNetworkBackedGameSave(save: save, networkSession: null), isTrue);
  });

  test('legacy origin alone uses the participant invariant', () {
    expect(
      isNetworkBackedGameSave(
        save: _save(
          origin: GameSaveOrigin.legacy,
          players: const [_human, _otherHuman],
        ),
        networkSession: null,
      ),
      isTrue,
    );
    expect(
      isNetworkBackedGameSave(
        save: _save(
          origin: GameSaveOrigin.legacy,
          players: const [_human, _ai],
        ),
        networkSession: null,
      ),
      isFalse,
    );
  });

  test('active match identity overrides explicit local origin', () {
    final save = _save(origin: GameSaveOrigin.local);
    final session = NetworkSession(
      userId: 'user_1',
      token: AuthToken('token'),
      matchId: save.id,
      connectionState: NetworkConnectionState.offline,
    );

    expect(
      isNetworkBackedGameSave(save: save, networkSession: session),
      isTrue,
    );
  });
}

const _human = Player(id: 'human', name: 'Human', colorValue: 0xFF4A7FC4);
const _otherHuman = Player(
  id: 'human_2',
  name: 'Other',
  colorValue: 0xFFC45050,
);
const _ai = Player(
  id: 'ai',
  name: 'AI',
  colorValue: 0xFF50A050,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1),
);

GameSave _save({
  String name = 'Campaign',
  required GameSaveOrigin origin,
  List<Player> players = const [],
}) {
  return GameSave(
    id: 'save_1',
    name: name,
    mapName: 'verdantia',
    turn: 1,
    playerStates: const {},
    savedAt: DateTime.utc(2026, 8, 9),
    camera: CameraState.zero,
    players: players,
    gameMode: GameMode.multiplayer,
    origin: origin,
  );
}
