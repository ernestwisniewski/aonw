import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/shared/providers/gameplay_settings_provider.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('game session uses the preferred map view from settings', () async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => SharedPreferences.setMockInitialValues({}));
    const selection = MapSelection(name: 'verdantia', source: MapSource.asset);
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(selection).overrideWithValue(AsyncData(_testMap())),
        mapImagePathProvider(
          selection,
        ).overrideWithValue(const AsyncData('/tmp/map.png')),
        gameSaveSnapshotProvider(
          'save_1',
        ).overrideWithValue(const AsyncData(null)),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(gameplaySettingsProvider.notifier)
        .setPreferredMapViewMode(MapViewMode.tile);

    final session = await container.read(
      gameSessionProvider(selection, 'save_1').future,
    );

    expect(session.viewMode, MapViewMode.tile);
  });
}

WorldMap _testMap() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [],
      height: 0,
    ),
  ],
);
