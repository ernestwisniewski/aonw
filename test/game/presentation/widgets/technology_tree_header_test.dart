import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_header.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('TechnologyTreeHeader renders science summary and closes', (
    tester,
  ) async {
    var closes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnologyTreeHeader(
            sciencePerTurn: 7,
            l10n: l10n,
            onClose: () => closes++,
          ),
        ),
      ),
    );

    expect(find.text(l10n.technologyTreeTitle), findsOneWidget);
    expect(find.text(l10n.sciencePerTurn(7)), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.closeAction));

    expect(closes, 1);
  });

  testWidgets('TechnologyActiveResearchBanner renders turns remaining', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnologyActiveResearchBanner(
            l10n: l10n,
            card: const TechnologyCardViewModel(
              id: TechnologyId.mining,
              state: TechnologyCardState.active,
              progress: 3,
              baseCost: 8,
              totalCost: 8,
              turnsRemaining: 2,
              boostActive: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n.activeResearchLabel), findsOneWidget);
    expect(find.text('Mining'), findsOneWidget);
    expect(find.text(l10n.turnCountLabel(2)), findsOneWidget);
  });
}
