import 'package:aonw/game/application/services/ai_turn_follow_up_planner.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/turn_presentation_sequencer.dart';
import 'package:aonw_core/game/domain/player.dart';

typedef HandoffClearer = void Function();
typedef HandoffSetter = void Function(HandoffData handoff);
typedef PlayerNameFormatter = String Function(Player player);
typedef TurnAdvanceReportLogger = void Function(TurnPresentationReport report);

final class AiTurnFollowUpPresenter {
  final TurnPresentationSequencer turnPresentationSequencer;
  final HandoffClearer clearHandoff;
  final HandoffSetter setHandoff;
  final PlayerNameFormatter playerNameFormatter;
  final TurnAdvanceReportLogger logTurnAdvanceReport;

  const AiTurnFollowUpPresenter({
    required this.turnPresentationSequencer,
    required this.clearHandoff,
    required this.setHandoff,
    required this.playerNameFormatter,
    required this.logTurnAdvanceReport,
  });

  Future<String?> present({
    required AiTurnFollowUpAction action,
    required GameMode gameMode,
    required bool localAiRuntimeEnabled,
    required Iterable<UiEffect> terminalUiEffects,
  }) async {
    if (gameMode != GameMode.hotSeat && localAiRuntimeEnabled) {
      clearHandoff();
    }

    switch (action) {
      case AiTurnFollowUpNone():
        return null;
      case AiTurnFollowUpScheduleAi(:final playerId):
        if (gameMode == GameMode.hotSeat) clearHandoff();
        return playerId;
      case AiTurnFollowUpHotSeatHandoff(
        :final player,
        :final turnNumber,
        :final freshTurn,
      ):
        setHandoff(
          HandoffData(
            playerId: player.id,
            playerName: playerNameFormatter(player),
            playerColorValue: player.colorValue,
            turnNumber: turnNumber,
            freshTurn: freshTurn,
          ),
        );
        return null;
      case AiTurnFollowUpConfirmHumanTurn(
        :final playerId,
        :final playTurnAdvanceEffects,
      ):
        final report = await turnPresentationSequencer.presentHumanTurnStart(
          playerId: playerId,
          shouldPlayTurnAdvanceEffects: playTurnAdvanceEffects,
          turnAdvanceEffects: terminalUiEffects,
        );
        if (report.turnAdvanceEffectsPlayed) {
          logTurnAdvanceReport(report);
        }
        return null;
    }
  }
}
