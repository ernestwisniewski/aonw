import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_map_repository.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_canvas.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('returns the shared starter MapView identity', (tester) async {
    final loadedMap = await tester.runAsync(_loadStarter);
    expect(loadedMap, isNotNull);
    final identity =
        jsonDecode(
              File(
                '../../aonw_tests/fixtures/maps/aonw2_starter/'
                'map_view_identity.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final map = loadedMap!;

    expect(map.mapId, identity['mapId']);
    expect(map.contentHash, identity['contentHash']);
    expect(map.cols, identity['cols']);
    expect(map.rows, identity['rows']);
    expect(map.gridLayout.name, identity['gridLayout']);
  });

  testWidgets('runs the recipient-safe starter movement session', (
    tester,
  ) async {
    var backendCreations = 0;
    late _TrackingRustSession backend;
    final repository = RustMapRepository(
      assets: _FileAssetBundle(),
      sessionFactory: () async {
        backendCreations += 1;
        final native = await createAonwRustSession();
        if (native == null) return null;
        backend = _TrackingRustSession(native);
        return backend;
      },
    );
    addTearDown(repository.close);

    final scene = await tester.runAsync(
      () => repository.load(MapAssetPaths.starter),
    );

    expect(scene, isNotNull);
    expect(scene!.player.stamp.mapHash, scene.map.contentHash);
    expect(scene.player.stamp.revision, 0);
    expect(scene.player.units, hasLength(1));
    expect(scene.player.units.single.id, 'preview-commander');
    expect(scene.player.units.single.ownerPlayerId, 'preview-player');
    expect(scene.player.units.single.coordinate, (col: 2, row: 1));

    final reachable = await tester.runAsync(
      () => repository.reachable(
        expectedRevision: scene.player.stamp.revision,
        unitId: 'preview-commander',
      ),
    );
    expect(reachable, isNotNull);
    expect(reachable!.tiles, isNotEmpty);
    final route = await tester.runAsync(
      () => repository.routePlan(
        expectedRevision: scene.player.stamp.revision,
        unitId: 'preview-commander',
        target: (col: 2, row: 2),
      ),
    );
    expect(route, isNotNull);
    expect(route!.steps.first.coordinate, (col: 2, row: 1));
    expect(route.steps.last.coordinate, (col: 2, row: 2));
    final moved = await tester.runAsync(
      () => repository.moveUnit(
        expectedRevision: scene.player.stamp.revision,
        unitId: 'preview-commander',
        target: route.target,
      ),
    );
    expect(moved, isNotNull);
    expect(moved!.accepted, isTrue);
    expect(moved.player!.stamp.revision, 1);
    expect(moved.player!.units.single.coordinate, (col: 2, row: 2));
    final rejected = await tester.runAsync(
      () => repository.moveUnit(
        expectedRevision: 0,
        unitId: 'preview-commander',
        target: (col: 2, row: 1),
      ),
    );
    expect(rejected, isNotNull);
    expect(rejected!.accepted, isFalse);
    expect(rejected.rejectionCode, CommandRejectionCodeView.staleRevision);
    expect(backendCreations, 1);
    expect(backend.requestTypes, [
      'inspectMap',
      'openSession',
      'snapshot',
      'query',
      'query',
      'dispatch',
      'snapshot',
      'dispatch',
    ]);
    await tester.runAsync(repository.close);
    expect(backend.closeCalls, 1);
  });

  testWidgets('renders the Rust-backed 40 by 30 Dravonia map', (tester) async {
    final loadedMap = await tester.runAsync(_loadDravonia);
    expect(loadedMap, isNotNull);
    final map = loadedMap!;
    final bounds = AonwOddQFlatTopGeometry(
      cols: map.cols,
      rows: map.rows,
      radius: aonwMapHexRadius,
    ).bounds;
    final snapshot = MapRenderSnapshot(
      map: map,
      interaction: const MapInteractionState(referenceVisible: false),
      reference: MapReferenceBundle(
        mapId: map.mapId,
        mapContentHash: map.contentHash,
        worldWidth: bounds.width,
        worldHeight: bounds.height,
        pages: const [],
      ),
      player: _emptyPlayer(map.contentHash),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        home: InteractiveViewer(
          constrained: false,
          child: MapCanvas(
            snapshot: snapshot,
            onHover: (_) {},
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(map.mapId, 'dravonia');
    expect(map.cols, 40);
    expect(map.rows, 30);
    expect(map.tiles, hasLength(1200));
    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<MapView?> _loadStarter() =>
    _loadMap('../../content/maps/aonw2_starter/map.json');

Future<MapView?> _loadDravonia() async {
  return _loadMap('../../content/maps/dravonia/map.json');
}

Future<MapView?> _loadMap(String path) async {
  final session = await createAonwRustSession();
  if (session == null) return null;
  try {
    final document = File(path).readAsStringSync();
    final response = await session.send(
      AonwClientRequest.inspectMap(mapDocument: document),
    );
    return const MapViewMapper().fromWire(
      response.require<AonwMapInspectedResponse>().map,
    );
  } finally {
    await session.close();
  }
}

PlayerMapView _emptyPlayer(String mapHash) => PlayerMapView(
  actorPlayerId: 'preview-player',
  stamp: SessionStampView(
    revision: 0,
    stateDigest: 'b' * 64,
    mapHash: mapHash,
    rulesetHash: 'c' * 64,
  ),
  turn: 1,
  pendingAction: null,
  units: const [],
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

final class _TrackingRustSession implements AonwRustSession {
  _TrackingRustSession(this._delegate);

  final AonwRustSession _delegate;
  final requestTypes = <String>[];
  var closeCalls = 0;

  @override
  Future<String> requestJson(String request) {
    final envelope = jsonDecode(request) as Map<String, dynamic>;
    final body = envelope['request'] as Map<String, dynamic>;
    requestTypes.add(body['type'] as String);
    return _delegate.requestJson(request);
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
    await _delegate.close();
  }
}
