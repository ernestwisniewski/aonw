import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('save and index origin survive JSON round trips', () {
    final save = _save(origin: GameSaveOrigin.network);
    final index = _index(origin: GameSaveOrigin.network);

    expect(save.toJson()['origin'], 'network');
    expect(index.toJson()['origin'], 'network');
    expect(GameSave.fromJson(save.toJson()).origin, GameSaveOrigin.network);
    expect(
      GameSaveIndex.fromJson(index.toJson()).origin,
      GameSaveOrigin.network,
    );
  });

  test('constructors default to explicit local origin', () {
    expect(_save().origin, GameSaveOrigin.local);
    expect(_index().origin, GameSaveOrigin.local);
  });

  test('legacy JSON with missing or unknown origin stays distinguishable', () {
    final saveJson = _save().toJson()..remove('origin');
    final indexJson = _index().toJson()..['origin'] = 'future-origin';

    expect(GameSave.fromJson(saveJson).origin, GameSaveOrigin.legacy);
    expect(GameSaveIndex.fromJson(indexJson).origin, GameSaveOrigin.legacy);
  });
}

GameSave _save({GameSaveOrigin origin = GameSaveOrigin.local}) {
  return GameSave(
    id: 'save_1',
    name: 'Campaign',
    mapName: 'verdantia',
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 8, 9),
    camera: CameraState.zero,
    origin: origin,
  );
}

GameSaveIndex _index({GameSaveOrigin origin = GameSaveOrigin.local}) {
  return GameSaveIndex(
    id: 'save_1',
    name: 'Campaign',
    mapName: 'verdantia',
    turn: 1,
    savedAt: DateTime.utc(2026, 8, 9),
    origin: origin,
  );
}
