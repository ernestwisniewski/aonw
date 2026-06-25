import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoldDivider', () {
    testWidgets('renders horizontal divider with given width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GoldDivider(width: 100))),
      );

      final box = tester.widget<SizedBox>(
        find.byKey(const ValueKey('gold-divider-root')),
      );
      expect(box.width, 100);
      expect(box.height, 9);
    });

    testWidgets('renders vertical divider with given height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GoldDivider(height: 100, axis: Axis.vertical)),
        ),
      );

      final box = tester.widget<SizedBox>(
        find.byKey(const ValueKey('gold-divider-root')),
      );
      expect(box.width, 9);
      expect(box.height, 100);
    });

    testWidgets('uses GameUiTheme.gold for the diamond', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GoldDivider(width: 50))),
      );

      final diamond = tester.widget<Container>(
        find.byKey(const ValueKey('gold-divider-diamond')),
      );
      expect(diamond.color, GameUiTheme.gold);
    });
  });
}
