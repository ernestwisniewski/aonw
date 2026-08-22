import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_canvas.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

Future<MapView?> _loadDravonia() async {
  final session = await createAonwRustSession();
  if (session == null) return null;
  try {
    final document = File(
      '../../content/maps/dravonia/map.json',
    ).readAsStringSync();
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
