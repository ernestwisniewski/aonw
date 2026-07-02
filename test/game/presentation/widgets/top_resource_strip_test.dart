import 'package:aonw/game/presentation/widgets/hud/outcome/hud_victory_status_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget pumpStrip({
    int gold = 120,
    int goldPerTurn = 7,
    int goldIncome = 9,
    int unitUpkeep = 2,
    int sciencePerTurn = 5,
    int stabilityNet = 4,
    StabilityBand stabilityBand = StabilityBand.stable,
    int resourceTotal = 3,
    int resourceTypes = 2,
    TopResourcePopupType? openBreakdown,
    HudVictoryStatusSummary? victoryStatus,
    String? playerName,
    Color? playerColor,
    int? turnNumber,
    VoidCallback? onGoldPressed,
    VoidCallback? onSciencePressed,
    VoidCallback? onStabilityPressed,
    VoidCallback? onResourcesPressed,
    VoidCallback? onVictoryPressed,
    VoidCallback? onTurnPressed,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TopResourceStrip(
          gold: gold,
          goldPerTurn: goldPerTurn,
          goldIncome: goldIncome,
          unitUpkeep: unitUpkeep,
          sciencePerTurn: sciencePerTurn,
          stabilityNet: stabilityNet,
          stabilityBand: stabilityBand,
          resourceTotal: resourceTotal,
          resourceTypes: resourceTypes,
          openBreakdown: openBreakdown,
          victoryStatus: victoryStatus,
          playerName: playerName,
          playerColor: playerColor,
          turnNumber: turnNumber,
          onTurnPressed: onTurnPressed,
          onGoldPressed: onGoldPressed ?? () {},
          onSciencePressed: onSciencePressed ?? () {},
          onStabilityPressed: onStabilityPressed ?? () {},
          onResourcesPressed: onResourcesPressed ?? () {},
          onVictoryPressed: onVictoryPressed ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders resource values and handles taps', (tester) async {
    var goldTaps = 0;
    var scienceTaps = 0;
    var stabilityTaps = 0;
    var resourceTaps = 0;

    await tester.pumpWidget(
      pumpStrip(
        openBreakdown: TopResourcePopupType.gold,
        onGoldPressed: () => goldTaps++,
        onSciencePressed: () => scienceTaps++,
        onStabilityPressed: () => stabilityTaps++,
        onResourcesPressed: () => resourceTaps++,
      ),
    );

    expect(find.text('120'), findsOneWidget);
    expect(find.text('▲ +7'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gameHud.resource.gold')));
    await tester.tap(find.byKey(const Key('gameHud.resource.science')));
    await tester.tap(find.byKey(const Key('gameHud.resource.stability')));
    await tester.tap(find.byKey(const Key('gameHud.resource.resources')));

    expect(goldTaps, 1);
    expect(scienceTaps, 1);
    expect(stabilityTaps, 1);
    expect(resourceTaps, 1);
  });

  testWidgets(
    'renders resource pills directly on the map without strip panel',
    (tester) async {
      await tester.pumpWidget(pumpStrip(turnNumber: 23));

      expect(
        find.ancestor(
          of: find.byKey(const Key('gameHud.resource.singleRow')),
          matching: find.byType(DecoratedBox),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('shows gold without turn delta when net is zero', (tester) async {
    await tester.pumpWidget(
      pumpStrip(
        gold: 42,
        goldPerTurn: 0,
        goldIncome: 0,
        unitUpkeep: 0,
        sciencePerTurn: 0,
        resourceTotal: 0,
        resourceTypes: 0,
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('▲ +0'), findsNothing);
    expect(find.text('▼ 0'), findsNothing);
  });

  testWidgets('uses semantic arrows for positive and negative deltas', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpStrip(
        gold: 42,
        goldPerTurn: -3,
        goldIncome: 1,
        unitUpkeep: 4,
        sciencePerTurn: 0,
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('▼ -3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('keeps gold delta visible on tiny phone width', (tester) async {
    _setViewSize(tester, const Size(359, 720));

    await tester.pumpWidget(pumpStrip());

    final scienceFinder = find.byKey(const Key('gameHud.resource.science'));

    expect(find.text('120'), findsOneWidget);
    expect(
      find.descendant(of: scienceFinder, matching: find.text('5')),
      findsNothing,
    );
    expect(
      find.descendant(of: scienceFinder, matching: find.text('+5')),
      findsOneWidget,
    );
    expect(find.text('▲ +7'), findsOneWidget);
  });

  testWidgets('warns when treasury projects below zero within three turns', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpStrip(gold: 5, goldPerTurn: -2, goldIncome: 0, unitUpkeep: 2),
    );

    final tooltip = tester.widget<Tooltip>(_goldTooltipFinder);

    expect(tooltip.message, contains('bankruptcy risk within 3 turns'));
  });

  testWidgets(
    'uses a pulsing red border instead of red fill for negative gold',
    (tester) async {
      await tester.pumpWidget(
        pumpStrip(gold: -4, goldPerTurn: 2, goldIncome: 4, unitUpkeep: 2),
      );

      final tooltip = tester.widget<Tooltip>(_goldTooltipFinder);
      final initialDecoration = _resourcePillDecoration(
        tester,
        const Key('gameHud.resource.gold'),
      );
      final initialBorder = initialDecoration.border! as Border;

      expect(find.text('-4'), findsOneWidget);
      expect(tooltip.message, contains('treasury below zero'));
      expect(initialDecoration.color, SurfaceElevation.floating.fill());
      expect(initialDecoration.color, isNot(GameUiTheme.danger.withAlpha(210)));
      expect(initialDecoration.boxShadow, hasLength(1));
      expect(initialBorder.top.color, GameUiTheme.danger.withAlpha(160));
      expect(initialBorder.top.width, 1.5);

      await tester.pump(const Duration(milliseconds: 410));

      final pulsedDecoration = _resourcePillDecoration(
        tester,
        const Key('gameHud.resource.gold'),
      );
      final pulsedBorder = pulsedDecoration.border! as Border;

      expect(pulsedDecoration.color, SurfaceElevation.floating.fill());
      expect(pulsedDecoration.boxShadow, hasLength(1));
      expect(pulsedBorder.top.color, isNot(initialBorder.top.color));
      expect(pulsedBorder.top.width, greaterThan(initialBorder.top.width));
    },
  );

  testWidgets('keeps normal gold tooltip when treasury has three-turn runway', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpStrip(gold: 10, goldPerTurn: -3, goldIncome: 0, unitUpkeep: 3),
    );

    final tooltip = tester.widget<Tooltip>(_goldTooltipFinder);

    expect(tooltip.message, isNot(contains('bankruptcy risk')));
  });

  testWidgets('opens resource info bottom sheet on long press', (tester) async {
    var goldTaps = 0;

    await tester.pumpWidget(
      pumpStrip(
        gold: 42,
        goldPerTurn: -3,
        goldIncome: 1,
        unitUpkeep: 4,
        sciencePerTurn: 6,
        resourceTotal: 2,
        resourceTypes: 1,
        openBreakdown: TopResourcePopupType.science,
        onGoldPressed: () => goldTaps++,
      ),
    );

    await tester.longPress(find.byKey(const Key('gameHud.resource.gold')));
    await tester.pumpAndSettle();

    expect(find.text('Gold'), findsOneWidget);
    expect(
      find.text('Gold: 42 • income +1 • upkeep -4 • net -3 / turn'),
      findsOneWidget,
    );
    expect(find.text('Show details'), findsOneWidget);

    await tester.tap(find.text('Show details'));
    await tester.pumpAndSettle();

    expect(goldTaps, 1);
  });

  group('turn pill', () {
    testWidgets('shows compact turn beside resources without player chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        pumpStrip(
          playerName: 'Alice',
          playerColor: const Color(0xFF4a7fc4),
          turnNumber: 23,
        ),
      );

      expect(find.byKey(const Key('gameHud.resource.identity')), findsNothing);
      expect(find.byKey(const Key('gameHud.resource.turn')), findsOneWidget);
      expect(find.text('Alice · T23'), findsNothing);
      expect(find.text('T23'), findsOneWidget);
    });

    testWidgets('renders turn number only', (tester) async {
      await tester.pumpWidget(pumpStrip(turnNumber: 23));

      expect(find.byKey(const Key('gameHud.resource.identity')), findsNothing);
      expect(find.byKey(const Key('gameHud.resource.turn')), findsOneWidget);
      expect(find.text('T23'), findsOneWidget);
    });

    testWidgets('delegates taps to the turn timeline action', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        pumpStrip(turnNumber: 23, onTurnPressed: () => taps++),
      );

      await tester.tap(find.byKey(const Key('gameHud.resource.turn')));

      expect(taps, 1);
    });

    testWidgets('is hidden when turn is absent', (tester) async {
      await tester.pumpWidget(pumpStrip());

      expect(find.byKey(const Key('gameHud.resource.identity')), findsNothing);
      expect(find.byKey(const Key('gameHud.resource.turn')), findsNothing);
    });
  });

  group('research status', () {
    testWidgets('does not render a top research pill', (tester) async {
      await tester.pumpWidget(pumpStrip());

      expect(find.byKey(const Key('gameHud.resource.research')), findsNothing);
      expect(find.textContaining('Choose research'), findsNothing);
    });
  });

  group('victory status', () {
    const victoryStatus = HudVictoryStatusSummary(
      primaryLabel: 'DOM 6%',
      compactLabel: '6%',
      secondaryLabel: 'ALICE / 60%',
      tooltip: 'Domination: Alice kontroluje 6% mapy.',
      critical: false,
    );

    testWidgets('uses only compact percentage text in portrait mode', (
      tester,
    ) async {
      _setViewSize(tester, const Size(390, 844));

      await tester.pumpWidget(pumpStrip(victoryStatus: victoryStatus));

      final victoryFinder = find.byKey(const Key('gameHud.victoryStatus'));

      expect(victoryFinder, findsOneWidget);
      expect(
        find.descendant(of: victoryFinder, matching: find.text('6%')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: victoryFinder,
          matching: find.textContaining('DOM'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: victoryFinder,
          matching: find.textContaining('ALICE'),
        ),
        findsNothing,
      );
    });

    testWidgets('delegates taps for the victory popup', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        pumpStrip(victoryStatus: victoryStatus, onVictoryPressed: () => taps++),
      );

      await tester.tap(find.byKey(const Key('gameHud.victoryStatus')));

      expect(taps, 1);
    });
  });

  testWidgets('keeps resources and turn in the top row at 360 px', (
    tester,
  ) async {
    _setViewSize(tester, const Size(360, 640));

    await tester.pumpWidget(
      pumpStrip(
        playerName: 'Alice',
        playerColor: const Color(0xFF4a7fc4),
        turnNumber: 23,
      ),
    );

    final identityFinder = find.byKey(const Key('gameHud.resource.identity'));
    final goldFinder = find.byKey(const Key('gameHud.resource.gold'));
    final scienceFinder = find.byKey(const Key('gameHud.resource.science'));
    final resourcesFinder = find.byKey(const Key('gameHud.resource.resources'));
    final turnFinder = find.byKey(const Key('gameHud.resource.turn'));
    final researchFinder = find.byKey(const Key('gameHud.resource.research'));

    expect(identityFinder, findsNothing);
    expect(goldFinder, findsOneWidget);
    expect(scienceFinder, findsOneWidget);
    expect(resourcesFinder, findsOneWidget);
    expect(turnFinder, findsOneWidget);
    expect(researchFinder, findsNothing);

    final goldRect = tester.getRect(goldFinder);
    final scienceRect = tester.getRect(scienceFinder);
    final resourcesRect = tester.getRect(resourcesFinder);
    final turnRect = tester.getRect(turnFinder);

    expect((scienceRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
    expect((resourcesRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
    expect((turnRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
    expect(turnRect.right, greaterThan(resourcesRect.right));
  });

  testWidgets('keeps turn beside resources on medium portrait widths', (
    tester,
  ) async {
    _setViewSize(tester, const Size(840, 1436));

    await tester.pumpWidget(
      pumpStrip(
        playerName: 'A Very Long Civilization Name',
        playerColor: const Color(0xFF4a7fc4),
        turnNumber: 23,
      ),
    );

    expect(find.byKey(const Key('gameHud.resource.identity')), findsNothing);
    final goldRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.gold')),
    );
    final scienceRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.science')),
    );
    final resourcesRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.resources')),
    );
    final turnRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.turn')),
    );

    expect((scienceRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
    expect((resourcesRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
    expect((turnRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
  });

  testWidgets('keeps resources and turn in one row on wide layouts', (
    tester,
  ) async {
    _setViewSize(tester, const Size(1000, 900));

    await tester.pumpWidget(
      pumpStrip(
        playerName: 'Alice',
        playerColor: const Color(0xFF4a7fc4),
        turnNumber: 23,
      ),
    );

    expect(find.byKey(const Key('gameHud.resource.identity')), findsNothing);
    final goldRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.gold')),
    );
    final turnRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.turn')),
    );

    expect((turnRect.center.dy - goldRect.center.dy).abs(), lessThan(1));
    expect(turnRect.right, greaterThan(goldRect.right));
  });
}

Finder get _goldTooltipFinder => find.descendant(
  of: find.byKey(const Key('gameHud.resource.gold')),
  matching: find.byType(Tooltip),
);

BoxDecoration _resourcePillDecoration(WidgetTester tester, Key resourceKey) {
  final surfaceFinder = find.descendant(
    of: find.byKey(resourceKey),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.constraints?.minHeight == 34 &&
          widget.constraints?.maxHeight == 34 &&
          widget.decoration is BoxDecoration,
    ),
  );

  expect(surfaceFinder, findsOneWidget);
  return tester.widget<Container>(surfaceFinder).decoration! as BoxDecoration;
}

void _setViewSize(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(() {
    tester.view
      ..resetPhysicalSize()
      ..resetDevicePixelRatio();
  });
}
