import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpicButton', () {
    testWidgets('primary variant renders gradient and triggers onPressed', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicButton.primary(onPressed: () => taps++, label: 'GO'),
          ),
        ),
      );

      expect(find.text('GO'), findsOneWidget);
      await tester.tap(find.byType(EpicButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('disabled primary does not trigger onPressed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicButton.primary(onPressed: null, label: 'OFF'),
          ),
        ),
      );

      await tester.tap(find.byType(EpicButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('outlined variant renders double border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicButton.outlined(onPressed: () {}, label: 'CANCEL'),
          ),
        ),
      );

      final outer = tester.widget<Container>(
        find.byKey(const ValueKey('epic-button-outer')),
      );
      final inner = tester.widget<Container>(
        find.byKey(const ValueKey('epic-button-inner')),
      );
      final outerDecoration = outer.decoration! as ShapeDecoration;
      final innerDecoration = inner.decoration! as ShapeDecoration;
      final outerShape = outerDecoration.shape as RoundedRectangleBorder;
      final innerShape = innerDecoration.shape as RoundedRectangleBorder;
      expect(outerShape.side.color, GameUiTheme.gold);
      expect(innerShape.side.color, GameUiTheme.copperDeep);
    });

    testWidgets('text variant has no background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicButton.text(onPressed: () {}, label: 'LINK'),
          ),
        ),
      );

      expect(find.text('LINK'), findsOneWidget);
    });
  });
}
