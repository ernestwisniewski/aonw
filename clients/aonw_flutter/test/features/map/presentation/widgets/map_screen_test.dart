import 'package:aonw_flutter/features/map/application/map_controller.dart';
import 'package:aonw_flutter/features/map/application/map_repository.dart';
import 'package:aonw_flutter/features/map/presentation/camera/map_viewport_projection.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
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
