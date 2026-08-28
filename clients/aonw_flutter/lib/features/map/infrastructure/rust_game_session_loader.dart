import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';

import '../application/map_session_port.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import 'map_reference_bundle_loader.dart';
import 'map_view_mapper.dart';
import 'player_map_view_mapper.dart';
import 'recipient_projection_cache.dart';

typedef RustSessionFactory = Future<AonwRustSession?> Function();

final class PreparedRustGameSession {
  const PreparedRustGameSession({
    required this.session,
    required this.scene,
    required this.cache,
  });

  final AonwRustSession session;
  final MapScene scene;
  final RecipientProjectionCache cache;
}

final class RustGameSessionLoader {
  RustGameSessionLoader({
    required AssetBundle assets,
    required RustSessionFactory sessionFactory,
    required MapViewMapper mapMapper,
    required PlayerMapViewMapper playerMapper,
  }) : _assets = assets,
       _sessionFactory = sessionFactory,
       _mapMapper = mapMapper,
       _playerMapper = playerMapper,
       _bundleLoader = MapReferenceBundleLoader(assets);

  final AssetBundle _assets;
  final RustSessionFactory _sessionFactory;
  final MapViewMapper _mapMapper;
  final PlayerMapViewMapper _playerMapper;
  final MapReferenceBundleLoader _bundleLoader;

  Future<PreparedRustGameSession> prepare(MapAssetPaths assets) async {
    final candidate = await _sessionFactory();
    if (candidate == null) {
      throw const MapLoadException(
        code: 'rust_adapter_unavailable',
        message: 'The Rust map adapter is unavailable on this platform.',
      );
    }
    try {
      return await _prepare(candidate, assets);
    } on MapLoadException {
      await candidate.close();
      rethrow;
    } on FormatException catch (error, stackTrace) {
      await candidate.close();
      throw MapLoadException(
        code: 'invalid_map_protocol',
        message: 'The map data is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } on Object {
      await candidate.close();
      rethrow;
    }
  }

  Future<PreparedRustGameSession> _prepare(
    AonwRustSession candidate,
    MapAssetPaths assets,
  ) async {
    await _verifyCapabilities(candidate);
    final document = await _assets.loadString(assets.document);
    final scenario = await _assets.loadString(assets.scenarioDocument);
    final map = await _inspectMap(candidate, document);
    final snapshot = await _openPlayer(
      candidate,
      mapDocument: document,
      scenarioDocument: scenario,
      actorPlayerId: assets.actorPlayerId,
    );
    final player = _playerMapper.fromWire(
      snapshot,
      map: map,
      actorPlayerId: assets.actorPlayerId,
    );
    final reference = await _bundleLoader.load(
      manifestAsset: assets.bundleManifest,
      map: map,
    );
    return PreparedRustGameSession(
      session: candidate,
      scene: MapScene(map: map, reference: reference, player: player),
      cache: RecipientProjectionCache.open(snapshot: snapshot, map: map),
    );
  }

  Future<AonwPlayerViewSnapshot> _openPlayer(
    AonwRustSession candidate, {
    required String mapDocument,
    required String scenarioDocument,
    required String actorPlayerId,
  }) async {
    final opened = await candidate.send(
      AonwClientRequest.openSession(
        mapDocument: mapDocument,
        scenarioDocument: scenarioDocument,
        actorPlayerId: actorPlayerId,
      ),
    );
    _loadResponse<AonwSessionOpenedResponse>(
      opened,
      'The local game session could not be opened.',
    );
    final snapshot = await candidate.send(AonwClientRequest.snapshot());
    return _loadResponse<AonwSnapshotResponse>(
      snapshot,
      'The player view could not be loaded.',
    ).snapshot;
  }

  Future<MapView> _inspectMap(
    AonwRustSession candidate,
    String document,
  ) async {
    final response = await candidate.send(
      AonwClientRequest.inspectMap(mapDocument: document),
    );
    final inspected = _loadResponse<AonwMapInspectedResponse>(
      response,
      'The map could not be opened.',
    );
    return _mapMapper.fromWire(inspected.map);
  }

  static T _loadResponse<T extends AonwClientResponseBody>(
    AonwClientResponse response,
    String message,
  ) {
    if (!response.isSuccess) {
      final error = response.error!;
      throw MapLoadException(
        code: error.code,
        message: message,
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    return response.require<T>();
  }

  static Future<void> _verifyCapabilities(AonwRustSession candidate) async {
    final response = await candidate.send(AonwClientRequest.capabilities());
    if (!response.isSuccess) {
      final error = response.error!;
      throw MapLoadException(
        code: 'rust_capability_mismatch',
        message: 'The native game adapter is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    final capabilities = response.require<AonwCapabilitiesResponse>();
    final missing = _requiredClientFeatures.difference(
      capabilities.features.toSet(),
    );
    if (missing.isEmpty) return;
    throw MapLoadException(
      code: 'rust_capability_mismatch',
      message: 'The native game adapter is incompatible with this client.',
      diagnosticCause: StateError(
        'Missing Rust client capabilities: '
        '${missing.map((feature) => feature.name).join(', ')}',
      ),
      diagnosticStackTrace: StackTrace.current,
    );
  }
}

const _requiredClientFeatures = <AonwClientFeature>{
  AonwClientFeature.inspectMap,
  AonwClientFeature.snapshot,
  AonwClientFeature.reachable,
  AonwClientFeature.routePlan,
  AonwClientFeature.moveUnit,
  AonwClientFeature.unitActions,
};
