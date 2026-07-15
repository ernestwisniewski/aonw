part of 'server_command_reducer.dart';

extension _ServerCommandReducerMapCache on ServerCommandReducer {
  Future<_LoadedServerMap> _loadServerMap(String rawMapName) {
    final mapName = rawMapName.trim();
    final cached = _loadedMaps[mapName];
    if (cached != null) return cached;

    final source = Future<_LoadedServerMap>.sync(() async {
      final sourceMapData = await _mapCatalog.loadAssetMap(mapName);
      sourceMapData.mapName ??= mapName;
      return _LoadedServerMap(
        sourceMapData,
        LegacyWorldMapAdapter.fromMapData(sourceMapData),
      );
    });
    late final Future<_LoadedServerMap> loading;
    loading = source.onError((Object error, StackTrace stackTrace) {
      if (identical(_loadedMaps[mapName], loading)) {
        unawaited(_loadedMaps.remove(mapName));
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
    _loadedMaps[mapName] = loading;
    return loading;
  }
}

final class _LoadedServerMap {
  const _LoadedServerMap(this.legacyMapData, this.canonicalWorldMap);

  // Asset maps are read-only in the reducer. Keeping this cache reducer-owned
  // avoids changing the mutable map catalog contract used by editor tooling.
  final MapData legacyMapData;
  final WorldMap canonicalWorldMap;
}
