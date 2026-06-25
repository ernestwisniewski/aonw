import 'package:aonw/game/presentation/widgets/selection/selection_command_chip.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionCommandChip', () {
    test('uses a wider labeled extent for long action labels', () {
      expect(
        SelectionCommandChip.actionExtentFor(
          label: 'Cancel city founding',
          showLabel: true,
        ),
        SelectionCommandChip.expandedLabeledExtent,
      );
      expect(
        SelectionCommandChip.actionExtentFor(
          label: 'Cancel exploration',
          showLabel: true,
        ),
        SelectionCommandChip.expandedLabeledExtent,
      );
    });

    test('uses the wide extent for the longest cancel labels', () {
      expect(
        SelectionCommandChip.actionExtentFor(
          label: 'Cancel trade route selection',
          showLabel: true,
        ),
        SelectionCommandChip.wideLabeledExtent,
      );
    });

    testWidgets('danger action renders warm red fill with dark border', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionCommandChip(
              icon: GameIcons.close,
              actionId: 'cancel',
              label: 'Cancel',
              active: true,
              showLabel: true,
              dangerOutlined: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byKey(const Key('selectionInfo.action.cancel')),
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      final dangerFill = Color.lerp(
        GameUiTheme.danger,
        GameUiTheme.copper,
        0.18,
      )!;
      final dangerBorder = Color.lerp(
        GameUiTheme.dangerSubtle,
        GameUiTheme.copperDeep,
        0.22,
      )!;

      expect(decoration.color, dangerFill.withAlpha(245));
      expect(decoration.boxShadow, isNotNull);
      expect(border.top.color, dangerBorder.withAlpha(255));
    });

    testWidgets('danger action label keeps regular action typography', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionCommandChip(
              icon: GameIcons.close,
              actionId: 'cancel',
              label: 'Cancel',
              active: true,
              showLabel: true,
              dangerOutlined: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final label = tester.widget<Text>(find.text('Cancel'));
      final icons = tester.widgetList<GameIcon>(find.byType(GameIcon));

      expect(find.text('CANCEL'), findsNothing);
      expect(label.style?.color, Colors.black);
      expect(label.style?.fontFamily, GameUiTheme.actionLabel.fontFamily);
      expect(label.style?.fontWeight, GameUiTheme.actionLabel.fontWeight);
      expect(label.style?.fontSize, GameUiTheme.actionLabel.fontSize);
      expect(label.style?.height, GameUiTheme.actionLabel.height);
      expect(label.style?.shadows, isNull);
      expect(icons.map((icon) => icon.color), everyElement(Colors.black));
      expect(
        icons.map((icon) => icon.size),
        everyElement(GameIconSize.regular),
      );
    });

    testWidgets('long danger action label renders without ellipsis', (
      tester,
    ) async {
      const label = 'Cancel trade route selection';

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionCommandChip(
              icon: GameIcons.close,
              actionId: 'cancelLongAction',
              label: label,
              active: true,
              showLabel: true,
              dangerOutlined: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final chipFinder = find.byKey(
        const Key('selectionInfo.action.cancelLongAction'),
      );
      final text = tester.widget<Text>(find.text(label));

      expect(
        tester.getSize(chipFinder).width,
        SelectionCommandChip.wideLabeledExtent,
      );
      expect(text.overflow, TextOverflow.visible);
      expect(text.data, label);
    });

    testWidgets('renders a compact numeric badge over the action icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionCommandChip(
              icon: GameIcons.attack,
              actionId: 'attack',
              label: 'Attack',
              badgeLabel: '2',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
    });
  });
}
