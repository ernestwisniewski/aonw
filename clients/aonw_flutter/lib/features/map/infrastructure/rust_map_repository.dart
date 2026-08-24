import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';

import '../application/map_repository.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';
import 'map_reference_bundle_loader.dart';
import 'map_view_mapper.dart';
import 'movement_view_mapper.dart';
import 'player_map_view_mapper.dart';

typedef RustSessionFactory = Future<AonwRustSession?> Function();

final class RustMapRepository implements MapRepository {
  RustMapRepository({
    required AssetBundle assets,
    RustSessionFactory sessionFactory = createAonwRustSession,
    MapViewMapper mapper = const MapViewMapper(),
    PlayerMapViewMapper playerMapper = const PlayerMapViewMapper(),
    MovementViewMapper movementMapper = const MovementViewMapper(),
  }) : _assets = assets,
       _sessionFactory = sessionFactory,
       _mapper = mapper,
       _playerMapper = playerMapper,
       _movementMapper = movementMapper,
       _bundleLoader = MapReferenceBundleLoader(assets);

  final AssetBundle _assets;
  final RustSessionFactory _sessionFactory;
  final MapViewMapper _mapper;
  final PlayerMapViewMapper _playerMapper;
  final MovementViewMapper _movementMapper;
  final MapReferenceBundleLoader _bundleLoader;
  AonwRustSession? _session;
  MapView? _map;
  PlayerMapView? _player;
  String? _actorPlayerId;
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
      final scene = await _prepareScene(candidate, assets);
      await _activate(candidate, scene, assets.actorPlayerId, generation);
      retained = true;
      return scene;
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

  Future<MapScene> _prepareScene(
    AonwRustSession candidate,
    MapAssetPaths assets,
  ) async {
    await _verifyCapabilities(candidate);
    final document = await _assets.loadString(assets.document);
    final scenario = await _assets.loadString(assets.scenarioDocument);
    final map = await _inspectMap(candidate, document, _mapper);
    final player = await _openPlayer(
      candidate,
      mapDocument: document,
      scenarioDocument: scenario,
      actorPlayerId: assets.actorPlayerId,
      map: map,
    );
    final reference = await _bundleLoader.load(
      manifestAsset: assets.bundleManifest,
      map: map,
    );
    return MapScene(map: map, reference: reference, player: player);
  }

  Future<PlayerMapView> _openPlayer(
    AonwRustSession candidate, {
    required String mapDocument,
    required String scenarioDocument,
    required String actorPlayerId,
    required MapView map,
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
    final player = _loadResponse<AonwSnapshotResponse>(
      snapshot,
      'The player view could not be loaded.',
    );
    return _playerMapper.fromWire(
      player.snapshot,
      map: map,
      actorPlayerId: actorPlayerId,
    );
  }

  Future<void> _activate(
    AonwRustSession candidate,
    MapScene scene,
    String actorPlayerId,
    int generation,
  ) async {
    _ensureCurrentLoad(generation);
    final previous = _session;
    if (previous != null) await previous.close();
    _ensureCurrentLoad(generation);
    _session = candidate;
    _map = scene.map;
    _player = scene.player;
    _actorPlayerId = actorPlayerId;
  }

  void _ensureCurrentLoad(int generation) {
    if (generation != _loadGeneration) {
      throw const MapLoadException(
        code: 'map_load_superseded',
        message: 'A newer map load replaced this request.',
      );
    }
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

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) async {
    final context = _context();
    try {
      final response = await _send(
        context.session,
        AonwClientRequest.reachable(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwReachableResult) {
        throw const FormatException('Expected a reachable result.');
      }
      return _movementMapper.reachable(
        result,
        map: context.map,
        expectedUnitId: unitId,
        expectedRevision: expectedRevision,
      );
    } on MapSessionException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw _invalidSessionResponse(error, stackTrace);
    }
  }

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async {
    final context = _context();
    try {
      final unit = _controlledUnit(context, unitId);
      final response = await _send(
        context.session,
        AonwClientRequest.routePlan(
          expectedRevision: expectedRevision,
          unitId: unitId,
          targetCol: target.col,
          targetRow: target.row,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwRoutePlanResult) {
        throw const FormatException('Expected a route-plan result.');
      }
      return _movementMapper.routePlan(
        result,
        map: context.map,
        unit: unit,
        expectedTarget: target,
        expectedRevision: expectedRevision,
      );
    } on MapSessionException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw _invalidSessionResponse(error, stackTrace);
    }
  }

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async {
    final context = _context();
    try {
      _controlledUnit(context, unitId);
      final response = await _send(
        context.session,
        AonwClientRequest.moveUnit(
          expectedRevision: expectedRevision,
          unitId: unitId,
          targetCol: target.col,
          targetRow: target.row,
        ),
      );
      final command = response.require<AonwCommandResponse>().result;
      _movementMapper.validateCommand(
        command,
        map: context.map,
        expectedUnitId: unitId,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      if (!command.accepted) {
        return MoveUnitResultView.rejected(
          code: _movementMapper.rejectionCode(command.rejection!),
        );
      }
      final snapshotResponse = await _send(
        context.session,
        AonwClientRequest.snapshot(),
      );
      final player = _playerMapper.fromWire(
        snapshotResponse.require<AonwSnapshotResponse>().snapshot,
        map: context.map,
        actorPlayerId: context.actorPlayerId,
      );
      if (player.stamp.revision != command.stamp.revision ||
          player.stamp.stateDigest != command.stamp.stateDigest) {
        throw const FormatException(
          'Command result and refreshed snapshot identities differ.',
        );
      }
      _player = player;
      return MoveUnitResultView.accepted(player: player);
    } on MapSessionException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw _invalidSessionResponse(error, stackTrace);
    }
  }

  @override
  Future<void> close() async {
    _loadGeneration += 1;
    final session = _session;
    _session = null;
    _map = null;
    _player = null;
    _actorPlayerId = null;
    if (session != null) await session.close();
  }

  ({
    AonwRustSession session,
    MapView map,
    PlayerMapView player,
    String actorPlayerId,
  })
  _context() {
    final session = _session;
    final map = _map;
    final player = _player;
    final actorPlayerId = _actorPlayerId;
    if (session == null ||
        map == null ||
        player == null ||
        actorPlayerId == null) {
      throw const MapSessionException(
        code: 'session_not_open',
        message: 'The local game session is not open.',
      );
    }
    return (
      session: session,
      map: map,
      player: player,
      actorPlayerId: actorPlayerId,
    );
  }

  static Future<AonwClientResponse> _send(
    AonwRustSession session,
    AonwClientRequest request,
  ) async {
    final response = await session.send(request);
    if (!response.isSuccess) {
      final error = response.error!;
      throw MapSessionException(
        code: error.code,
        message: 'The movement request could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    return response;
  }

  static MapSessionException _invalidSessionResponse(
    FormatException error,
    StackTrace stackTrace,
  ) => MapSessionException(
    code: 'invalid_session_protocol',
    message: 'The movement response is incompatible with this client.',
    diagnosticCause: error,
    diagnosticStackTrace: stackTrace,
  );
}

Future<void> _verifyCapabilities(AonwRustSession candidate) async {
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

Future<MapView> _inspectMap(
  AonwRustSession candidate,
  String document,
  MapViewMapper mapper,
) async {
  final response = await candidate.send(
    AonwClientRequest.inspectMap(mapDocument: document),
  );
  final inspected = RustMapRepository._loadResponse<AonwMapInspectedResponse>(
    response,
    'The map could not be opened.',
  );
  return mapper.fromWire(inspected.map);
}

const _requiredClientFeatures = <AonwClientFeature>{
  AonwClientFeature.inspectMap,
  AonwClientFeature.snapshot,
  AonwClientFeature.reachable,
  AonwClientFeature.routePlan,
  AonwClientFeature.moveUnit,
  AonwClientFeature.unitActions,
};

VisibleUnitView _controlledUnit(
  ({
    AonwRustSession session,
    MapView map,
    PlayerMapView player,
    String actorPlayerId,
  })
  context,
  String unitId,
) {
  // Unit ownership remains a recipient-view concern; Rust still validates
  // control and legality authoritatively for every query and command.
  for (final unit in context.player.units) {
    if (unit.id == unitId && unit.ownerPlayerId == context.actorPlayerId) {
      return unit;
    }
  }
  throw const FormatException(
    'Movement request references an uncontrolled or absent unit.',
  );
}
