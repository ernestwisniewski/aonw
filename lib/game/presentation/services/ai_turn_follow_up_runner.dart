import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_turn_follow_up_planner.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_presenter.dart';
import 'package:aonw/game/presentation/services/turn_presentation_sequencer.dart';

typedef AiTurnLocalRuntimeEnabledReader = bool Function(GameSave save);
typedef AiTurnControlPlayerIdReader = String Function();
typedef AiTurnAdvanceEffectsPlayer =
    Future<int> Function({
      required String saveId,
      required Iterable<UiEffect> terminalUiEffects,
    });

final class AiTurnFollowUpRunner {
  final GameLogger logger;
  final AiTurnLocalRuntimeEnabledReader localAiRuntimeEnabled;
  final AiTurnControlPlayerIdReader controlPlayerId;
  final AiTurnAdvanceEffectsPlayer playTurnAdvanceEffects;
  final HumanTurnConfirmer confirmHumanTurn;
  final TurnStartFocusRequester focusTurnStartMapTarget;
  final bool Function() canContinue;
  final HandoffClearer clearHandoff;
  final HandoffSetter setHandoff;
  final PlayerNameFormatter playerNameFormatter;

  const AiTurnFollowUpRunner({
    required this.logger,
    required this.localAiRuntimeEnabled,
    required this.controlPlayerId,
    required this.playTurnAdvanceEffects,
    required this.confirmHumanTurn,
    required this.focusTurnStartMapTarget,
    required this.canContinue,
    required this.clearHandoff,
    required this.setHandoff,
    required this.playerNameFormatter,
  });

  Future<String?> advanceAfterAiTurn({
    required GameSave updatedSave,
    required int previousTurn,
    required String playerId,
    required Iterable<UiEffect> terminalUiEffects,
  }) {
    final localRuntimeEnabled = localAiRuntimeEnabled(updatedSave);
    final action = AiTurnFollowUpPlanner.plan(
      updatedSave: updatedSave,
      previousTurn: previousTurn,
      aiPlayerId: playerId,
      controlPlayerId: controlPlayerId(),
      localAiRuntimeEnabled: localRuntimeEnabled,
    );

    return AiTurnFollowUpPresenter(
      turnPresentationSequencer: TurnPresentationSequencer(
        playTurnAdvanceEffects: (effects) {
          return playTurnAdvanceEffects(
            saveId: updatedSave.id,
            terminalUiEffects: effects,
          );
        },
        confirmHumanTurn: confirmHumanTurn,
        focusTurnStartMapTarget: focusTurnStartMapTarget,
        canContinue: canContinue,
      ),
      clearHandoff: clearHandoff,
      setHandoff: setHandoff,
      playerNameFormatter: playerNameFormatter,
      logTurnAdvanceReport: _logTurnAdvanceReport,
    ).present(
      action: action,
      gameMode: updatedSave.gameMode,
      localAiRuntimeEnabled: localRuntimeEnabled,
      terminalUiEffects: terminalUiEffects,
    );
  }

  void _logTurnAdvanceReport(TurnPresentationReport report) {
    logger.info(
      'AI Runtime',
      'hidden turn-advance effects '
          'duration=${report.turnAdvanceEffectDuration.inMilliseconds}ms '
          'effects=${report.turnAdvanceEffectCount}',
    );
  }
}
