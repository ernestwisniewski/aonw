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
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns the shared starter MapView identity', (tester) async {
    final loadedMap = await tester.runAsync(_loadStarter);
    expect(loadedMap, isNotNull);
    final identity =
        jsonDecode(
              File(
                '../../aonw_tests/fixtures/maps/aonw2_starter/'
                'map_view_identity.v1.json',
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

  testWidgets('opens the recipient-safe starter session snapshot', (
    tester,
  ) async {
    final repository = RustMapRepository(assets: _FileAssetBundle());
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
    );

    await tester.pumpWidget(
      MaterialApp(
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

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
