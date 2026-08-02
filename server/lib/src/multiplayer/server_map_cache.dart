import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';

final class LoadedServerMap {
  const LoadedServerMap(this.mapView);

  final WorldMap mapView;
}

/// Loads and memoizes authoritative maps, evicting failed loads for retries.
final class ServerMapCache {
  ServerMapCache(this._mapCatalog);

  final MultiplayerMapCatalog _mapCatalog;
  final Map<String, Future<LoadedServerMap>> _loadedMaps = {};

  Future<LoadedServerMap> load(String rawMapName) {
    final mapName = rawMapName.trim();
    final cached = _loadedMaps[mapName];
    if (cached != null) return cached;

    final source = Future<LoadedServerMap>.sync(() async {
      final worldMap = await _mapCatalog.loadAssetMap(mapName);
      return LoadedServerMap(
        worldMap.mapName == null
            ? worldMap.copyWith(mapName: mapName)
            : worldMap,
      );
    });
    late final Future<LoadedServerMap> loading;
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
