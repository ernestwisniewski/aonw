import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_step.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a complete localized first-turn sequence for a settler', () {
    final steps = FirstTurnCoachmarkSteps.build(
      l10n: AppLocalizationsEn(),
      context: const FirstTurnCoachmarkContext(
        selectionKind: FirstTurnCoachmarkSelectionKind.settler,
        hasSelectionActions: true,
      ),
    );

    expect(steps, hasLength(8));
    expect(steps.map((step) => step.title), [
      'Step 1: read the selection',
      'Step 2: check your empire',
      'Step 3: learn the left menu',
      'Step 4: give the right order',
      'Step 5: choose research',
      'Step 6: set up the city',
      'Step 7: clear the action queue',
      'Step 8: end the turn and repeat',
    ]);
    expect(steps[0].body, startsWith('Click or tap the same hex'));
    expect(steps[0].body, contains('map objective'));
    expect(steps[0].body, contains('bottom toolbar'));
    expect(steps[0].body, contains('cancel'));
    expect(steps[1].body, contains('domination'));
    expect(steps[1].body, contains('artifacts'));
    expect(steps[2].body, contains('left menu'));
    expect(steps[3].body, contains('settler'));
    expect(steps[6].body, contains('The action button'));
    expect(steps[7].body, contains('resources, units, city, research'));
  });

  test('builds equivalent first-turn sequence in English', () {
    final steps = FirstTurnCoachmarkSteps.build(
      l10n: AppLocalizationsEn(),
      context: const FirstTurnCoachmarkContext(
        hasSelectionActions: false,
        readyToEndTurn: true,
      ),
    );

    expect(steps, hasLength(8));
    expect(steps.first.title, 'Step 1: read the selection');
    expect(steps.first.body, startsWith('Click or tap the same hex'));
    expect(steps.first.body, contains('map objective'));
    expect(steps[3].body, contains('units and cities one by one'));
    expect(steps[6].body, contains('All key decisions'));
    expect(steps.last.title, 'Step 8: end the turn and repeat');
  });

  test(
    'uses selection-specific action copy without leaking settler guidance',
    () {
      final workerSteps = FirstTurnCoachmarkSteps.build(
        l10n: AppLocalizationsEn(),
        context: const FirstTurnCoachmarkContext(
          selectionKind: FirstTurnCoachmarkSelectionKind.worker,
          hasSelectionActions: true,
        ),
      );
      final citySteps = FirstTurnCoachmarkSteps.build(
        l10n: AppLocalizationsEn(),
        context: const FirstTurnCoachmarkContext(
          selectionKind: FirstTurnCoachmarkSelectionKind.city,
          hasSelectionActions: true,
          hasCityNeedingProduction: true,
        ),
      );

      expect(workerSteps[3].body, contains('worker'));
      expect(workerSteps[3].body.toLowerCase(), isNot(contains('settler')));
      expect(citySteps[0].body, contains('You have a city selected'));
      expect(citySteps[3].body, contains('With a city selected'));
      expect(citySteps[3].body.toLowerCase(), isNot(contains('settler')));
    },
  );
}
