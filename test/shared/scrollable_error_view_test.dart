import 'package:aonw/shared/widgets/scrollable_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long messages scroll instead of overflowing in landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const longPath =
        '/very/long/path/Library/Developer/CoreSimulator/Devices/'
        '61342490-9CCE-4097-BECB-6906DD2661D4/data/Containers/Bundle/'
        'Application/C9BA70BC-695B-45BE-B8F7-A193EE0B7F1B/Runner.app/'
        'Frameworks/objective_c.framework/objective_c';
    final message = List.filled(
      8,
      'Load failed: Invalid argument(s): $longPath',
    ).join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollableErrorView(
            message: message,
            actionLabel: 'RETRY',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('RETRY'), findsOneWidget);
  });
}
