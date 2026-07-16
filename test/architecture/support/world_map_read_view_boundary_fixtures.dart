part of '../world_map_projection_boundary_test.dart';

void _registerWorldMapReadViewBoundaryFixtures() {
  test('removed adapter guard rejects symbols and stale imports', () {
    final violations = removedProductionSymbolViolations(
      {
        'fixture.dart': '''
import 'package:aonw_core/map/persistence/legacy_world_map_adapter.dart';

Object restore(MapData data) => LegacyWorldMapAdapter.fromMapData(data);
''',
      },
      symbol: 'LegacyWorldMapAdapter',
      uriSuffix: '/legacy_world_map_adapter.dart',
    );

    expect(
      violations,
      contains('fixture.dart:3 must not reference LegacyWorldMapAdapter'),
    );
    expect(
      violations,
      contains(
        'fixture.dart:1 must not import or export '
        'package:aonw_core/map/persistence/legacy_world_map_adapter.dart',
      ),
    );
  });

  test('symbol guard rejects static references outside type positions', () {
    final violations = sourceSymbolReferenceViolations(
      'final decoder = MapData.fromJson;',
      'fixture.dart',
      symbol: 'MapData',
    );

    expect(violations, contains('fixture.dart:1 must not reference MapData'));
  });

  test('read-view guard rejects every zero-copy invariant mutation', () {
    final nonFinal = _worldMapReadViewViolations('''
class WorldMapReadView {
  final WorldMap _worldMap;
  WorldTile? tileAt(int col, int row) => null;
}
''', 'non_final.dart');
    final wrongReturn = _worldMapReadViewViolations('''
final class WorldMapReadView {
  final WorldMap _worldMap;
  MapTileView? tileAt(int col, int row) => null;
}
''', 'wrong_return.dart');
    final tileData = _worldMapReadViewViolations('''
final class WorldMapReadView {
  final WorldMap _worldMap;
  WorldTile? tileAt(int col, int row) => null;
  TileData? project(int col, int row) => null;
}
''', 'tile_data.dart');
    final explicitCache = _worldMapReadViewViolations('''
final class WorldMapReadView {
  final WorldMap _worldMap;
  final Map<HexCoord, WorldTile> _cache = {};
  WorldTile? tileAt(int col, int row) => null;
}
''', 'explicit_cache.dart');
    final inferredCache = _worldMapReadViewViolations('''
final class WorldMapReadView {
  final WorldMap _worldMap;
  final _cache = <HexCoord, WorldTile>{};
  WorldTile? tileAt(int col, int row) => null;
}
''', 'inferred_cache.dart');
    final globalCache = _worldMapReadViewViolations('''
final _cache = <HexCoord, WorldTile>{};

final class WorldMapReadView {
  final WorldMap _worldMap;
  WorldTile? tileAt(int col, int row) => _cache[HexCoord(col: col, row: row)];
}
''', 'global_cache.dart');
    final missingField = _worldMapReadViewViolations('''
final class WorldMapReadView {
  WorldTile? tileAt(int col, int row) => null;
}
''', 'missing_field.dart');

    expect(nonFinal, contains(contains('must remain final')));
    expect(wrongReturn, contains(contains('must return WorldTile?')));
    expect(tileData, contains(contains('must not reference TileData')));
    expect(explicitCache, contains(contains('must declare exactly')));
    expect(inferredCache, contains(contains('must declare exactly')));
    expect(globalCache, contains(contains('must not declare top-level')));
    expect(missingField, contains(contains('must declare exactly')));
  });
}
