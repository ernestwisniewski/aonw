import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/services/ai_turn_execution_runner.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_identity_guard.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_runner.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_context.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_process.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

extension GameAiTurnAutoPilotExecution on GameAiTurnAutoPilotContext {
  AiTurnExecutionRunner aiTurnExecutionRunner() {
    return AiTurnExecutionRunner.fromPreparedProcess(
      logger: ref.read(gameLoggerProvider),
      throttler: runtimeThrottler,
      prepareProcess: prepareAiTurnProcess,
      invalidateSaveSnapshot: (saveId) =>
          ref.invalidate(gameSaveSnapshotProvider(saveId)),
      authorizeFollowUp:
          ({required updatedSave, required previousTurn, required playerId}) {
            return followUpIdentityGuard.authorizeFollowUp(
                  saveId: updatedSave.id,
                  previousTurn: previousTurn,
                  updatedTurn: updatedSave.turn,
                  playerId: playerId,
                ) !=
                null;
          },
      advanceAfterAiTurn:
          ({
            required updatedSave,
            required previousTurn,
            required playerId,
            required terminalUiEffects,
          }) async {
            final token = followUpIdentityGuard.authorizedFollowUpToken(
              saveId: updatedSave.id,
              previousTurn: previousTurn,
              updatedTurn: updatedSave.turn,
              playerId: playerId,
            );
            if (token == null) return null;
            return aiTurnFollowUpRunner(token).advanceAfterAiTurn(
              updatedSave: updatedSave,
              previousTurn: previousTurn,
              playerId: playerId,
              terminalUiEffects: terminalUiEffects,
            );
          },
      onExecutionSettled: (request) {
        final settledLease = followUpIdentityGuard.finishExecution(
          saveId: request.saveId,
          turn: request.turn,
          playerId: request.playerId,
        );
        if (settledLease != null) {
          cancelTurnOpening(settledLease);
        }
      },
      canContinue: canContinue,
      precomputeStats: runtimeCoordinator.precomputeStats,
      throttleStats: runtimeCoordinator.throttleStats,
      logThrottleChange: runtimeCoordinator.logThrottleChange,
    );
  }

  AiTurnFollowUpRunner aiTurnFollowUpRunner(
    AiTurnExecutionIdentityToken token,
  ) {
    final presentationDriver = aiTurnPresentationDriver();
    return AiTurnFollowUpRunner(
      logger: ref.read(gameLoggerProvider),
      localAiRuntimeEnabled: (save) {
        return GameAiTurnAutoPilotRules.shouldRunLocalAi(
          save: save,
          networkSession: ref.read(networkSessionProvider),
        );
      },
      controlPlayerId: () {
        return ref.read(gamePlayerControlControllerProvider).activePlayerId;
      },
      playTurnAdvanceEffects: ({required saveId, required terminalUiEffects}) {
        return presentationDriver.playTurnAdvanceEffects(
          saveId: saveId,
          terminalUiEffects: terminalUiEffects,
        );
      },
      beginTurnOpening: (playerId) {
        followUpIdentityGuard.runIfCurrent(token, () {
          ref
              .read(gamePlayerControlControllerProvider.notifier)
              .beginTurnOpening(playerId, lease: token.openingLease);
        });
      },
      prepareHumanTurn: (playerId) {
        return followUpIdentityGuard.runAsyncIfCurrent(token, () {
          return ref
              .read(gamePlayerControlControllerProvider.notifier)
              .prepareHumanTurn(playerId, lease: token.openingLease);
        });
      },
      focusTurnStartMapTarget: (playerId) {
        return followUpIdentityGuard.runAsyncIfCurrent(token, () {
          return ref
              .read(hudCommandDispatcherProvider)
              .focusTurnStartMapTarget(
                activePlayerId: playerId,
                state: ref
                    .read(gameStateProvider(saveReader()?.id ?? ''))
                    .value,
              );
        });
      },
      releaseHumanTurn: (playerId) {
        return followUpIdentityGuard.runAsyncIfCurrent(token, () {
          return ref
              .read(gamePlayerControlControllerProvider.notifier)
              .releaseHumanTurn(playerId, lease: token.openingLease);
        });
      },
      canContinue: () =>
          canContinue() && followUpIdentityGuard.isCurrent(token),
      clearHandoff: () {
        followUpIdentityGuard.runIfCurrent(token, () {
          ref.read(gameHandoffProvider.notifier).clear();
        });
      },
      setHandoff: (handoff) {
        followUpIdentityGuard.runIfCurrent(token, () {
          ref.read(gameHandoffProvider.notifier).setPending(handoff);
        });
      },
      playerNameFormatter: (player) {
        return GameDisplayNames.player(
          AppLocalizations.of(contextReader()),
          player,
        );
      },
    );
  }
}
