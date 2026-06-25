import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/selection/selection_label_chip.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionLabelChip', () {
    testWidgets('renders icon and value text', (tester) async {
      const item = SelectionInfoItem(
        label: 'Attack',
        value: '12',
        icon: GameIcons.attack,
        color: Colors.white,
        showLabel: true,
      );

      await _pump(tester, item: item, density: SelectionDensity.compact);

      expect(find.text('Attack: 12'), findsOneWidget);
      expect(find.byType(GameIcon), findsOneWidget);
    });

    testWidgets('compact density uses 28px height', (tester) async {
      const item = SelectionInfoItem(
        label: 'X',
        value: '1',
        icon: GameIcons.defense,
        color: Colors.white,
        showLabel: false,
      );

      await _pump(tester, item: item, density: SelectionDensity.compact);

      expect(tester.getSize(find.byType(SelectionLabelChip)).height, 28);
    });

    testWidgets('comfortable density uses 36px height', (tester) async {
      const item = SelectionInfoItem(
        label: 'X',
        value: '1',
        icon: GameIcons.defense,
        color: Colors.white,
        showLabel: false,
      );

      await _pump(tester, item: item, density: SelectionDensity.comfortable);

      expect(tester.getSize(find.byType(SelectionLabelChip)).height, 36);
    });
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required SelectionInfoItem item,
  required SelectionDensity density,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectionLabelChip(item: item, density: density),
      ),
    ),
  );
}
