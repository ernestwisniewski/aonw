import 'package:aonw/game/presentation/widgets/hud/objective/hud_objective_button_signal.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_options_panel.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('uses objective count badge for regular guidance', () {
    final signal = HudObjectiveButtonSignal.from(
      l10n: l10n,
      objectives: [
        GameObjectiveProgress(
          definition: GameObjectiveTracker.earlyGameObjectives[0],
          currentValue: 0,
        ),
        GameObjectiveProgress(
          definition: GameObjectiveTracker.earlyGameObjectives[1],
          currentValue: 0,
        ),
        GameObjectiveProgress(
          definition: GameObjectiveTracker.earlyGameObjectives[2],
          currentValue: 4,
        ),
      ],
      open: false,
    );

    expect(signal.badgeLabel, '3');
    expect(signal.badgeTone, GameUiSideMenuBadgeTone.count);
    expect(
      signal.tooltip,
      'Objectives: active objective - Choose research (0/1, 3 objectives)',
    );
  });

  test('uses score pressure badge and tooltip', () {
    final signal = HudObjectiveButtonSignal.from(
      l10n: l10n,
      objectives: const [
        GameObjectiveProgress(
          definition: GameObjectiveDefinition(
            id: GameObjectiveId.overtakeScoreLeader,
            phase: GameObjectivePhase.endgame,
            track: GameObjectiveTrack.strategic,
            targetValue: 96,
            tone: GameObjectiveTone.warning,
          ),
          currentValue: 80,
        ),
      ],
      open: false,
    );

    expect(signal.badgeLabel, 'PTS');
    expect(signal.badgeTone, GameUiSideMenuBadgeTone.score);
    expect(
      signal.tooltip,
      'Objectives: score pressure - Catch the score leader (80/96, 1 objective)',
    );
  });

  test('uses domination badge and close tooltip when open', () {
    final signal = HudObjectiveButtonSignal.from(
      l10n: l10n,
      objectives: const [
        GameObjectiveProgress(
          definition: GameObjectiveDefinition(
            id: GameObjectiveId.breakDominationHold,
            phase: GameObjectivePhase.endgame,
            track: GameObjectiveTrack.strategic,
            targetValue: 4,
            tone: GameObjectiveTone.warning,
          ),
          currentValue: 2,
        ),
      ],
      open: true,
    );

    expect(signal.badgeLabel, 'DOM');
    expect(signal.badgeTone, GameUiSideMenuBadgeTone.domination);
    expect(
      signal.tooltip,
      "Close objectives: domination threat - Break a rival's domination (2/4, 1 objective)",
    );
  });
}
