import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_canvas.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import 'starter_map_golden_support.dart';

void main() {
  testWidgets('freezes every current map rendering layer', (tester) async {
    final loaded = await loadStarterMapGoldenFixture(tester);
    final map = loaded.map;
    final reference = loaded.reference;
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
    final stamp = starterMapGoldenStamp(map.contentHash);
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
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
    stamp: starterMapGoldenStamp(map.contentHash),
    turn: 1,
    pendingAction: null,
    units: units,
  ),
);
