import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionActionBar', () {
    testWidgets('renders info chips and command actions with shared extents', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionActionBar(
              chips: const [
                SelectionInfoChipViewModel(
                  id: SelectionInfoChipId.terrain,
                  icon: GameIcons.terrain,
                  label: 'Terrain',
                ),
              ],
              openChipId: SelectionInfoChipId.terrain,
              onToggleChip: (_) {},
              actions: [
                SelectionCommandChip(
                  icon: GameIcons.move,
                  actionId: 'move',
                  label: 'Move',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('selectionInfo.chip.terrain'))),
        const Size.square(SelectionActionBar.infoChipExtent),
      );
      expect(
        tester.getSize(find.byKey(const Key('selectionInfo.action.move'))),
        const Size(
          SelectionActionBar.actionChipWidth,
          SelectionActionBar.actionChipHeight,
        ),
      );
    });

    testWidgets('omits itself when there are no chips or actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SelectionActionBar(
              chips: const [],
              openChipId: null,
              onToggleChip: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SelectionActionBar), findsOneWidget);
      expect(find.byKey(const Key('selectionInfo.group.info')), findsNothing);
      expect(
        find.byKey(const Key('selectionInfo.group.actions')),
        findsNothing,
      );
    });
  });
}
