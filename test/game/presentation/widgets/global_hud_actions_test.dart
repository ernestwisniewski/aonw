import 'package:aonw/game/presentation/widgets/hud/global_hud_actions.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlobalHudActionButton exposes key, tooltip, and tap handler', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalHudActionButton(
            actionId: 'research',
            keyLabel: 'Research',
            icon: GameIcons.science,
            active: false,
            tooltip: 'Research',
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('globalHud.action.research')), findsOneWidget);

    await tester.tap(find.byKey(const Key('globalHud.action.research')));

    expect(taps, 1);

    await tester.longPress(find.byKey(const Key('globalHud.action.research')));
    await tester.pumpAndSettle();

    expect(find.text('Research'), findsOneWidget);
  });

  testWidgets('GlobalHudActionRail omits scroll container when empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GlobalHudActionRail(children: [])),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('GlobalHudActionButton keeps research action icon-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalHudActionButton(
            actionId: 'research',
            keyLabel: 'Research',
            icon: GameIcons.science,
            active: false,
            tooltip: 'Research: Bronze · 4t',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('globalHud.action.research.statusText')),
      findsNothing,
    );
    expect(find.text('Bronze 4t'), findsNothing);
  });

  testWidgets('GlobalHudActionRail lays out actions in the requested axis', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalHudActionRail(
            axis: Axis.vertical,
            children: [
              GlobalHudActionButton(
                actionId: 'research',
                keyLabel: 'Research',
                icon: GameIcons.science,
                active: true,
                tooltip: 'Close research',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollView.scrollDirection, Axis.vertical);
    expect(find.byKey(const Key('globalHud.action.research')), findsOneWidget);
  });
}
