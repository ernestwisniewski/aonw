part of '../game_providers_test.dart';

void _registerGameSaveProviderScenarios() {
  group('gameSaveProvider', () {
    test('returns null for an empty save id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSaveProvider('').future),
        completion(isNull),
      );
    });

    test('loads save through repository', () async {
      final save = providerSave();
      final gameRepository = FakeGameRepository(saves: {'save_1': save});
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSaveProvider('save_1').future),
        completion(equals(save)),
      );
      expect(gameRepository.loadCount, 1);
    });

    test('surfaces repository errors', () async {
      final gameRepository = FakeGameRepository(throwOnLoad: true);
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSaveProvider('broken').future),
        throwsA(isA<StateError>()),
      );
    });
  });
}
