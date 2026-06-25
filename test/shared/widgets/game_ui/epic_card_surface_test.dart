import 'package:aonw/shared/widgets/game_ui/epic_card_surface.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpicCardSurface', () {
    testWidgets('renders content without header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: EpicCardSurface(content: Text('hello'))),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(GoldDivider), findsNothing);
    });

    testWidgets('renders header with GoldDivider when header provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicCardSurface(header: Text('TITLE'), content: Text('body')),
          ),
        ),
      );

      expect(find.text('TITLE'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      expect(find.byType(GoldDivider), findsOneWidget);
    });

    testWidgets('shows corner diamonds by default with header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: EpicCardSurface(header: Text('T'), content: Text('c')),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('epic-card-corner-diamond-left')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('epic-card-corner-diamond-right')),
        findsOneWidget,
      );
    });

    testWidgets('hides corner diamonds when showCornerDiamonds is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicCardSurface(
              header: Text('T'),
              content: Text('c'),
              showCornerDiamonds: false,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('epic-card-corner-diamond-left')),
        findsNothing,
      );
    });

    testWidgets('auto-hides corner diamonds at width < 360', (tester) async {
      tester.view.physicalSize = const Size(300, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EpicCardSurface(header: Text('T'), content: Text('c')),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('epic-card-corner-diamond-left')),
        findsNothing,
      );
    });

    testWidgets('invokes onClose when close button tapped', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpicCardSurface(
              header: const Text('T'),
              content: const Text('c'),
              onClose: () => closed++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('epic-card-close')));
      await tester.pump();
      expect(closed, 1);
    });
  });
}
