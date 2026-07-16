part of 'server_command_reducer.dart';

extension _ServerCommandReducerMapCache on ServerCommandReducer {
  Future<_LoadedServerMap> _loadServerMap(String rawMapName) {
    final mapName = rawMapName.trim();
    final cached = _loadedMaps[mapName];
    if (cached != null) return cached;

    final source = Future<_LoadedServerMap>.sync(() async {
      final sourceMapData = await _mapCatalog.loadAssetMap(mapName);
      sourceMapData.mapName ??= mapName;
      validateMapDataTileInvariants(sourceMapData);
      final mapView = sourceMapData.indexedReadView();
      return _LoadedServerMap(mapView);
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
  const _LoadedServerMap(this.mapView);

  // The mutable MapData container ends at load/index time; only its view is
  // retained by the reducer cache.
  final MapReadView mapView;
}
