import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SelectionDetailsChips renders shared label chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectionDetailsChips(
            density: SelectionDensity.compact,
            items: [
              SelectionInfoItem(
                icon: GameIcons.terrain,
                label: 'Terrain',
                value: 'Plain',
                color: Colors.green,
              ),
              SelectionInfoItem(
                icon: GameIcons.resources,
                label: 'Resources',
                value: 'Iron',
                color: Colors.amber,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SelectionLabelChip), findsNWidgets(2));
    expect(find.text('Terrain: PLAIN'), findsOneWidget);
    expect(find.text('Resources: IRON'), findsOneWidget);
  });
}
