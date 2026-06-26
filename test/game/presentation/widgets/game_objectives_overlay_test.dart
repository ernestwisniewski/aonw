import 'package:aonw/game/presentation/widgets/hud/objective/game_objectives_overlay.dart';
import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_summary.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders localized objective copy and micro-tooltip', (
    tester,
  ) async {
    final objective = GameObjectiveProgress(
      definition: GameObjectiveTracker.expansionObjectives.first,
      currentValue: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: GameObjectivesOverlay(
              objectives: [objective],
              maxWidth: 340,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('OBJECTIVES'), findsOneWidget);
    expect(find.byKey(const Key('gameObjectives.close')), findsNothing);
    expect(find.byKey(const Key('gameObjectives.overview')), findsOneWidget);
    expect(find.text('ACTIVE OBJECTIVE'), findsOneWidget);
    expect(
      find.text('Top priority: Build your first building'),
      findsOneWidget,
    );
    expect(find.text('Progress 0/1'), findsOneWidget);
    expect(find.text('Build your first building'), findsOneWidget);
    expect(
      find.text(
        'The first building should strengthen food, production, or gold.',
      ),
      findsOneWidget,
    );
    expect(find.text('+ lasting city advantage'), findsOneWidget);
    expect(find.text('Expansion'), findsOneWidget);
    expect(
      find.byTooltip('Buildings stay in the city and scale across many turns.'),
      findsOneWidget,
    );
  });

  testWidgets('renders score pressure advice under the objective hint', (
    tester,
  ) async {
    const objective = GameObjectiveProgress(
      definition: GameObjectiveTracker.overtakeScoreLeaderObjective,
      currentValue: 80,
      advice: GameObjectiveAdvice.unlockTechnology,
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: GameObjectivesOverlay(
              objectives: [objective],
              scoreBreakdown: HudObjectiveScoreBreakdown(
                mode: HudObjectiveScoreBreakdownMode.catchUp,
                playerScore: 80,
                comparisonScore: 95,
                rows: [
                  HudObjectiveScoreBreakdownRow(
                    advice: GameObjectiveAdvice.unlockTechnology,
                    playerValue: 0,
                    comparisonValue: 12,
                    delta: 12,
                  ),
                  HudObjectiveScoreBreakdownRow(
                    advice: GameObjectiveAdvice.constructBuilding,
                    playerValue: 0,
                    comparisonValue: 8,
                    delta: 8,
                  ),
                ],
              ),
              maxWidth: 360,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Catch the score leader'), findsOneWidget);
    expect(find.text('Top priority: Catch the score leader'), findsOneWidget);
    expect(find.text('SCORE PRESSURE'), findsOneWidget);
    expect(find.textContaining('Biggest gap'), findsOneWidget);
    expect(find.textContaining('completing a technology'), findsOneWidget);
    expect(
      find.byKey(const Key('gameObjectives.scoreBreakdown')),
      findsOneWidget,
    );
    expect(find.text('Score gap: 15 pts'), findsWidgets);
    expect(find.text('You 80 / leader 95'), findsOneWidget);
    expect(find.text('Technologies'), findsOneWidget);
    expect(find.text('short by 12'), findsOneWidget);
  });

  testWidgets('summarizes domination pressure in the overview band', (
    tester,
  ) async {
    const objective = GameObjectiveProgress(
      definition: GameObjectiveDefinition(
        id: GameObjectiveId.breakDominationHold,
        phase: GameObjectivePhase.endgame,
        track: GameObjectiveTrack.strategic,
        targetValue: 3,
        tone: GameObjectiveTone.warning,
      ),
      currentValue: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: GameObjectivesOverlay(
              objectives: [objective],
              maxWidth: 360,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('gameObjectives.overview')), findsOneWidget);
    expect(find.text('DOMINATION THREAT'), findsOneWidget);
    expect(
      find.text("Top priority: Break a rival's domination"),
      findsOneWidget,
    );
    expect(find.text('Progress 2/3'), findsOneWidget);
    expect(find.text("Break a rival's domination"), findsOneWidget);
  });
}
