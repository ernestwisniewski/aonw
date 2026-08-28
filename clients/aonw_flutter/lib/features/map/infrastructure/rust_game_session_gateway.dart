import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';

import '../../combat/application/combat_session_port.dart';
import '../../combat/infrastructure/rust_combat_gateway.dart';
import '../../combat/read_model/combat_view.dart';
import '../../logistics/application/unit_logistics_session_port.dart';
import '../../logistics/infrastructure/rust_unit_logistics_gateway.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../turns/application/turn_session_port.dart';
import '../../turns/infrastructure/rust_turn_gateway.dart';
import '../../turns/read_model/turn_command_view.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../unit_actions/infrastructure/rust_unit_action_gateway.dart';
import '../../unit_actions/infrastructure/unit_action_view_mapper.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../application/map_session_port.dart';
import '../application/movement_session_port.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';
import 'map_view_mapper.dart';
import 'player_map_view_mapper.dart';
import 'recipient_projection_cache.dart';
import 'rust_game_session_context.dart';
import 'rust_game_session_loader.dart';
import 'rust_movement_gateway.dart';

final class RustGameSessionGateway
    implements
        MapSessionPort,
        MovementSessionPort,
        CombatSessionPort,
        UnitLogisticsSessionPort,
        TurnSessionPort,
        UnitActionSessionPort {
  RustGameSessionGateway({
    required AssetBundle assets,
    RustSessionFactory sessionFactory = createAonwRustSession,
    MapViewMapper mapper = const MapViewMapper(),
    PlayerMapViewMapper playerMapper = const PlayerMapViewMapper(),
    RustMovementGateway movementGateway = const RustMovementGateway(),
    RustCombatGateway combatGateway = const RustCombatGateway(),
    RustTurnGateway turnGateway = const RustTurnGateway(),
    RustUnitLogisticsGateway logisticsGateway =
        const RustUnitLogisticsGateway(),
    UnitActionViewMapper unitActionMapper = const UnitActionViewMapper(),
  }) : _loader = RustGameSessionLoader(
         assets: assets,
         sessionFactory: sessionFactory,
         mapMapper: mapper,
         playerMapper: playerMapper,
       ),
       _playerMapper = playerMapper,
       _movementGateway = movementGateway,
       _combatGateway = combatGateway,
       _turnGateway = turnGateway,
       _logisticsGateway = logisticsGateway,
       _unitActions = RustUnitActionGateway(
         playerMapper: playerMapper,
         mapper: unitActionMapper,
       );

  final RustGameSessionLoader _loader;
  final PlayerMapViewMapper _playerMapper;
  final RustMovementGateway _movementGateway;
  final RustCombatGateway _combatGateway;
  final RustTurnGateway _turnGateway;
  final RustUnitLogisticsGateway _logisticsGateway;
  final RustUnitActionGateway _unitActions;
  AonwRustSession? _session;
  MapView? _map;
  PlayerMapView? _player;
  RecipientProjectionCache? _cache;
  String? _actorPlayerId;
  Future<void> _requestTail = Future<void>.value();
  var _loadGeneration = 0;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final generation = ++_loadGeneration;
    final prepared = await _loader.prepare(assets);
    var retained = false;
    try {
      await _activate(prepared, assets.actorPlayerId, generation);
      retained = true;
      return prepared.scene;
    } finally {
      if (!retained) await prepared.session.close();
    }
  }

  Future<void> _activate(
    PreparedRustGameSession prepared,
    String actorPlayerId,
    int generation,
  ) async {
    _ensureCurrentLoad(generation);
    await _requestTail;
    _ensureCurrentLoad(generation);
    final previous = _session;
    if (previous != null) await previous.close();
    _ensureCurrentLoad(generation);
    _session = prepared.session;
    _map = prepared.scene.map;
    _player = prepared.scene.player;
    _cache = prepared.cache;
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

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) => _serialize(
    () => _movementGateway.reachable(
      context: _context(),
      expectedRevision: expectedRevision,
      unitId: unitId,
      send: _send,
    ),
  );

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => _serialize(
    () => _movementGateway.routePlan(
      context: _context(),
      expectedRevision: expectedRevision,
      unitId: unitId,
      target: target,
      send: _send,
    ),
  );

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => _serialize(
    () => _movementGateway.moveUnit(
      context: _context(),
      expectedRevision: expectedRevision,
      unitId: unitId,
      target: target,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  }) => _serialize(
    () => _combatGateway.preview(
      context: _context(),
      expectedRevision: expectedRevision,
      attackerUnitId: attackerUnitId,
      defender: defender,
      send: _send,
    ),
  );

  @override
  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  }) => _serialize(
    () => _combatGateway.attack(
      context: _context(),
      expectedRevision: expectedRevision,
      attack: attack,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<UnitLogisticsOptionsView> unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) => _serialize(
    () => _logisticsGateway.options(
      context: _context(),
      expectedRevision: expectedRevision,
      unitId: unitId,
      send: _send,
    ),
  );

  @override
  Future<UnitLogisticsCommandResultView> executeUnitLogistics({
    required int expectedRevision,
    required UnitLogisticsActionView action,
  }) => _serialize(
    () => _logisticsGateway.execute(
      context: _context(),
      expectedRevision: expectedRevision,
      action: action,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) => _serialize(() async {
    try {
      return await _unitActions.execute(
        context: _context(),
        expectedRevision: expectedRevision,
        unitId: unitId,
        action: action,
        retainPlayer: _retainPlayer,
      );
    } on MovementSessionException catch (error) {
      throw UnitActionSessionException(
        code: error.code,
        message: 'The unit action request could not be completed.',
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
        resyncedPlayer: error.resyncedPlayer,
      );
    }
  });

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      _serialize(
        () => _turnGateway.execute(
          context: _context(),
          expectedRevision: expectedRevision,
          send: _send,
          applyPatch: _applyCommandPatch,
        ),
      );

  @override
  Future<void> close() async {
    _loadGeneration += 1;
    final session = _session;
    _session = null;
    _map = null;
    _player = null;
    _cache = null;
    _actorPlayerId = null;
    await _requestTail;
    if (session != null) await session.close();
  }

  RustGameSessionContext _context() {
    final session = _session;
    final map = _map;
    final player = _player;
    final cache = _cache;
    final actorPlayerId = _actorPlayerId;
    if (session == null ||
        map == null ||
        player == null ||
        cache == null ||
        actorPlayerId == null) {
      throw const MovementSessionException(
        code: 'session_not_open',
        message: 'The local game session is not open.',
      );
    }
    return (
      session: session,
      map: map,
      player: player,
      cache: cache,
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
      throw MovementSessionException(
        code: error.code,
        message: 'The movement request could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    return response;
  }

  Future<PlayerMapView> _applyCommandPatch(
    RustGameSessionContext context,
    AonwCommandResult command,
  ) async {
    try {
      final snapshot = context.cache.apply(command);
      final player = _playerMapper.fromWire(
        snapshot,
        map: context.map,
        actorPlayerId: context.actorPlayerId,
      );
      _player = player;
      return player;
    } on FormatException catch (error, stackTrace) {
      final resyncedPlayer = await _resync(context);
      throw MovementSessionException(
        code: 'recipient_resynchronized',
        message:
            'The recipient view was resynchronized after an invalid patch.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
        resyncedPlayer: resyncedPlayer,
      );
    }
  }

  Future<PlayerMapView> _resync(RustGameSessionContext context) async {
    final response = await _send(context.session, AonwClientRequest.snapshot());
    final snapshot = response.require<AonwSnapshotResponse>().snapshot;
    context.cache.replaceAfterResync(snapshot);
    final player = _playerMapper.fromWire(
      snapshot,
      map: context.map,
      actorPlayerId: context.actorPlayerId,
    );
    _player = player;
    return player;
  }

  void _retainPlayer(PlayerMapView player) => _player = player;

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _requestTail.then((_) => operation());
    _requestTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
