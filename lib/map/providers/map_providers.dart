import 'package:aonw/map/application/map_repository.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/persistence/local_map_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_providers.g.dart';

Duration? _doNotRetry(int retryCount, Object error) => null;

@riverpod
MapRepository mapRepository(Ref ref) => const LocalMapRepository();

@riverpod
Future<List<MapSelection>> availableMaps(Ref ref) =>
    ref.watch(mapRepositoryProvider).listAvailableMaps();

@Riverpod(retry: _doNotRetry)
Future<MapData> activeMap(Ref ref, MapSelection selection) =>
    ref.watch(mapRepositoryProvider).loadMap(selection);

@Riverpod(retry: _doNotRetry)
Future<String?> mapImagePath(Ref ref, MapSelection selection) =>
    ref.watch(mapRepositoryProvider).resolveImagePath(selection);
