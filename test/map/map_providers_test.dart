import 'package:aonw/map/application/map_repository.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/persistence/local_map_repository.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMapRepository implements MapRepository {
  final MapData mapData;
  final List<MapSelection> maps;
  final String? imagePath;
  String? deletedName;

  _FakeMapRepository({
    required this.mapData,
    this.maps = const [],
    this.imagePath,
  });

  @override
  Future<List<MapSelection>> listAvailableMaps() async => maps;

  @override
  Future<MapData> loadMap(MapSelection selection) async => mapData;

  @override
  Future<String?> resolveImagePath(MapSelection selection) async => imagePath;

  @override
  Future<void> deleteSavedMap(String name) async {
    deletedName = name;
  }
}

MapData _map() => MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
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
      imagePath: '/tmp/map.png',
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
      container.read(mapImagePathProvider(selection).future),
      completion('/tmp/map.png'),
    );
  });
}
