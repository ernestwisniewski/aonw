part of 'server_command_reducer.dart';

extension _ServerCommandReducerMapCache on ServerCommandReducer {
  Future<_LoadedServerMap> _loadServerMap(String rawMapName) {
    final mapName = rawMapName.trim();
    final cached = _loadedMaps[mapName];
    if (cached != null) return cached;

    final source = Future<_LoadedServerMap>.sync(() async {
      final worldMap = await _mapCatalog.loadAssetMap(mapName);
      return _LoadedServerMap(
        worldMap.mapName == null
            ? worldMap.copyWith(mapName: mapName)
            : worldMap,
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
  const _LoadedServerMap(this.mapView);

  final WorldMap mapView;
}
