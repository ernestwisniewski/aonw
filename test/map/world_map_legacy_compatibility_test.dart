import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/reducer_parity_fixture.dart';

void main() {
  group('WorldMap legacy compatibility', () {
    test('preserves every bundled map and its objectives', () {
      const expectedMapNames = {'myranth', 'terenos', 'verdantia'};
      final discoveredMapNames = _bundledMapNames();
      expect(discoveredMapNames, expectedMapNames);

      for (final mapName in discoveredMapNames) {
        final source = File('assets/maps/$mapName/map.json').readAsStringSync();
        final legacy = MapDataCodec.fromJson(source);
        final world = LegacyWorldMapAdapter.fromMapData(legacy);
        final roundTripped = LegacyWorldMapAdapter.toMapData(world);
        final normalizedLegacy = jsonDecode(MapDataCodec.toJson(legacy));

        expect(
          jsonDecode(MapDataCodec.toJson(roundTripped)),
          normalizedLegacy,
          reason: '$mapName WorldMap round-trip',
        );
        expect(world.mapName, mapName);
        expect(world.indexedTileCount, legacy.tiles.length);
        expect(world.objectives.length, legacy.objectives.length);
        _expectIndexedTiles(world, legacy, mapName);
      }
    });

    test('preserves the map in every reducer parity fixture', () {
      final fixtures = ReducerParityCorpus.load(Directory.current);

      for (final fixture in fixtures) {
        final expected = jsonDecode(MapDataCodec.toJson(fixture.mapData));
        final world = LegacyWorldMapAdapter.fromMapData(fixture.mapData);
        final roundTripped = LegacyWorldMapAdapter.toMapData(world);

        expect(
          jsonDecode(MapDataCodec.toJson(roundTripped)),
          expected,
          reason: fixture.id,
        );
        expect(world.indexedTileCount, fixture.mapData.tiles.length);
      }
    });
  });
}

Set<String> _bundledMapNames() {
  return Directory('assets/maps')
      .listSync()
      .whereType<Directory>()
      .where((directory) => File('${directory.path}/map.json').existsSync())
      .map((directory) => directory.uri.pathSegments.reversed.skip(1).first)
      .toSet();
}

void _expectIndexedTiles(WorldMap world, MapData legacy, String mapName) {
  for (final tile in legacy.tiles) {
    final indexed = world.tileAt(HexCoord(col: tile.col, row: tile.row));
    expect(indexed, isNotNull, reason: '$mapName ${tile.col},${tile.row}');
    expect(indexed!.terrains, tile.terrains);
    expect(indexed.resources, tile.resources);
    expect(indexed.height, tile.height);
  }
}
