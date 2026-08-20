part of '../game_providers_test.dart';

void _registerSavedCameraProviderScenarios() {
  group('savedCameraProvider', () {
    test('returns null for an empty save id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(savedCameraProvider('').future),
        completion(isNull),
      );
    });

    test('loads camera through repository', () async {
      final gameRepository = FakeGameRepository(
        saves: {'save_1': providerSave()},
      );
      final container = ProviderContainer(
        overrides: [gameRepositoryProvider.overrideWithValue(gameRepository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(savedCameraProvider('save_1').future),
        completion(
          isA<CameraState>()
              .having((camera) => camera.x, 'x', 4)
              .having((camera) => camera.y, 'y', 5)
              .having((camera) => camera.zoom, 'zoom', 1.25),
        ),
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
        container.read(savedCameraProvider('broken').future),
        throwsA(isA<StateError>()),
      );
    });
  });
}
