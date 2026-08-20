import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw/map/application/map_repository.dart';
import 'package:aonw/map/persistence/local_map_repository.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMapRepository implements MapRepository {
  final WorldMap mapData;
  final List<MapSelection> maps;
  final MapImageSource? imageSource;
  String? deletedName;

  _FakeMapRepository({
    required this.mapData,
    this.maps = const [],
    this.imageSource,
  });

  @override
  Future<List<MapSelection>> listAvailableMaps() async => maps;

  @override
  Future<WorldMap> loadMap(MapSelection selection) async => mapData;

  @override
  Future<MapImageSource?> resolveImageSource(MapSelection selection) async =>
      imageSource;

  @override
  Future<void> deleteSavedMap(String name) async {
    deletedName = name;
  }
}

WorldMap _map() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.ocean],
      resources: [],
      height: 0,
    ),
  ],
);

void main() {
  const selection = MapSelection(name: 'test', source: MapSource.asset);

  test('mapRepositoryProvider uses local repository by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mapRepositoryProvider), isA<LocalMapRepository>());
  });

  test('map providers read through injected repository', () async {
    final repository = _FakeMapRepository(
      mapData: _map(),
      maps: const [selection],
      imageSource: const SavedMapSingleImageSource('/tmp/map.png'),
    );
    final container = ProviderContainer(
      overrides: [mapRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(availableMapsProvider.future),
      completion([selection]),
    );
    await expectLater(
      container.read(activeMapProvider(selection).future),
      completion(same(repository.mapData)),
    );
    await expectLater(
      container.read(mapImageSourceProvider(selection).future),
      completion(const SavedMapSingleImageSource('/tmp/map.png')),
    );
  });
}
