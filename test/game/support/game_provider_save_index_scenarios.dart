part of '../game_providers_test.dart';

void _registerGameSaveIndexProviderScenarios() {
  group('gameSavesIndexProvider', () {
    test('lists saves through repository', () async {
      final save = _makeSave();
      final gameRepository = _FakeGameRepository(
        snapshots: {save.id: GameSnapshotFactory.create(save: save)},
      );
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSavesIndexProvider.future),
        completion(
          contains(
            isA<GameSaveIndex>()
                .having((index) => index.id, 'id', save.id)
                .having((index) => index.name, 'name', save.name),
          ),
        ),
      );
    });
  });
}
