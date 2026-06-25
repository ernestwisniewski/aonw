import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionIcon', () {
    testWidgets('compact density renders compact tile', (tester) async {
      await _pump(tester, density: SelectionDensity.compact);

      expect(tester.getSize(find.byType(SelectionIcon)), const Size.square(56));
    });

    testWidgets('comfortable density renders large tile', (tester) async {
      await _pump(tester, density: SelectionDensity.comfortable);

      expect(tester.getSize(find.byType(SelectionIcon)), const Size.square(72));
    });
  });
}

Future<void> _pump(WidgetTester tester, {required SelectionDensity density}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectionIcon(
          density: density,
          icon: GameIcons.terrain,
          color: Colors.amber,
        ),
      ),
    ),
  );
}
