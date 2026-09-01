import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';

final class MapAssetPaths {
  const MapAssetPaths({
    required this.document,
    required this.bundleManifest,
    required this.scenarioDocument,
    required this.actorPlayerId,
  });

  static const starter = MapAssetPaths(
    document: 'assets/maps/aonw2_starter/map.json',
    bundleManifest: 'assets/maps/aonw2_starter/map_texture_manifest.json',
    scenarioDocument: 'assets/scenarios/aonw2_starter.json',
    actorPlayerId: 'preview-player',
  );

  final String document;
  final String bundleManifest;
  final String scenarioDocument;
  final String actorPlayerId;
}

abstract interface class MapRepository {
  Future<MapScene> load(MapAssetPaths assets);

  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  });

  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  });

  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  });

  Future<void> close();
}

final class MapLoadException implements Exception {
  const MapLoadException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;

  @override
  String toString() => 'MapLoadException($code): $message';
}

final class MapSessionException implements Exception {
  const MapSessionException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;

  @override
  String toString() => 'MapSessionException($code): $message';
}
