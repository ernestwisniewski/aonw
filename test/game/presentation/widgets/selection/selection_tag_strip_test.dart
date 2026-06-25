import 'package:aonw/game/presentation/widgets/bottom_toolbar/hex_presentation/hex_tag_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionTagStrip', () {
    testWidgets('compact density shows one tight tag', (tester) async {
      await _pump(tester, density: SelectionDensity.compact);

      expect(find.text('FERTILE FIELD'), findsOneWidget);
      expect(find.text('DEFENSIVE POSITION'), findsNothing);
      expect(_firstTagSize(tester).height, 23);
    });

    testWidgets('comfortable density shows two roomier tags', (tester) async {
      await _pump(tester, density: SelectionDensity.comfortable);

      expect(find.text('FERTILE FIELD'), findsOneWidget);
      expect(find.text('DEFENSIVE POSITION'), findsOneWidget);
      expect(_firstTagSize(tester).height, 28);
    });
  });
}

Size _firstTagSize(WidgetTester tester) {
  return tester.getSize(
    find
        .ancestor(
          of: find.text('FERTILE FIELD'),
          matching: find.byType(Container),
        )
        .first,
  );
}

Future<void> _pump(WidgetTester tester, {required SelectionDensity density}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectionTagStrip(
          density: density,
          tags: const [
            HexTagViewModel(
              label: 'Fertile field',
              icon: GameIcons.food,
              color: Colors.green,
            ),
            HexTagViewModel(
              label: 'Defensive position',
              icon: GameIcons.defense,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    ),
  );
}
