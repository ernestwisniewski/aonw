import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/unit_actions/application/unit_action_session_port.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';

MapScene testMapScene({
  int cols = 3,
  int rows = 2,
  String? mapId,
  String? contentHash,
  double defaultZoom = 1,
  List<VisibleUnitView> units = const [],
}) {
  final terrains = MapTerrain.values;
  final tiles = <MapTileView>[];
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final terrain = terrains[(row * cols + col) % terrains.length];
      tiles.add(
        MapTileView(
          coordinate: (col: col, row: row),
          displayTerrain: terrain,
          yieldTerrain: terrain,
          movementTerrains: [terrain],
          terrainTags: [terrain],
          resources: const [],
          height: 0,
        ),
      );
    }
  }
  return MapScene(
    map: MapView(
      mapId: mapId ?? (cols == 7 && rows == 7 ? 'aonw2_starter' : 'test-map'),
      contentHash: contentHash ?? 'a' * 64,
      gridLayout: MapGridLayout.oddQFlatTop,
      cols: cols,
      rows: rows,
      defaultZoom: defaultZoom,
      tiles: tiles,
      objectives: const [],
    ),
    reference: MapReferenceBundle(
      mapId: mapId ?? (cols == 7 && rows == 7 ? 'aonw2_starter' : 'test-map'),
      mapContentHash: contentHash ?? 'a' * 64,
      worldWidth: 120 + (cols - 1) * 90,
      worldHeight: 103.92304845413263 * (rows + (cols > 1 ? 0.5 : 0)),
      pages: const [],
    ),
    player: PlayerMapView(
      actorPlayerId: 'preview-player',
      stamp: SessionStampView(
        revision: 0,
        stateDigest: 'b' * 64,
        mapHash: contentHash ?? 'a' * 64,
        rulesetHash: 'c' * 64,
      ),
      turn: 1,
      pendingAction: null,
      units: units,
    ),
  );
}

VisibleUnitView testVisibleUnit({
  String id = 'preview-commander',
  String ownerPlayerId = 'preview-player',
  MapHexCoordinate coordinate = (col: 0, row: 0),
  int movementUnits = 12,
}) => VisibleUnitView(
  id: id,
  ownerPlayerId: ownerPlayerId,
  kind: VisibleUnitKind.commander,
  name: 'Commander',
  coordinate: coordinate,
  movementUnits: movementUnits,
  posture: VisibleUnitPosture.active,
);

SessionStampView testSessionStamp({int revision = 0, String? stateDigest}) =>
    SessionStampView(
      revision: revision,
      stateDigest: stateDigest ?? 'b' * 64,
      mapHash: 'a' * 64,
      rulesetHash: 'c' * 64,
    );

ReachableView testReachableView({
  String unitId = 'preview-commander',
  List<ReachableTileView> tiles = const [
    ReachableTileView(
      coordinate: (col: 1, row: 0),
      costUnits: 4,
      exhaustsMovement: false,
    ),
  ],
}) => ReachableView(
  stamp: testSessionStamp(),
  unitId: unitId,
  availableMovementUnits: 12,
  tiles: tiles,
);

RoutePlanView testRoutePlanView({
  String unitId = 'preview-commander',
  MapHexCoordinate origin = (col: 0, row: 0),
  MapHexCoordinate target = (col: 1, row: 0),
}) => RoutePlanView(
  stamp: testSessionStamp(),
  unitId: unitId,
  target: target,
  destination: target,
  totalCostUnits: 4,
  availableMovementUnits: 12,
  remainingMovementUnits: 8,
  steps: [
    MovementStepView(
      coordinate: origin,
      enterCostUnits: 0,
      cumulativeCostUnits: 0,
    ),
    MovementStepView(
      coordinate: target,
      enterCostUnits: 4,
      cumulativeCostUnits: 4,
    ),
  ],
);

MoveUnitExecutionView testMoveUnitExecutionView({
  String unitId = 'preview-commander',
  MapHexCoordinate from = const (col: 0, row: 0),
  MapHexCoordinate to = const (col: 1, row: 0),
}) => MoveUnitExecutionView(
  events: [UnitMovedEventView(unitId: unitId, from: from, to: to)],
  evidence: UnitMovementEvidenceView(
    unitId: unitId,
    from: from,
    steps: [
      MovementStepView(
        coordinate: to,
        enterCostUnits: 4,
        cumulativeCostUnits: 4,
      ),
    ],
  ),
);

final class FakeGameSession
    implements MapSessionPort, MovementSessionPort, UnitActionSessionPort {
  FakeGameSession.success(
    this.scene, {
    this.reachableResult,
    this.routeResult,
    this.moveResult,
    this.moveFailure,
    this.unitActionResult,
    this.unitActionFailure,
  }) : failure = null;
  FakeGameSession.failure(this.failure)
    : scene = null,
      reachableResult = null,
      routeResult = null,
      moveResult = null,
      moveFailure = null,
      unitActionResult = null,
      unitActionFailure = null;

  final MapScene? scene;
  final MapLoadException? failure;
  final ReachableView? reachableResult;
  final RoutePlanView? routeResult;
  final MoveUnitResultView? moveResult;
  final MovementSessionException? moveFailure;
  final UnitActionResultView? unitActionResult;
  final UnitActionSessionException? unitActionFailure;
  var unitActionCalls = 0;
  UnitActionKindView? lastUnitAction;
  int? lastUnitActionExpectedRevision;
  String? lastUnitActionUnitId;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final error = failure;
    if (error != null) throw error;
    return scene!;
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) async => reachableResult ?? (throw StateError('No reachable fixture.'));

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async => routeResult ?? (throw StateError('No route fixture.'));

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async {
    final error = moveFailure;
    if (error != null) throw error;
    return moveResult ?? (throw StateError('No move fixture.'));
  }

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) async {
    unitActionCalls += 1;
    lastUnitAction = action;
    lastUnitActionExpectedRevision = expectedRevision;
    lastUnitActionUnitId = unitId;
    final error = unitActionFailure;
    if (error != null) throw error;
    return unitActionResult ?? (throw StateError('No unit action fixture.'));
  }

  @override
  Future<void> close() async {}
}
