part of 'live_event_subscription_test.dart';

CanonicalGameSnapshot _snapshot(int offset) =>
    GameSnapshotFactory.create(save: _save(), eventLogOffset: offset);

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
}
