part of '../world_map_projection_boundary_test.dart';

void _registerServerMapCacheBoundaryFixtures() {
  test('server cache guard accepts one validated indexed view', () {
    expect(
      _serverMapCacheBoundaryViolations(
        source: _validServerMapCacheFixture,
        path: 'fixture.dart',
        forbiddenTypeNames: const {
          'WorldMap',
          'WorldMapReadView',
          'LegacyWorldMapAdapter',
        },
      ),
      isEmpty,
    );
  });

  test('server cache guard rejects duplicate and premature indexing', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture.replaceFirst(
        'validateMapDataTileInvariants(sourceMapData);\n'
            '    final mapView = sourceMapData.indexedReadView();',
        'final mapView = sourceMapData.indexedReadView();\n'
            '    final duplicate = sourceMapData.indexedReadView();\n'
            '    validateMapDataTileInvariants(sourceMapData);',
      ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'MapData',
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      containsAll([
        'fixture.dart _loadServerMap must call indexedReadView exactly once; '
            'found 2',
        'fixture.dart _loadServerMap must directly validate, index, and cache '
            'sourceMapData in order within one block',
      ]),
    );
  });

  test('server cache guard rejects validation hidden in a local function', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture.replaceFirst(
        'validateMapDataTileInvariants(sourceMapData);\n'
            '    final mapView = sourceMapData.indexedReadView();',
        'void validateLater() {\n'
            '      validateMapDataTileInvariants(sourceMapData);\n'
            '    }\n'
            '    final mapView = sourceMapData.indexedReadView();\n'
            '    validateLater();',
      ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      contains(
        'fixture.dart _loadServerMap must directly validate, index, and cache '
        'sourceMapData in order within one block',
      ),
    );
  });

  test('server cache guard rejects conditional validation', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture.replaceFirst(
        'validateMapDataTileInvariants(sourceMapData);',
        'if (false) validateMapDataTileInvariants(sourceMapData);',
      ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      contains(
        'fixture.dart _loadServerMap must directly validate, index, and cache '
        'sourceMapData in order within one block',
      ),
    );
  });

  test('server cache guard rejects legacy maps and a wider cache field', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture
          .replaceFirst(
            'final mapView = sourceMapData.indexedReadView();',
            'final mapView = WorldMapReadView('
                'LegacyWorldMapAdapter.fromMapData(sourceMapData));',
          )
          .replaceFirst(
            'final MapReadView mapView;',
            'final WorldMap mapView;',
          ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      containsAll([
        'fixture.dart must not reference LegacyWorldMapAdapter',
        'fixture.dart must not reference WorldMapReadView',
        'fixture.dart must not reference WorldMap',
        'fixture.dart _LoadedServerMap.mapView must be final MapReadView',
      ]),
    );
  });

  test('server cache guard rejects retaining the mutable source map', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture
          .replaceFirst(
            'return _LoadedServerMap(mapView);',
            'return _LoadedServerMap(sourceMapData, mapView);',
          )
          .replaceFirst(
            'const _LoadedServerMap(this.mapView);',
            'const _LoadedServerMap(this.legacyMapData, this.mapView);',
          )
          .replaceFirst(
            'final MapReadView mapView;',
            'final MapData legacyMapData;\n  final MapReadView mapView;',
          ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      containsAll([
        'fixture.dart _loadServerMap must cache only the same mapView',
        'fixture.dart _LoadedServerMap must cache only one mapView field; '
            'found [legacyMapData, mapView]',
      ]),
    );
  });

  test('server cache guard rejects legacy source-map reads', () {
    final violations = _serverMapCacheBoundaryViolations(
      source:
          '$_validServerMapCacheFixture\n'
          'void leak(_LoadedServerMap loaded) {\n'
          '  consume(loaded.legacyMapData);\n'
          '}',
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations.where(
        (violation) => violation.contains('must not reference legacyMapData'),
      ),
      isNotEmpty,
    );
  });

  test('server cache guard rejects a static raw-map cache', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture.replaceFirst(
        'final MapReadView mapView;',
        'static MapData? rawMap;\n  final MapReadView mapView;',
      ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'MapData',
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      containsAll([
        'fixture.dart must not reference MapData',
        'fixture.dart _LoadedServerMap must cache only one mapView field; '
            'found [rawMap, mapView]',
      ]),
    );
  });

  test('server cache guard rejects aliasing the mutable source map', () {
    final violations = _serverMapCacheBoundaryViolations(
      source: _validServerMapCacheFixture.replaceFirst(
        'validateMapDataTileInvariants(sourceMapData);',
        'final rawAlias = sourceMapData;\n'
            '    validateMapDataTileInvariants(sourceMapData);',
      ),
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'MapData',
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      contains(
        'fixture.dart _loadServerMap must not retain or alias sourceMapData',
      ),
    );
  });

  test('server cache guard rejects a second load hidden in a helper', () {
    final violations = _serverMapCacheBoundaryViolations(
      source:
          '$_validServerMapCacheFixture\n'
          'Future<Object> loadAndHide() async {\n'
          '  final dynamic hidden = await catalog.loadAssetMap("other");\n'
          '  return hidden;\n'
          '}',
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'MapData',
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      contains(
        'fixture.dart server reducer library must call loadAssetMap exactly '
        'once; found 2',
      ),
    );
  });

  test('server cache guard rejects retaining a map loader tear-off', () {
    final violations = _serverMapCacheBoundaryViolations(
      source:
          '$_validServerMapCacheFixture\n'
          'void retainLoader() {\n'
          '  final loader = catalog.loadAssetMap;\n'
          '  consume(loader);\n'
          '}',
      path: 'fixture.dart',
      forbiddenTypeNames: const {
        'MapData',
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );

    expect(
      violations,
      contains(
        'fixture.dart server reducer library must reference loadAssetMap '
        'exactly once; found 2',
      ),
    );
  });

  test('server reducer guard rejects wide map contracts outside cache', () {
    const reducerSource = '''
class ServerReducer {
  void _applyTurnCommand({required WorldMap mapView}) {}
}
''';
    final dependencyViolations = _serverReducerLibraryDependencyViolations(
      {_serverReducerPath: reducerSource},
      forbiddenTypeNames: const {
        'WorldMap',
        'WorldMapReadView',
        'LegacyWorldMapAdapter',
      },
    );
    final contractViolations = _serverReducerMapContractViolations({
      _serverReducerPath: reducerSource,
      _serverReducerOutcomePath: '''
extension Outcome on ServerReducer {
  void _gameOutcome({required MapReadView mapView}) {}
}
''',
    });

    expect(
      dependencyViolations,
      contains('$_serverReducerPath must not reference WorldMap'),
    );
    expect(
      contractViolations,
      contains(
        '$_serverReducerPath _applyTurnCommand.mapView must have type '
        'MapReadView; found WorldMap',
      ),
    );
  });
}

const _validServerMapCacheFixture = '''
extension ServerMapCache on ServerReducer {
  Future<_LoadedServerMap> _loadServerMap(String mapName) async {
    final sourceMapData = await catalog.loadAssetMap(mapName);
    validateMapDataTileInvariants(sourceMapData);
    final mapView = sourceMapData.indexedReadView();
    return _LoadedServerMap(mapView);
  }
}

final class _LoadedServerMap {
  const _LoadedServerMap(this.mapView);

  final MapReadView mapView;
}
''';
