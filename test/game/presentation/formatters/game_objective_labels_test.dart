import 'package:aonw/game/presentation/formatters/game_objective_labels.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('GameObjectiveLabels', () {
    test('maps objective ids to player-facing copy', () {
      final presentation = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.expansionObjectives.first,
      );

      expect(presentation.title, 'Build your first building');
      expect(
        presentation.hint,
        'The first building should strengthen food, production, or gold.',
      );
      expect(presentation.rewardLabel, '+ lasting city advantage');
      expect(
        presentation.microTooltip,
        'Buildings stay in the city and scale across many turns.',
      );
      expect(presentation.phaseLabel, 'Expansion');
    });

    test('covers every objective with non-empty copy', () {
      final definitions = [
        ...GameObjectiveTracker.guidanceObjectives,
        ...GameObjectiveTracker.strategicObjectives,
      ];

      for (final definition in definitions) {
        final presentation = GameObjectiveLabels.presentation(l10n, definition);

        expect(presentation.title, isNotEmpty);
        expect(presentation.hint, isNotEmpty);
        expect(presentation.rewardLabel, isNotEmpty);
        expect(presentation.microTooltip, isNotEmpty);
        expect(presentation.phaseLabel, isNotEmpty);
      }
    });

    test('maps domination pressure objectives to clear copy', () {
      final hold = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.holdDominationObjective,
      );
      final breakHold = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.breakDominationHoldObjective,
      );

      expect(hold.title, 'Hold domination');
      expect(hold.phaseLabel, 'Endgame');
      expect(breakHold.title, "Break a rival's domination");
      expect(breakHold.rewardLabel, '+ countdown stopped');
    });

    test('maps score pressure objectives to clear copy', () {
      final hold = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.holdScoreLeadObjective,
      );
      final overtake = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.overtakeScoreLeaderObjective,
      );

      expect(hold.title, 'Hold the lead');
      expect(hold.rewardLabel, '+ score-cap win');
      expect(overtake.title, 'Catch the score leader');
      expect(overtake.microTooltip, contains('if scores tie'));
    });

    test('maps map objective pressure objectives to clear copy', () {
      final secure = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.secureMapObjective,
      );
      final deny = GameObjectiveLabels.presentation(
        l10n,
        GameObjectiveTracker.breakMapObjectiveHoldObjective,
      );

      expect(secure.title, 'Secure the map objective');
      expect(secure.microTooltip, contains('triangle markers'));
      expect(deny.title, 'Break the rival objective');
      expect(deny.rewardLabel, '+ denied objective');
    });

    test('maps objective advice to localized one-line hints', () {
      expect(
        GameObjectiveLabels.advice(l10n, GameObjectiveAdvice.unlockTechnology),
        'Biggest gap: completing a technology.',
      );
      expect(
        GameObjectiveLabels.advice(l10n, GameObjectiveAdvice.protectLead),
        'Priority: do not give up cities, and secure the next score gain.',
      );
      expect(GameObjectiveLabels.advice(l10n, null), isNull);
    });
  });
}
