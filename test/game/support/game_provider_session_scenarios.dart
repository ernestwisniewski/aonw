part of '../game_providers_test.dart';

void _registerGameSessionNotifierScenarios() {
  group('GameSessionNotifier', () {
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);

    ProviderContainer makeContainer({
      required AsyncValue<WorldMap> mapAsync,
      AsyncValue<String?> imagePathAsync = const AsyncData(null),
      AsyncValue<CanonicalGameSnapshot?> snapshotAsync = const AsyncData(null),
    }) {
      return ProviderContainer(
        overrides: [
          activeMapProvider(selection).overrideWithValue(mapAsync),
          mapImagePathProvider(selection).overrideWithValue(imagePathAsync),
          gameSaveSnapshotProvider('save_1').overrideWithValue(snapshotAsync),
        ],
      );
    }

    test('resolves to GameSession when all providers are ready', () async {
      final container = makeContainer(mapAsync: AsyncData(_makeMap()));
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session, isNotNull);
      expect(session.viewMode, MapViewMode.graphic);
      expect(session.imagePath, isNull);
    });

    test('resolves with imagePath when image provider has data', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        imagePathAsync: const AsyncData('/tmp/map.png'),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.imagePath, '/tmp/map.png');
    });

    test('resolves with null imagePath when image provider errors', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        imagePathAsync: AsyncError(Exception('no image'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.imagePath, isNull);
    });

    test('propagates map load error as AsyncError', () async {
      final container = makeContainer(
        mapAsync: AsyncError(Exception('map missing'), StackTrace.empty),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gameSessionProvider(selection, 'save_1').future),
        throwsA(anything),
      );
    });

    test('setViewMode updates viewMode in AsyncData state', () async {
      final container = makeContainer(mapAsync: AsyncData(_makeMap()));
      addTearDown(container.dispose);

      await container.read(gameSessionProvider(selection, 'save_1').future);
      container
          .read(gameSessionProvider(selection, 'save_1').notifier)
          .setViewMode(MapViewMode.graphic);

      final session = container
          .read(gameSessionProvider(selection, 'save_1'))
          .value;
      expect(session?.viewMode, MapViewMode.graphic);
    });

    test('setViewMode is no-op when state is not AsyncData', () async {
      final container = makeContainer(mapAsync: const AsyncLoading<WorldMap>());
      addTearDown(container.dispose);

      // should not throw
      container
          .read(gameSessionProvider(selection, 'save_1').notifier)
          .setViewMode(MapViewMode.graphic);

      final state = container.read(gameSessionProvider(selection, 'save_1'));
      expect(state, isA<AsyncLoading<GameSession>>());
    });

    test('includes saved camera metadata in the session', () async {
      final container = makeContainer(
        mapAsync: AsyncData(_makeMap()),
        snapshotAsync: AsyncData(
          _makeSnapshot(
            save: _makeSave().copyWith(
              camera: const CameraState(x: 1, y: 2, zoom: 3),
            ),
          ),
        ),
      );
      addTearDown(container.dispose);

      final session = await container.read(
        gameSessionProvider(selection, 'save_1').future,
      );
      expect(session.initialCamera?.x, 1);
      expect(session.initialCamera?.y, 2);
      expect(session.initialCamera?.zoom, 3);
    });

    test(
      'session does not depend on world-slice repository providers',
      () async {
        final container = ProviderContainer(
          overrides: [
            activeMapProvider(
              selection,
            ).overrideWithValue(AsyncData(_makeMap())),
            mapImagePathProvider(
              selection,
            ).overrideWithValue(const AsyncData(null)),
            gameSaveSnapshotProvider(
              'save_1',
            ).overrideWithValue(const AsyncData(null)),
          ],
        );
        addTearDown(container.dispose);

        final session = await container.read(
          gameSessionProvider(selection, 'save_1').future,
        );

        expect(session.mapData.cols, 5);
      },
    );
  });
}
