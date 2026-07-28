import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:test/test.dart';

void main() {
  test('loads the first existing safe map from configured roots', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'aonw-map-catalog-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final assetDirectory = Directory(
      '${tempDirectory.path}/assets/canonical-fixture',
    );
    await assetDirectory.create(recursive: true);
    await File(
      '${assetDirectory.path}/map.json',
    ).writeAsString(MapDataCodec.toJson(_catalogFixtureMap()));

    final loaded = await FileMultiplayerMapCatalog(
      roots: ['${tempDirectory.path}/missing', '${tempDirectory.path}/assets'],
    ).loadAssetMap(' canonical-fixture ');

    expect(loaded.cols, 1);
    expect(loaded.rows, 1);
    expect(loaded.mapName, 'catalog-fixture');
    expect(loaded.tiles, hasLength(1));
    final tile = loaded.tiles.single;
    expect(tile.col, 0);
    expect(tile.row, 0);
    expect(tile.terrains, [TerrainType.forest]);
    expect(tile.resources, [ResourceType.deer]);
    expect(tile.height, 2);
  });

  test('rejects unsafe names before accessing the filesystem', () async {
    const catalog = FileMultiplayerMapCatalog(roots: []);

    for (final invalidName in const [
      '',
      ' ',
      '..',
      '../verdantia',
      'maps/verdantia',
      r'maps\verdantia',
    ]) {
      await expectLater(
        catalog.loadAssetMap(invalidName),
        throwsA(isA<ArgumentError>()),
        reason: invalidName,
      );
    }
  });

  test('reports a missing safe map', () async {
    const catalog = FileMultiplayerMapCatalog(roots: []);

    await expectLater(
      catalog.loadAssetMap('missing-map'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Map asset not found: missing-map',
        ),
      ),
    );
  });
}

MapData _catalogFixtureMap() {
  return MapData(
    cols: 1,
    rows: 1,
    mapName: 'catalog-fixture',
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.forest],
        resources: [ResourceType.deer],
        height: 2,
      ),
    ],
  );
}
