import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_board.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates regular and compact board metrics from tree positions', () {
    const cards = [
      TechnologyCardViewModel(
        id: TechnologyId.agriculture,
        state: TechnologyCardState.available,
        progress: 0,
        baseCost: 6,
        totalCost: 6,
        turnsRemaining: 3,
        boostActive: false,
      ),
      TechnologyCardViewModel(
        id: TechnologyId.mining,
        state: TechnologyCardState.locked,
        progress: 0,
        baseCost: 7,
        totalCost: 7,
        turnsRemaining: 4,
        boostActive: false,
        treeColumn: 2,
        treeRow: 1,
      ),
    ];

    final regular = TechnologyTreeBoardMetrics.fromCards(cards, compact: false);
    final compact = TechnologyTreeBoardMetrics.fromCards(cards, compact: true);

    expect(regular.nodeWidth, 194);
    expect(regular.nodeHeight, 174);
    expect(regular.horizontalGap, 52);
    expect(regular.width, 16 * 2 + 3 * 194 + 2 * 52);
    expect(regular.height, 16 * 2 + 2 * 174 + 18);
    expect(
      regular.rects[TechnologyId.mining],
      const Rect.fromLTWH(16 + 2 * (194 + 52), 16 + 174 + 18, 194, 174),
    );

    expect(compact.nodeWidth, 164);
    expect(compact.nodeHeight, 164);
    expect(compact.horizontalGap, 34);
    expect(compact.width, 16 * 2 + 3 * 164 + 2 * 34);
    expect(compact.height, 16 * 2 + 2 * 164 + 18);
  });

  testWidgets('routes node, details and research taps through callbacks', (
    tester,
  ) async {
    final verticalController = ScrollController();
    final horizontalController = ScrollController();
    addTearDown(verticalController.dispose);
    addTearDown(horizontalController.dispose);

    TechnologyId? selectedTechnologyId;
    TechnologyId? detailsTechnologyId;
    TechnologyId? researchedTechnologyId;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 360,
            child: Builder(
              builder: (context) {
                return TechnologyTreeBoard(
                  cards: const [
                    TechnologyCardViewModel(
                      id: TechnologyId.agriculture,
                      state: TechnologyCardState.available,
                      progress: 0,
                      baseCost: 6,
                      totalCost: 6,
                      turnsRemaining: 3,
                      boostActive: false,
                    ),
                  ],
                  selectedTechnologyId: null,
                  hasDetailsLayer: false,
                  compact: false,
                  pathAnimation: const AlwaysStoppedAnimation<double>(0),
                  verticalController: verticalController,
                  horizontalController: horizontalController,
                  l10n: AppLocalizations.of(context),
                  onTechnologySelected: (card) =>
                      selectedTechnologyId = card.id,
                  onTechnologyDetails: (card) => detailsTechnologyId = card.id,
                  onBuildingDetails: (_) {},
                  onUnitDetails: (_) {},
                  onResearch: (technologyId) =>
                      researchedTechnologyId = technologyId,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Agriculture'), findsOneWidget);

    await tester.tap(find.text('Agriculture'));
    await tester.pump();
    expect(selectedTechnologyId, TechnologyId.agriculture);

    await tester.tap(find.byTooltip('Technology details'));
    await tester.pump();
    expect(detailsTechnologyId, TechnologyId.agriculture);

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(researchedTechnologyId, TechnologyId.agriculture);
  });

  testWidgets('shows a draggable bottom scrollbar for horizontal overflow', (
    tester,
  ) async {
    final verticalController = ScrollController();
    final horizontalController = ScrollController();
    addTearDown(verticalController.dispose);
    addTearDown(horizontalController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 360,
            child: Builder(
              builder: (context) {
                return TechnologyTreeBoard(
                  cards: const [
                    TechnologyCardViewModel(
                      id: TechnologyId.agriculture,
                      state: TechnologyCardState.available,
                      progress: 0,
                      baseCost: 6,
                      totalCost: 6,
                      turnsRemaining: 3,
                      boostActive: false,
                    ),
                    TechnologyCardViewModel(
                      id: TechnologyId.mining,
                      state: TechnologyCardState.locked,
                      progress: 0,
                      baseCost: 7,
                      totalCost: 7,
                      turnsRemaining: 4,
                      boostActive: false,
                      treeColumn: 3,
                    ),
                  ],
                  selectedTechnologyId: null,
                  hasDetailsLayer: false,
                  compact: true,
                  pathAnimation: const AlwaysStoppedAnimation<double>(0),
                  verticalController: verticalController,
                  horizontalController: horizontalController,
                  l10n: AppLocalizations.of(context),
                  onTechnologySelected: (_) {},
                  onTechnologyDetails: (_) {},
                  onBuildingDetails: (_) {},
                  onUnitDetails: (_) {},
                  onResearch: (_) {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollbar = find.byKey(
      const Key('technologyTreeBoard.horizontalScrollbar'),
    );
    expect(scrollbar, findsOneWidget);
    expect(
      find.byKey(const Key('technologyTreeBoard.horizontalScrollbar.track')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('technologyTreeBoard.horizontalScrollbar.thumb')),
      findsOneWidget,
    );

    await tester.drag(scrollbar, const Offset(120, 0));
    await tester.pump();

    expect(horizontalController.offset, greaterThan(0));
  });

  testWidgets('renders an empty state without scrollable board chrome', (
    tester,
  ) async {
    final verticalController = ScrollController();
    final horizontalController = ScrollController();
    addTearDown(verticalController.dispose);
    addTearDown(horizontalController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TechnologyTreeBoard(
                cards: const [],
                selectedTechnologyId: null,
                hasDetailsLayer: false,
                compact: false,
                pathAnimation: const AlwaysStoppedAnimation<double>(0),
                verticalController: verticalController,
                horizontalController: horizontalController,
                l10n: AppLocalizations.of(context),
                onTechnologySelected: (_) {},
                onTechnologyDetails: (_) {},
                onBuildingDetails: (_) {},
                onUnitDetails: (_) {},
                onResearch: (_) {},
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('No technologies to display'), findsOneWidget);
    expect(find.textContaining('provides technologies'), findsOneWidget);
    expect(find.byType(Scrollbar), findsNothing);
  });
}
