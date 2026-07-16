import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/reducer_parity_fixture.dart';

void main() {
  group('WorldMap tile-view compatibility', () {
    test('freezes every bundled map and its objectives', () {
      const expectedMapNames = {'myranth', 'terenos', 'verdantia'};
      final discoveredMapNames = _bundledMapNames();
      expect(discoveredMapNames, expectedMapNames);

      for (final mapName in discoveredMapNames) {
        final source = File('assets/maps/$mapName/map.json').readAsStringSync();
        final mapData = MapDataCodec.fromJson(source);
        final world = _worldMapFromData(mapData);

        _expectWorldMatchesMapData(world, mapData, reason: mapName);
        expect(world.mapName, mapName);
      }
    });

    test('freezes the map in every reducer parity fixture', () {
      final fixtures = ReducerParityCorpus.load(Directory.current);

      for (final fixture in fixtures) {
        final world = _worldMapFromData(fixture.mapData);

        _expectWorldMatchesMapData(world, fixture.mapData, reason: fixture.id);
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

WorldMap _worldMapFromData(MapData source) {
  return WorldMap.fromTileViews(
    cols: source.cols,
    rows: source.rows,
    tiles: source.tiles,
    objectives: source.objectives,
    mapName: source.mapName,
    defaultZoom: source.defaultZoom,
  );
}

void _expectWorldMatchesMapData(
  WorldMap world,
  MapData source, {
  required String reason,
}) {
  expect(world.cols, source.cols, reason: reason);
  expect(world.rows, source.rows, reason: reason);
  expect(world.mapName, source.mapName, reason: reason);
  expect(world.defaultZoom, source.defaultZoom, reason: reason);
  expect(world.indexedTileCount, source.tiles.length, reason: reason);
  expect(
    world.objectives.map((objective) => objective.toJson()).toList(),
    source.objectives.map((objective) => objective.toJson()).toList(),
    reason: reason,
  );
  expect(
    world.tiles
        .map(
          (tile) => {
            'col': tile.col,
            'row': tile.row,
            'terrains': tile.terrains.toList(),
            'resources': tile.resources.toList(),
            'height': tile.height,
          },
        )
        .toList(),
    source.tiles
        .map(
          (tile) => {
            'col': tile.col,
            'row': tile.row,
            'terrains': tile.terrains.toList(),
            'resources': tile.resources.toList(),
            'height': tile.height,
          },
        )
        .toList(),
    reason: reason,
  );
  for (final tile in source.tiles) {
    final indexed = world.tileAt(HexCoord(col: tile.col, row: tile.row));
    expect(indexed, isNotNull, reason: '$reason ${tile.col},${tile.row}');
  }
}
