import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_reference_bundle_loader.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_view_mapper.dart';
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

import '../../../../support/localized_test_app.dart';

void main() {
  testWidgets('freezes every current map rendering layer', (tester) async {
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
    final reference = await MapReferenceBundleLoader(rootBundle).load(
      manifestAsset: 'assets/maps/aonw2_starter/map_texture_manifest.json',
      map: map,
    );
    expect(reference.pages, hasLength(1));
    await tester.binding.setSurfaceSize(const Size(660, 728));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _expectGolden(
      tester,
      snapshot: _snapshot(
        map,
        reference: reference,
        interaction: const MapInteractionState(referenceVisible: false),
      ),
      file: 'goldens/starter_map.png',
      referenceVisible: false,
    );
    await _expectGolden(
      tester,
      snapshot: _snapshot(map, reference: reference),
      file: 'goldens/starter_map_reference.png',
      referenceVisible: true,
    );
    final stamp = _stamp(map.contentHash);
    await _expectGolden(
      tester,
      snapshot: _snapshot(
        map,
        reference: reference,
        interaction: MapInteractionState(
          hovered: (col: 4, row: 3),
          selected: (col: 3, row: 3),
          selectedUnitId: 'preview-commander',
          reachable: ReachableView(
            stamp: stamp,
            unitId: 'preview-commander',
            availableMovementUnits: 12,
            tiles: const [
              ReachableTileView(
                coordinate: (col: 4, row: 3),
                costUnits: 4,
                exhaustsMovement: false,
              ),
              ReachableTileView(
                coordinate: (col: 5, row: 3),
                costUnits: 8,
                exhaustsMovement: false,
              ),
            ],
          ),
          route: RoutePlanView(
            stamp: stamp,
            unitId: 'preview-commander',
            target: (col: 5, row: 3),
            destination: (col: 5, row: 3),
            totalCostUnits: 8,
            availableMovementUnits: 12,
            remainingMovementUnits: 4,
            steps: const [
              MovementStepView(
                coordinate: (col: 3, row: 3),
                enterCostUnits: 0,
                cumulativeCostUnits: 0,
              ),
              MovementStepView(
                coordinate: (col: 4, row: 3),
                enterCostUnits: 4,
                cumulativeCostUnits: 4,
              ),
              MovementStepView(
                coordinate: (col: 5, row: 3),
                enterCostUnits: 4,
                cumulativeCostUnits: 8,
              ),
            ],
          ),
        ),
        units: const [
          VisibleUnitView(
            id: 'preview-commander',
            ownerPlayerId: 'preview-player',
            kind: VisibleUnitKind.commander,
            name: 'Commander',
            coordinate: (col: 3, row: 3),
            movementUnits: 12,
            posture: VisibleUnitPosture.active,
          ),
        ],
      ),
      file: 'goldens/starter_map_interaction.png',
      referenceVisible: true,
    );
  });
}

Future<void> _expectGolden(
  WidgetTester tester, {
  required MapRenderSnapshot snapshot,
  required String file,
  required bool referenceVisible,
}) async {
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
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey('static-reference-layer')),
    referenceVisible ? findsOneWidget : findsNothing,
  );
  await expectLater(
    find.byKey(const ValueKey('starter-golden')),
    matchesGoldenFile(file),
  );
}

MapRenderSnapshot _snapshot(
  MapView map, {
  required MapReferenceBundle reference,
  MapInteractionState interaction = const MapInteractionState(),
  List<VisibleUnitView> units = const [],
}) => MapRenderSnapshot(
  map: map,
  interaction: interaction,
  reference: reference,
  player: PlayerMapView(
    actorPlayerId: 'preview-player',
    stamp: _stamp(map.contentHash),
    turn: 1,
    pendingAction: null,
    units: units,
  ),
);

SessionStampView _stamp(String mapHash) => SessionStampView(
  revision: 0,
  stateDigest: 'b' * 64,
  mapHash: mapHash,
  rulesetHash: 'c' * 64,
);
