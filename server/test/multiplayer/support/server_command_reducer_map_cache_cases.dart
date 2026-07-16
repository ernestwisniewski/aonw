part of '../server_command_reducer_test.dart';

void _registerServerCommandReducerMapCacheTests() {
  group('ServerCommandReducer map cache', () {
    test('reuses a loaded map across sequential reductions', () async {
      final map = _CountingMapData(_resourceTradeMap());
      final catalog = _CountingMapCatalog({'test_map': map});
      final reducer = ServerCommandReducer(mapCatalog: catalog);

      await _reduceForMap(reducer, 'test_map');
      await _reduceForMap(reducer, 'test_map');

      expect(catalog.loadCountFor('test_map'), 1);
      expect(map.indexedReadViewCalls, 1);
    });

    test('deduplicates concurrent loads for the same map', () async {
      final release = Completer<void>();
      final catalog = _CountingMapCatalog({
        'test_map': _resourceTradeMap(),
      }, release: release);
      final reducer = ServerCommandReducer(mapCatalog: catalog);

      final first = _reduceForMap(reducer, 'test_map');
      final second = _reduceForMap(reducer, 'test_map');
      await catalog.firstLoadStarted;

      expect(catalog.loadCountFor('test_map'), 1);
      release.complete();
      final reductions = await Future.wait([first, second]);
      expect(reductions.every((reduction) => reduction.accepted), isTrue);
      expect(catalog.loadCountFor('test_map'), 1);
    });

    test('keeps separate cache entries for different maps', () async {
      final mapA = _CountingMapData(_resourceTradeMap());
      final mapB = _CountingMapData(_resourceTradeMap());
      final catalog = _CountingMapCatalog({'map_a': mapA, 'map_b': mapB});
      final reducer = ServerCommandReducer(mapCatalog: catalog);

      await _reduceForMap(reducer, 'map_a');
      await _reduceForMap(reducer, 'map_b');
      await _reduceForMap(reducer, 'map_a');

      expect(catalog.loadCountFor('map_a'), 1);
      expect(catalog.loadCountFor('map_b'), 1);
      expect(mapA.indexedReadViewCalls, 1);
      expect(mapB.indexedReadViewCalls, 1);
    });

    test('validates tiles before indexing and evicts an invalid map', () async {
      final map = _CountingMapData(
        MapData(
          cols: 0,
          rows: 1,
          tiles: [
            const TileData(
              col: 0,
              row: 0,
              terrains: [],
              resources: [],
              height: 0,
            ),
          ],
        ),
      );
      final catalog = _CountingMapCatalog({'test_map': map});
      final reducer = ServerCommandReducer(mapCatalog: catalog);

      await expectLater(
        _reduceForMap(reducer, 'test_map'),
        throwsA(
          isA<WorldMapException>().having(
            (error) => error.message,
            'message',
            'Tile terrains must not be empty',
          ),
        ),
      );
      expect(map.indexedReadViewCalls, 0);
      expect(catalog.loadCountFor('test_map'), 1);

      map
        ..cols = 1
        ..tiles[0] = const TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        );
      final retried = await _reduceForMap(reducer, 'test_map');

      expect(retried.accepted, isTrue);
      expect(map.indexedReadViewCalls, 1);
      expect(catalog.loadCountFor('test_map'), 2);
    });

    test('evicts a failed load so the map can be retried', () async {
      final catalog = _CountingMapCatalog(
        {'test_map': _resourceTradeMap()},
        failuresBeforeSuccess: const {'test_map': 1},
      );
      final reducer = ServerCommandReducer(mapCatalog: catalog);

      await expectLater(
        _reduceForMap(reducer, 'test_map'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Injected map load failure for test_map',
          ),
        ),
      );
      final retried = await _reduceForMap(reducer, 'test_map');

      expect(retried.accepted, isTrue);
      expect(catalog.loadCountFor('test_map'), 2);
    });
  });
}

Future<ServerCommandReduction> _reduceForMap(
  ServerCommandReducer reducer,
  String mapName,
) {
  return reducer.reduce(
    match: _runningMatch(mapName: mapName),
    snapshot: _snapshot(_diplomacyState(), save: _save(mapName: mapName)),
    wireCommand: _wireCommand(const SubmitTurnCommand('player_1')),
    actorPlayerId: 'player_1',
    now: DateTime.utc(2026, 6, 30, 12),
  );
}

final class _CountingMapData extends MapData {
  _CountingMapData(MapData source)
    : super(
        cols: source.cols,
        rows: source.rows,
        tiles: source.tiles,
        objectives: source.objectives,
        mapName: source.mapName,
        defaultZoom: source.defaultZoom,
      );

  int indexedReadViewCalls = 0;

  @override
  MapReadView indexedReadView() {
    indexedReadViewCalls += 1;
    return super.indexedReadView();
  }
}

class _CountingMapCatalog implements MultiplayerMapCatalog {
  _CountingMapCatalog(
    this._maps, {
    Map<String, int> failuresBeforeSuccess = const {},
    this.release,
  }) : _failuresRemaining = Map.of(failuresBeforeSuccess);

  final Map<String, MapData> _maps;
  final Completer<void>? release;
  final Map<String, int> _failuresRemaining;
  final Map<String, int> _loadCounts = {};
  final Completer<void> _firstLoadStarted = Completer<void>();

  Future<void> get firstLoadStarted => _firstLoadStarted.future;

  int loadCountFor(String mapName) => _loadCounts[mapName] ?? 0;

  @override
  Future<MapData> loadAssetMap(String mapName) async {
    _loadCounts.update(mapName, (count) => count + 1, ifAbsent: () => 1);
    if (!_firstLoadStarted.isCompleted) _firstLoadStarted.complete();

    final failuresRemaining = _failuresRemaining[mapName] ?? 0;
    if (failuresRemaining > 0) {
      _failuresRemaining[mapName] = failuresRemaining - 1;
      throw StateError('Injected map load failure for $mapName');
    }

    final release = this.release;
    if (release != null) await release.future;
    final map = _maps[mapName];
    if (map == null) throw StateError('Map not found: $mapName');
    return map;
  }
}
