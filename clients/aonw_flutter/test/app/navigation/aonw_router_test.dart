import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/map/application/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
  testWidgets('opens the map route and fails closed for an unknown route', (
    tester,
  ) async {
    final controller = MapController(
      repository: FakeMapRepository.success(testMapScene()),
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);

    final context = tester.element(find.byKey(const ValueKey('map-canvas')));
    Navigator.of(context).pushNamed('/future-screen');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unknown-route')), findsOneWidget);
    expect(find.text('Unknown route: /future-screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
