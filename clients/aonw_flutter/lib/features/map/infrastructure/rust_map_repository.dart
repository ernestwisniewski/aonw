import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';

import '../application/map_repository.dart';
import '../read_model/map_scene.dart';
import 'map_reference_bundle_loader.dart';
import 'map_view_mapper.dart';
import 'player_map_view_mapper.dart';

typedef RustSessionFactory = Future<AonwRustSession?> Function();

final class RustMapRepository implements MapRepository {
  RustMapRepository({
    required AssetBundle assets,
    RustSessionFactory sessionFactory = createAonwRustSession,
    MapViewMapper mapper = const MapViewMapper(),
    PlayerMapViewMapper playerMapper = const PlayerMapViewMapper(),
  }) : _assets = assets,
       _sessionFactory = sessionFactory,
       _mapper = mapper,
       _playerMapper = playerMapper,
       _bundleLoader = MapReferenceBundleLoader(assets);

  final AssetBundle _assets;
  final RustSessionFactory _sessionFactory;
  final MapViewMapper _mapper;
  final PlayerMapViewMapper _playerMapper;
  final MapReferenceBundleLoader _bundleLoader;
  AonwRustSession? _session;
  var _loadGeneration = 0;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final generation = ++_loadGeneration;
    final candidate = await _sessionFactory();
    if (candidate == null) {
      throw const MapLoadException(
        code: 'rust_adapter_unavailable',
        message: 'The Rust map adapter is unavailable on this platform.',
      );
    }
    var retained = false;
    try {
      final document = await _assets.loadString(assets.document);
      final scenario = await _assets.loadString(assets.scenarioDocument);
      final response = await candidate.send(
        AonwClientRequest.inspectMap(mapDocument: document),
      );
      if (!response.isSuccess) {
        final error = response.error!;
        throw MapLoadException(
          code: error.code,
          message: 'The map could not be opened.',
          diagnosticCause: error,
          diagnosticStackTrace: StackTrace.current,
        );
      }
      final wire = response.require<AonwMapInspectedResponse>().map;
      final map = _mapper.fromWire(wire);
      final opened = await candidate.send(
        AonwClientRequest.openSession(
          mapDocument: document,
          scenarioDocument: scenario,
          actorPlayerId: assets.actorPlayerId,
        ),
      );
      if (!opened.isSuccess) {
        final error = opened.error!;
        throw MapLoadException(
          code: error.code,
          message: 'The local game session could not be opened.',
          diagnosticCause: error,
          diagnosticStackTrace: StackTrace.current,
        );
      }
      opened.require<AonwSessionOpenedResponse>();
      final snapshotResponse = await candidate.send(
        AonwClientRequest.snapshot(),
      );
      if (!snapshotResponse.isSuccess) {
        final error = snapshotResponse.error!;
        throw MapLoadException(
          code: error.code,
          message: 'The player view could not be loaded.',
          diagnosticCause: error,
          diagnosticStackTrace: StackTrace.current,
        );
      }
      final player = _playerMapper.fromWire(
        snapshotResponse.require<AonwSnapshotResponse>().snapshot,
        map: map,
      );
      final reference = await _bundleLoader.load(
        manifestAsset: assets.bundleManifest,
        map: map,
      );
      if (generation != _loadGeneration) {
        throw const MapLoadException(
          code: 'map_load_superseded',
          message: 'A newer map load replaced this request.',
        );
      }
      final previous = _session;
      if (previous != null) await previous.close();
      if (generation != _loadGeneration) {
        throw const MapLoadException(
          code: 'map_load_superseded',
          message: 'A newer map load replaced this request.',
        );
      }
      _session = candidate;
      retained = true;
      return MapScene(map: map, reference: reference, player: player);
    } on MapLoadException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw MapLoadException(
        code: 'invalid_map_protocol',
        message: 'The map data is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } finally {
      if (!retained) await candidate.close();
    }
  }

  @override
  Future<void> close() async {
    _loadGeneration += 1;
    final session = _session;
    _session = null;
    if (session != null) await session.close();
  }
}
