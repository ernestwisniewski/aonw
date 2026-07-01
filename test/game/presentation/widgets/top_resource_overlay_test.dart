import 'package:aonw/game/presentation/widgets/hud/outcome/hud_victory_status_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_overlay.dart';
import 'package:aonw/game/presentation/widgets/resources/top_resource_strip.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TopResourceOverlay renders strip and delegates resource taps', (
    tester,
  ) async {
    var goldTaps = 0;
    var scienceTaps = 0;
    var resourceTaps = 0;
    var victoryTaps = 0;

    await _pumpOverlay(
      tester,
      victoryStatus: _victoryStatus,
      onGoldPressed: () => goldTaps++,
      onSciencePressed: () => scienceTaps++,
      onResourcesPressed: () => resourceTaps++,
      onVictoryPressed: () => victoryTaps++,
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('▲ +3'), findsOneWidget);
    expect(find.text('+6'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gameHud.resource.gold')));
    await tester.tap(find.byKey(const Key('gameHud.resource.science')));
    await tester.tap(find.byKey(const Key('gameHud.resource.resources')));
    await tester.tap(find.byKey(const Key('gameHud.victoryStatus')));

    expect(goldTaps, 1);
    expect(scienceTaps, 1);
    expect(resourceTaps, 1);
    expect(victoryTaps, 1);
  });

  testWidgets('TopResourceOverlay keeps menu-matched top margin', (
    tester,
  ) async {
    await _pumpOverlay(tester);

    final stripRect = tester.getRect(
      find.byKey(const Key('gameHud.resource.strip')),
    );

    expect(stripRect.top, 10);
  });

  testWidgets('TopResourceOverlay shows popup and closes from backdrop', (
    tester,
  ) async {
    var closes = 0;

    await _pumpOverlay(
      tester,
      openBreakdown: TopResourcePopupType.resources,
      onCloseBreakdown: () => closes++,
    );

    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.resources')),
      findsOneWidget,
    );
    expect(find.text('Resources'), findsOneWidget);

    await tester.tapAt(const Offset(30, 250));

    expect(closes, 1);
  });

  testWidgets(
    'TopResourceOverlay uses swipeable bottom sheet on portrait phone',
    (tester) async {
      var closes = 0;

      await _pumpOverlay(
        tester,
        size: const Size(390, 844),
        openBreakdown: TopResourcePopupType.gold,
        onCloseBreakdown: () => closes++,
      );

      final sheet = find.byKey(
        const Key('gameHud.resourceBreakdownSheet.gold'),
      );
      expect(sheet, findsOneWidget);
      expect(
        find.byKey(const Key('gameHud.resourceBreakdown.gold')),
        findsOneWidget,
      );
      final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
      expect(slide.duration, GameMotion.snap);
      expect(slide.curve, GameMotion.enter);

      await tester.drag(sheet, const Offset(0, 90));
      await tester.pump();

      expect(closes, 1);
    },
  );

  testWidgets('TopResourceOverlay shows victory popup and closes backdrop', (
    tester,
  ) async {
    var closes = 0;

    await _pumpOverlay(
      tester,
      victoryStatus: _victoryStatus,
      openBreakdown: TopResourcePopupType.victory,
      onCloseBreakdown: () => closes++,
    );

    expect(
      find.byKey(const Key('gameHud.resourceBreakdown.victory')),
      findsOneWidget,
    );
    final popup = find.byKey(const Key('gameHud.resourceBreakdown.victory'));
    expect(find.text('Game goal'), findsOneWidget);
    expect(
      find.descendant(of: popup, matching: find.text('DOM 6% · ALICE / 60%')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: popup,
        matching: find.text('Domination: Alice controls 6% of the map.'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: popup, matching: find.text('Control')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: popup, matching: find.text('6% / 60%')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(30, 250));

    expect(closes, 1);
  });

  testWidgets('TopResourceOverlay forwards turn without research pill', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      playerName: 'Alice',
      playerColor: const Color(0xFF4a7fc4),
      turnNumber: 23,
      activeTechnologyName: 'Bronze',
      activeTechnologyTurnsRemaining: 4,
    );

    expect(find.byKey(const Key('gameHud.resource.identity')), findsNothing);
    expect(find.byKey(const Key('gameHud.resource.turn')), findsOneWidget);
    expect(find.text('Alice · T23'), findsNothing);
    expect(find.text('T23'), findsOneWidget);
    expect(find.byKey(const Key('gameHud.resource.research')), findsNothing);
    expect(find.text('Bronze · 4t'), findsNothing);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  Size? size,
  TopResourcePopupType? openBreakdown,
  HudVictoryStatusSummary? victoryStatus,
  String? playerName,
  Color? playerColor,
  int? turnNumber,
  String? activeTechnologyName,
  int? activeTechnologyTurnsRemaining,
  VoidCallback? onGoldPressed,
  VoidCallback? onSciencePressed,
  VoidCallback? onResourcesPressed,
  VoidCallback? onVictoryPressed,
  VoidCallback? onCloseBreakdown,
}) async {
  if (size != null) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
    });
  }

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox.expand(
          child: TopResourceOverlay(
            gold: 42,
            goldPerTurn: 3,
            goldIncome: 4,
            unitUpkeep: 1,
            sciencePerTurn: 6,
            stabilityNet: 0,
            stabilityBand: StabilityBand.stable,
            resourceInventory: const CityResourceInventory(
              playerId: 'player_1',
              countsByType: {ResourceType.iron: 2},
              sources: [],
            ),
            openBreakdown: openBreakdown,
            victoryStatus: victoryStatus,
            playerName: playerName,
            playerColor: playerColor,
            turnNumber: turnNumber,
            goldBreakdown: const GoldBreakdown(
              treasury: 42,
              citySources: [],
              projectSources: [],
              upkeep: UnitUpkeepBreakdown(
                playerId: 'player_1',
                unitCount: 0,
                freeUnitCount: 0,
                paidUnitCount: 0,
                grossUpkeep: 0,
              ),
            ),
            scienceBreakdown: const ScienceYieldBreakdown(
              total: 6,
              byCityId: {},
              sources: [],
            ),
            cities: const [],
            activeTechnologyName: activeTechnologyName,
            activeTechnologyTurnsRemaining: activeTechnologyTurnsRemaining,
            l10n: AppLocalizationsEn(),
            onGoldPressed: onGoldPressed ?? () {},
            onSciencePressed: onSciencePressed ?? () {},
            onResourcesPressed: onResourcesPressed ?? () {},
            onVictoryPressed: onVictoryPressed ?? () {},
            onCloseBreakdown: onCloseBreakdown ?? () {},
          ),
        ),
      ),
    ),
  );
}

const _victoryStatus = HudVictoryStatusSummary(
  primaryLabel: 'DOM 6%',
  compactLabel: '6%',
  secondaryLabel: 'ALICE / 60%',
  tooltip: 'Domination: Alice controls 6% of the map.',
  critical: false,
  details: [
    HudVictoryStatusDetail(label: 'Control', value: '6% / 60%'),
    HudVictoryStatusDetail(label: 'Hold', value: 'below threshold'),
  ],
);
