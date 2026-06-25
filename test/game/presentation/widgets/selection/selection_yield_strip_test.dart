import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionYieldStrip', () {
    testWidgets('compact density uses tight metric cells', (tester) async {
      await _pump(tester, density: SelectionDensity.compact);

      expect(find.text('Potential'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(_firstMetricSize(tester).height, 32);
      expect(find.byTooltip('FOOD: 2'), findsOneWidget);
    });

    testWidgets('comfortable density uses roomier metric cells', (
      tester,
    ) async {
      await _pump(tester, density: SelectionDensity.comfortable);

      expect(find.text('Potential'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(_firstMetricSize(tester).height, 36);
      expect(find.byTooltip('Test tooltip'), findsOneWidget);
    });
  });
}

Size _firstMetricSize(WidgetTester tester) {
  return tester.getSize(
    find.ancestor(of: find.text('2'), matching: find.byType(Container)).first,
  );
}

Future<void> _pump(WidgetTester tester, {required SelectionDensity density}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 160,
          child: SelectionYieldStrip(
            density: density,
            title: 'Potential',
            tooltip: 'Test tooltip',
            items: const [
              SelectionYieldItem(
                icon: GameIcons.food,
                label: 'FOOD',
                value: 2,
                color: Colors.green,
              ),
              SelectionYieldItem(
                icon: GameIcons.production,
                label: 'PROD',
                value: 1,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
