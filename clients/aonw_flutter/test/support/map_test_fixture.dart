import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';

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
        behaviorVersion: 1,
        revision: 0,
        stateDigest: 'b' * 64,
        mapHash: contentHash ?? 'a' * 64,
        rulesetHash: 'c' * 64,
      ),
      turn: 1,
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

SessionStampView testSessionStamp({int revision = 0}) => SessionStampView(
  behaviorVersion: 1,
  revision: revision,
  stateDigest: 'b' * 64,
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

final class FakeMapRepository implements MapRepository {
  FakeMapRepository.success(
    this.scene, {
    this.reachableResult,
    this.routeResult,
    this.moveResult,
  }) : failure = null;
  FakeMapRepository.failure(this.failure)
    : scene = null,
      reachableResult = null,
      routeResult = null,
      moveResult = null;

  final MapScene? scene;
  final MapLoadException? failure;
  final ReachableView? reachableResult;
  final RoutePlanView? routeResult;
  final MoveUnitResultView? moveResult;

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
  }) async => moveResult ?? (throw StateError('No move fixture.'));

  @override
  Future<void> close() async {}
}
