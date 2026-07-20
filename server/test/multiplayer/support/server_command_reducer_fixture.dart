part of '../server_command_reducer_test.dart';

WireSnapshot _snapshot(PersistentGameState state, {GameSave? save}) {
  return WireSnapshot(
    matchId: 'match_1',
    offset: 0,
    save: (save ?? _save()).toJson(),
    state: state.toJson(),
  );
}

GameSave _save({
  Map<String, PlayerTurnState>? playerStates,
  List<Player>? players,
  String mapName = 'test_map',
}) {
  return GameSave(
    id: 'save_1',
    name: 'Server reducer trade',
    mapName: mapName,
    turn: 1,
    playerStates:
        playerStates ??
        const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
    savedAt: DateTime.utc(2026, 6, 30, 11),
    camera: CameraState.zero,
    players: players ?? _domainPlayers(),
    gameMode: GameMode.multiplayer,
  );
}
