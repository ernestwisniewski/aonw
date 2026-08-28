import 'package:aonw_flutter/features/unit_actions/application/action_deck_state.dart';
import 'package:aonw_flutter/features/unit_actions/presentation/unit_action_deck.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('renders localized focusable actions and dispatches one intent', (
    tester,
  ) async {
    UnitActionKindView? dispatched;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: UnitActionDeck(
            state: const ActionDeckViewState(unitId: 'unit-1'),
            onAction: (action) => dispatched = action,
          ),
        ),
      ),
    );

    expect(find.text('Unit actions'), findsOneWidget);
    expect(find.text('Fortify'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Cancel action'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey(('unit-action', 'fortify'))));
    expect(dispatched, UnitActionKindView.fortify);
  });

  testWidgets('blocks actions while pending and exposes a typed failure', (
    tester,
  ) async {
    var dispatches = 0;
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: UnitActionDeck(
              state: const ActionDeckViewState(
                unitId: 'unit-1',
                inFlightAction: UnitActionKindView.skip,
                failure: UnitActionFailure.rejected(
                  UnitActionRejectionCodeView.unitBusy,
                ),
              ),
              onAction: (_) => dispatches += 1,
            ),
          ),
        ),
      ),
    );

    final fortify = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey(('unit-action', 'fortify'))),
    );
    expect(fortify.onPressed, isNull);
    expect(find.bySemanticsLabel('Executing unit action'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    expect(
      find.text('That unit is busy and cannot perform this action now.'),
      findsOneWidget,
    );
    expect(dispatches, 0);
  });
}
