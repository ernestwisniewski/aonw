import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
  testWidgets('opens the map route and fails closed for an unknown route', (
    tester,
  ) async {
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      session: session,
      movement: session,
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-viewport')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    Navigator.of(tester.element(find.text('Settings'))).pop();
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const ValueKey('map-viewport')));
    Navigator.of(context).pushNamed('/future-screen');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unknown-route')), findsOneWidget);
    expect(find.text('Unknown route: /future-screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('uses Polish app shell and map translations', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      session: session,
      movement: session,
    );

    await tester.pumpWidget(
      AonwApp(mapController: controller, locale: const Locale('pl')),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Mapa test-map, 3 na 2 heksów'),
      findsOneWidget,
    );

    final context = tester.element(find.byKey(const ValueKey('map-viewport')));
    Navigator.of(context).pushNamed('/future-screen');
    await tester.pumpAndSettle();

    expect(find.text('Strona niedostępna'), findsOneWidget);
    expect(find.text('Nieznana trasa: /future-screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    semantics.dispose();
  });
}
