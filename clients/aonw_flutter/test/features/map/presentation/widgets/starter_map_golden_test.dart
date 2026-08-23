import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_canvas.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  testWidgets('starter terrain has a client-owned visual golden', (
    tester,
  ) async {
    final loadedMap = await tester.runAsync(() async {
      final session = await createAonwRustSession();
      if (session == null) return null;
      try {
        final response = await session.send(
          AonwClientRequest.inspectMap(
            mapDocument: await rootBundle.loadString(
              'assets/maps/aonw2_starter/map.json',
            ),
          ),
        );
        return const MapViewMapper().fromWire(
          response.require<AonwMapInspectedResponse>().map,
        );
      } finally {
        await session.close();
      }
    });
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
      player: PlayerMapView(
        actorPlayerId: 'preview-player',
        stamp: SessionStampView(
          behaviorVersion: 1,
          revision: 0,
          stateDigest: 'b' * 64,
          mapHash: map.contentHash,
          rulesetHash: 'c' * 64,
        ),
        units: const [],
      ),
    );
    await tester.binding.setSurfaceSize(const Size(660, 728));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      LocalizedTestApp(
        home: ColoredBox(
          color: Colors.black,
          child: RepaintBoundary(
            key: const ValueKey('starter-golden'),
            child: MapCanvas(
              snapshot: snapshot,
              onHover: (_) {},
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('starter-golden')),
      matchesGoldenFile('goldens/starter_map.png'),
    );
  });
}
