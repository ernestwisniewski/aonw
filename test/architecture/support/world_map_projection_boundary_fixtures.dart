part of '../world_map_projection_boundary_test.dart';

void _registerWorldMapProjectionBoundaryFixtures() {
  test('guard rejects direct, prefixed, tear-off, and manual projections', () {
    final violations = _legacyProjectionViolations('''
typedef Adapter = LegacyWorldMapAdapter;

void direct(WorldMap worldMap) {
  final first = LegacyWorldMapAdapter.toMapData(worldMap);
  final second = legacy.LegacyWorldMapAdapter.toMapData(worldMap);
  final projection = LegacyWorldMapAdapter.toMapData;
  final prefixedProjection = legacy.LegacyWorldMapAdapter.toMapData;
  final aliasedProjection = Adapter.toMapData(worldMap);
  final manual = MapData(cols: worldMap.cols, rows: worldMap.rows, tiles: []);
}
''', 'fixture.dart');

    expect(
      violations.where((violation) => violation.contains('toMapData')),
      hasLength(5),
    );
    expect(violations, contains(contains('must not reference MapData')));
  });

  test(
    'guard rejects removed bounded adapters but allows unrelated methods',
    () {
      final violations = _legacyProjectionViolations('''
TileData? projectOne(WorldMap worldMap) =>
    LegacyWorldMapAdapter.tileDataAt(worldMap, 0, 0);
Object saveDraft(MapDraft draft) => draft.toMapData();
''', 'fixture.dart');

      expect(violations, hasLength(1));
      expect(violations, contains(contains('tileDataAt')));
    },
  );

  test('adapter guard rejects full projections hidden behind helpers', () {
    final violations = _classProjectionViolations(
      '''
abstract final class LegacyWorldMapAdapter {
  static MapData toMapData(WorldMap worldMap) => throw UnimplementedError();

  static Object asTileLookup(WorldMap worldMap) => _hidden(worldMap);

  static Object _hidden(WorldMap worldMap) => toMapData(worldMap);
}
''',
      'fixture.dart',
      className: 'LegacyWorldMapAdapter',
      allowedProjectionMethods: _allowedFullMapConverterMethods,
    );

    expect(violations, contains(contains('toMapData')));
  });

  test('adapter API guard rejects every unexpected public method', () {
    final violations = _adapterApiDeclarationViolations('''
abstract final class LegacyWorldMapAdapter {
  static WorldMap fromMapData(MapData mapData) => throw UnimplementedError();
  static MapData toMapData(WorldMap worldMap) => throw UnimplementedError();

  static WorldTile? lookup(WorldMap worldMap, int col, int row) =>
      _lookup(worldMap, col, row);
  static final lookupCache = <HexCoord, WorldTile>{};
  factory LegacyWorldMapAdapter.named() => throw UnimplementedError();

  static WorldTile? _lookup(WorldMap worldMap, int col, int row) => null;
}
''', 'fixture.dart');

    expect(violations, hasLength(3));
    expect(violations, contains(contains('unexpected public method lookup')));
    expect(
      violations,
      contains(contains('unexpected public field lookupCache')),
    );
    expect(violations, contains(contains('unexpected public constructor')));
  });

  test('adapter API guard requires both exact converter signatures', () {
    final missingConverter = _adapterApiDeclarationViolations('''
abstract final class LegacyWorldMapAdapter {
  static WorldMap fromMapData(MapData mapData) => throw UnimplementedError();
}
''', 'missing_converter.dart');
    final getterInsteadOfMethod = _adapterApiDeclarationViolations('''
abstract final class LegacyWorldMapAdapter {
  static WorldMap fromMapData(MapData mapData) => throw UnimplementedError();
  static MapData get toMapData => throw UnimplementedError();
}
''', 'getter_converter.dart');
    final genericConverter = _adapterApiDeclarationViolations('''
abstract final class LegacyWorldMapAdapter {
  static WorldMap fromMapData<T>(MapData mapData) => throw UnimplementedError();
  static MapData toMapData(WorldMap worldMap) => throw UnimplementedError();
}
''', 'generic_converter.dart');
    final implicitPublicConstructor = _adapterApiDeclarationViolations('''
final class LegacyWorldMapAdapter {
  static WorldMap fromMapData(MapData mapData) => throw UnimplementedError();
  static MapData toMapData(WorldMap worldMap) => throw UnimplementedError();
}
''', 'implicit_constructor.dart');

    expect(
      missingConverter,
      contains(contains('exactly one toMapData converter')),
    );
    expect(
      getterInsteadOfMethod,
      contains(contains('toMapData must be static MapData')),
    );
    expect(
      genericConverter,
      contains(contains('fromMapData must be static WorldMap')),
    );
    expect(
      implicitPublicConstructor,
      contains(contains('abstract final utility class')),
    );
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

  test(
    'adapter guard rejects hidden calls and tear-offs for both converters',
    () {
      final violations = _classProjectionViolations(
        '''
abstract final class LegacyWorldMapAdapter {
  static WorldMap fromMapData(MapData mapData) => throw UnimplementedError();
  static MapData toMapData(WorldMap worldMap) => throw UnimplementedError();

  static Object hiddenImports(MapData mapData) {
    final importLater = fromMapData;
    return fromMapData(mapData);
  }

  static Object hiddenProjections(WorldMap worldMap) {
    final projectLater = toMapData;
    return toMapData(worldMap);
  }

  static Object unrelated(Codec codec, Object data) {
    final decodeLater = codec.fromMapData;
    codec.toMapData(data);
    return decodeLater;
  }
}
''',
        'fixture.dart',
        className: 'LegacyWorldMapAdapter',
        allowedProjectionMethods: _allowedFullMapConverterMethods,
      );

      expect(
        violations.where(
          (violation) =>
              violation.contains('LegacyWorldMapAdapter.fromMapData'),
        ),
        hasLength(2),
      );
      expect(
        violations.where(
          (violation) => violation.contains('LegacyWorldMapAdapter.toMapData'),
        ),
        hasLength(2),
      );
    },
  );

  test('class guard permits projections only in named migration methods', () {
    final violations = _classProjectionViolations(
      '''
class PersistentCityProductionResolver {
  Object pending(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);

  Object migratedDirectly(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);

  Object migratedViaHelper(WorldMap worldMap) => _hidden(worldMap);

  Object _hidden(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);
}
''',
      'fixture.dart',
      className: 'PersistentCityProductionResolver',
      allowedProjectionMethods: const {'pending'},
    );

    expect(violations, contains(contains('toMapData')));
    expect(violations, hasLength(2));
  });

  test('ratchet binds projections to path, owner, and reference kind', () {
    const allowedKey = 'lib/allowed.dart::class:Allowed/method:pending::call';
    final violations = _projectionRatchetViolations(
      {
        'lib/allowed.dart': '''
class Allowed {
  Object pending(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);
}
''',
        'lib/helper.dart': '''
class Helper {
  Object hidden(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);
}
''',
        'lib/tear_off.dart': '''
final projection = LegacyWorldMapAdapter.toMapData;
''',
      },
      allowedSites: const {allowedKey: 1},
    );

    expect(violations, hasLength(2));
    expect(violations, contains(contains('lib/helper.dart')));
    expect(violations, contains(contains('lib/tear_off.dart')));
    expect(violations, contains(contains('tearOff')));
  });

  test('ratchet rejects another projection in an allowed member', () {
    const key = 'lib/allowed.dart::class:Allowed/method:pending::call';
    final violations = _projectionRatchetViolations(
      {
        'lib/allowed.dart': '''
class Allowed {
  void pending(WorldMap worldMap) {
    LegacyWorldMapAdapter.toMapData(worldMap);
    LegacyWorldMapAdapter.toMapData(worldMap);
  }
}
''',
      },
      allowedSites: const {key: 1},
    );

    expect(violations, contains(contains('expected 1, found 2')));
  });

  test('guard forbids adapter typedefs defined outside the consumer unit', () {
    final violations = _adapterTypedefViolations({
      'lib/adapter_alias.dart': '''
typedef Adapter = legacy.LegacyWorldMapAdapter;
typedef ChainedAdapter = Adapter;
''',
      'lib/consumer.dart': '''
import 'adapter_alias.dart';

WorldMap importMap(MapData data) => Adapter.fromMapData(data);
final importMapLater = ChainedAdapter.fromMapData;
''',
    });

    expect(violations, hasLength(2));
    expect(violations, contains(contains('typedef:Adapter')));
    expect(violations, contains(contains('typedef:ChainedAdapter')));
  });
}
