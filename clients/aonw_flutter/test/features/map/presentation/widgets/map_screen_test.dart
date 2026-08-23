import 'package:aonw_flutter/features/map/application/map_controller.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/presentation/camera/map_viewport_projection.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('supports selection, pan, zoom and reference toggle', (
    tester,
  ) async {
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene(cols: 7, rows: 7)),
    );
    final camera = TransformationController();
    addTearDown(controller.dispose);
    addTearDown(camera.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            controller: controller,
            transformationController: camera,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const projection = MapViewportProjection(
      AonwOddQFlatTopGeometry(cols: 7, rows: 7, radius: 60),
    );
    final canvas = find.byKey(const ValueKey('map-canvas'));
    final center = projection.hexCenter((col: 3, row: 3));
    await tester.tapAt(tester.getTopLeft(canvas) + Offset(center.x, center.y));
    await tester.pump();
    expect(find.text('Hex 3, 3'), findsOneWidget);

    final beforePan = camera.value.clone();
    await tester.drag(
      find.byKey(const ValueKey('map-viewport')),
      const Offset(60, 40),
    );
    await tester.pumpAndSettle();
    expect(camera.value, isNot(equals(beforePan)));

    final beforeZoom = camera.value.getMaxScaleOnAxis();
    final viewportCenter = tester.getCenter(
      find.byKey(const ValueKey('map-viewport')),
    );
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(viewportCenter - const Offset(30, 0));
    await second.down(viewportCenter + const Offset(30, 0));
    await first.moveTo(viewportCenter - const Offset(80, 0));
    await second.moveTo(viewportCenter + const Offset(80, 0));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(camera.value.getMaxScaleOnAxis(), greaterThan(beforeZoom));

    await tester.tap(find.byKey(const ValueKey('reference-toggle')));
    await tester.pump();
    expect(
      (controller.state as MapReadyState).interaction.referenceVisible,
      isFalse,
    );
  });

  testWidgets('renders a 25 by 19 map without overflow', (tester) async {
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene(cols: 25, rows: 19)),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders reachable and route workflow with explicit confirm', (
    tester,
  ) async {
    final movedPlayer = PlayerMapView(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1),
      units: [testVisibleUnit(coordinate: (col: 1, row: 0), movementUnits: 8)],
    );
    final controller = MapController(
      repository: FakeMapRepository.success(
        testMapScene(units: [testVisibleUnit()]),
        reachableResult: testReachableView(),
        routeResult: testRoutePlanView(),
        moveResult: MoveUnitResultView.accepted(player: movedPlayer),
      ),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    const projection = MapViewportProjection(
      AonwOddQFlatTopGeometry(cols: 3, rows: 2, radius: 60),
    );
    final canvas = find.byKey(const ValueKey('map-canvas'));
    final origin = projection.hexCenter((col: 0, row: 0));
    await tester.tapAt(tester.getTopLeft(canvas) + Offset(origin.x, origin.y));
    await tester.pumpAndSettle();

    expect(find.text('Unit preview-commander'), findsOneWidget);
    expect(find.byKey(const ValueKey('movement-layer')), findsOneWidget);
    expect(find.byKey(const ValueKey('unit-layer')), findsOneWidget);

    controller.select((col: 1, row: 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('confirm-move')), findsOneWidget);
    expect(find.textContaining('Route: 4 movement units'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-move')));
    await tester.pumpAndSettle();

    final ready = controller.state as MapReadyState;
    expect(ready.scene.player.units.single.coordinate, (col: 1, row: 0));
    expect(find.byKey(const ValueKey('confirm-move')), findsNothing);
  });

  testWidgets(
    'initial camera fits authored zoom once and isolates static grid',
    (tester) async {
      final controller = MapController(
        repository: FakeMapRepository.success(
          testMapScene(cols: 7, rows: 7, defaultZoom: 1.2),
        ),
      );
      final camera = TransformationController();
      addTearDown(controller.dispose);
      addTearDown(camera.dispose);
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MapScreen(
            controller: controller,
            transformationController: camera,
          ),
        ),
      );
      await tester.pumpAndSettle();

      const geometry = AonwOddQFlatTopGeometry(cols: 7, rows: 7, radius: 60);
      final fit = 800 / geometry.bounds.height;
      expect(camera.value.getMaxScaleOnAxis(), closeTo(fit * 1.2, 1e-6));
      final initialMatrix = List<double>.of(camera.value.storage);
      final staticGrid = tester.renderObject(
        find.byKey(const ValueKey('static-grid-layer')),
      );

      controller.hover((col: 2, row: 2));
      await tester.pump();

      expect(camera.value.storage, orderedEquals(initialMatrix));
      expect(
        tester.renderObject(find.byKey(const ValueKey('static-grid-layer'))),
        same(staticGrid),
      );
      expect(find.byKey(const ValueKey('interaction-layer')), findsOneWidget);
    },
  );

  testWidgets('accepts a replacement external camera controller', (
    tester,
  ) async {
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene()),
    );
    final firstCamera = TransformationController();
    final secondCamera = TransformationController();
    addTearDown(controller.dispose);
    addTearDown(firstCamera.dispose);
    addTearDown(secondCamera.dispose);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          controller: controller,
          transformationController: firstCamera,
          autoLoad: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          controller: controller,
          transformationController: secondCamera,
          autoLoad: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(secondCamera.value, isNot(equals(Matrix4.identity())));
  });

  testWidgets('shows typed failure and retry action', (tester) async {
    final controller = MapController(
      repository: FakeMapRepository.failure(
        const MapLoadException(code: 'rust_unavailable', message: 'No Rust'),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map unavailable'), findsOneWidget);
    expect(find.text('rust_unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('exposes map semantics with reduced motion enabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MapScreen(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Map test-map, 3 by 2 hexes'), findsOneWidget);
    final canvasContext = tester.element(
      find.byKey(const ValueKey('map-canvas')),
    );
    expect(MediaQuery.disableAnimationsOf(canvasContext), isTrue);
    semantics.dispose();
  });
}
