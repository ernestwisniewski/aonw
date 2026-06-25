import 'package:aonw/game/presentation/widgets/bottom_toolbar/end_turn_button.dart';
import 'package:aonw/game/presentation/widgets/hud/turn_action_hint.dart';
import 'package:aonw/game/presentation/widgets/theme/city_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _turnActions = [
  HudTurnActionOption(
    index: 0,
    label: 'Warrior 1',
    kindLabel: 'Unit',
    thumbnail: HudTurnActionThumbnail.unit(GameUnitType.warrior),
  ),
  HudTurnActionOption(
    index: 1,
    label: 'Warszawa produkcja',
    kindLabel: 'City',
    thumbnail: HudTurnActionThumbnail.city(cityVisualLevel: 1),
  ),
  HudTurnActionOption(
    index: 2,
    label: 'Choose research',
    kindLabel: 'Research',
    thumbnail: HudTurnActionThumbnail.research(TechnologyId.writing),
  ),
];

Future<void> _pumpButton(
  WidgetTester tester, {
  bool waiting = false,
  bool readyToEndTurn = true,
  int actionCount = 0,
  int currentActionIndex = -1,
  List<HudTurnActionOption> actionOptions = const [],
  String waitingForLabel = '',
  String? actionHintLabel,
  bool compact = false,
  bool showTurnLabel = true,
  double? minHeight,
  bool showActionMenu = false,
  bool pulseActionBorder = false,
  bool disableAnimations = false,
  VoidCallback? onTap,
  ValueChanged<int>? onActionSelected,
}) async {
  Widget home = Scaffold(
    body: Center(
      child: EndTurnButton(
        playerColor: const Color(0xFF4a7fc4),
        turn: 1,
        waiting: waiting,
        readyToEndTurn: readyToEndTurn,
        actionCount: actionCount,
        currentActionIndex: currentActionIndex,
        actionOptions: actionOptions,
        waitingForLabel: waitingForLabel,
        actionHintLabel: actionHintLabel,
        compact: compact,
        showTurnLabel: showTurnLabel,
        minHeight: minHeight,
        showActionMenu: showActionMenu,
        pulseActionBorder: pulseActionBorder,
        onActionSelected: onActionSelected,
        onTap: onTap ?? () {},
      ),
    ),
  );
  if (disableAnimations) {
    home = MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(disableAnimations: true),
      child: home,
    );
  }

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  testWidgets('renders compact turn control on a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpButton(
      tester,
      compact: true,
      showTurnLabel: false,
      minHeight: 44,
    );

    expect(find.text('TURN 1'), findsNothing);
    expect(find.text('END TURN'), findsOneWidget);
    expect(tester.getSize(find.byType(EndTurnButton)).height, greaterThan(44));
  });

  testWidgets('action state calls next action from the button', (tester) async {
    const ended = false;
    var next = false;

    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionHintLabel: 'Next step: Warrior',
      onTap: () => next = true,
    );

    expect(find.text('Next step: Warrior'), findsNothing);
    expect(find.text('ACTION'), findsOneWidget);

    await tester.tap(find.text('ACTION'));
    await tester.pump();

    expect(next, isTrue);
    expect(ended, isFalse);
  });

  testWidgets('action state shows progress segment and action menu', (
    tester,
  ) async {
    int? selectedAction;

    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 1,
      actionOptions: _turnActions,
      actionHintLabel: 'Next step: Warrior',
      showActionMenu: true,
      onActionSelected: (index) => selectedAction = index,
    );

    expect(find.text('ACTION'), findsOneWidget);
    expect(find.byKey(const Key('endTurnButton.actionMenu')), findsOneWidget);
    expect(
      find.byKey(const Key('endTurnButton.actionProgress')),
      findsOneWidget,
    );
    expect(find.text('2/3'), findsOneWidget);
    final progressText = tester.widget<Text>(
      find.byKey(const Key('endTurnButton.actionProgress')),
    );
    expect(progressText.style?.shadows, isNotNull);
    expect(progressText.style!.shadows, hasLength(2));

    await tester.tap(find.byKey(const Key('endTurnButton.actionMenu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Warrior 1'), findsOneWidget);
    expect(find.text('Warszawa produkcja'), findsOneWidget);
    expect(find.text('Choose research'), findsOneWidget);

    await tester.tap(find.byKey(const Key('endTurnButton.actionMenu.item.2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(selectedAction, 2);
  });

  testWidgets('action state paints thumbnail for the next action option', (
    tester,
  ) async {
    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 1,
      actionOptions: _turnActions,
      showActionMenu: true,
      onActionSelected: (_) {},
    );

    expect(
      find.byKey(const Key('endTurnButton.actionThumbnail.research')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('endTurnButton.actionMenu')),
        matching: find.byKey(
          const Key('endTurnButton.actionThumbnail.research'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('endTurnButton.actionThumbnail.city')),
      findsNothing,
    );

    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 0,
      actionOptions: _turnActions,
    );

    final cityThumbnail = tester.widget<CitySpriteIcon>(
      find.byKey(const Key('endTurnButton.actionThumbnail.city')),
    );
    expect(cityThumbnail.fit, BoxFit.contain);
    expect(cityThumbnail.alignment, Alignment.center);

    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 2,
      currentActionIndex: -1,
      actionOptions: _turnActions.take(2).toList(growable: false),
    );

    expect(
      find.byKey(const Key('endTurnButton.actionThumbnail.unit')),
      findsOneWidget,
    );
    final warriorThumbnail = tester.widget<UnitSpriteIcon>(
      find.byKey(const Key('endTurnButton.actionThumbnail.unit')),
    );
    expect(warriorThumbnail.type, GameUnitType.warrior);
    expect(warriorThumbnail.size, greaterThan(47));
    expect(
      find.byKey(const Key('endTurnButton.actionThumbnail.city')),
      findsNothing,
    );
  });

  testWidgets('action state marks objective-linked hint on the button', (
    tester,
  ) async {
    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionHintLabel: 'Objective: assign a building in City',
    );

    expect(find.text('ACTION'), findsOneWidget);
    expect(
      find.byKey(const Key('endTurnButton.objectiveLink')),
      findsOneWidget,
    );

    final tooltip = tester.widget<Tooltip>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message?.contains('Objective: assign a building in City') ??
                false),
      ),
    );
    expect(tooltip.message, contains('Go to the next action'));
  });

  testWidgets('action border pulses only when explicitly triggered', (
    tester,
  ) async {
    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 0,
      actionOptions: _turnActions,
      showActionMenu: true,
      pulseActionBorder: true,
      onActionSelected: (_) {},
    );

    expect(
      find.byKey(const Key('endTurnButton.animatedActionBorder')),
      findsOneWidget,
    );

    await _pumpButton(tester, actionCount: 0, pulseActionBorder: true);

    expect(
      find.byKey(const Key('endTurnButton.animatedActionBorder')),
      findsNothing,
    );
  });

  testWidgets('action border pulse respects reduce motion', (tester) async {
    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 0,
      actionOptions: _turnActions,
      showActionMenu: true,
      pulseActionBorder: true,
      disableAnimations: true,
      onActionSelected: (_) {},
    );

    expect(
      find.byKey(const Key('endTurnButton.animatedActionBorder')),
      findsNothing,
    );
  });

  testWidgets('action segment uses joined static border width', (tester) async {
    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 0,
      actionOptions: _turnActions,
      actionHintLabel: 'Next step: Warrior',
      showActionMenu: true,
      onActionSelected: (_) {},
    );

    expect(find.byKey(const Key('endTurnButton.actionMenu')), findsOneWidget);
    expect(
      find.byKey(const Key('endTurnButton.actionChevron')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byType(EndTurnButton)).width,
      EndTurnButton.preferredWidth(compact: false, includeActionSegment: true),
    );
  });

  testWidgets('compact action menu fits inside its preferred width', (
    tester,
  ) async {
    await _pumpButton(
      tester,
      readyToEndTurn: false,
      actionCount: 3,
      currentActionIndex: 0,
      actionOptions: _turnActions,
      actionHintLabel: 'Next step: Warrior',
      compact: true,
      showTurnLabel: false,
      showActionMenu: true,
      onActionSelected: (_) {},
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(EndTurnButton)).width,
      EndTurnButton.preferredWidth(compact: true, includeActionSegment: true),
    );
  });

  testWidgets('end turn state transitions use HUD motion tokens', (
    tester,
  ) async {
    await _pumpButton(tester);

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(EndTurnButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(EndTurnButton),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byType(EndTurnButton),
        matching: find.byType(AnimatedSwitcher),
      ),
    );

    expect(container.duration, GameMotion.scene);
    expect(container.curve, GameMotion.stateChange);
    expect(opacity.duration, GameMotion.scene);
    expect(opacity.curve, GameMotion.stateChange);
    expect(switcher.duration, GameMotion.scene);
    expect(switcher.switchInCurve, GameMotion.enter);
    expect(switcher.switchOutCurve, GameMotion.exit);
  });

  testWidgets('end turn transitions collapse when reduce motion is enabled', (
    tester,
  ) async {
    await _pumpButton(tester, disableAnimations: true);

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(EndTurnButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(EndTurnButton),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(
        of: find.byType(EndTurnButton),
        matching: find.byType(AnimatedSwitcher),
      ),
    );

    expect(container.duration, Duration.zero);
    expect(opacity.duration, Duration.zero);
    expect(switcher.duration, Duration.zero);
  });

  testWidgets('end turn state calls end turn', (tester) async {
    var ended = false;

    await _pumpButton(tester, onTap: () => ended = true);

    expect(find.text('TURN 1'), findsOneWidget);
    await tester.tap(find.text('END TURN'));
    await tester.pump();

    expect(ended, isTrue);
  });

  testWidgets('waiting state ignores taps', (tester) async {
    var tapped = false;

    await _pumpButton(
      tester,
      waiting: true,
      waitingForLabel: 'Waiting na Bob',
      onTap: () => tapped = true,
    );

    expect(find.text('WAITING'), findsOneWidget);

    await tester.tap(find.text('WAITING'), warnIfMissed: false);
    await tester.pump();

    expect(tapped, isFalse);
  });
}
