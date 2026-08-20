part of 'game_ai_turn_auto_pilot.dart';

extension _GameAiTurnAutoPilotExecution on _GameAiTurnAutoPilotState {
  AiTurnExecutionRunner _aiTurnExecutionRunner() {
    return AiTurnExecutionRunner.fromPreparedProcess(
      logger: ref.read(gameLoggerProvider),
      throttler: _runtimeThrottler,
      prepareProcess: _prepareAiTurnProcess,
      invalidateSaveSnapshot: (saveId) =>
          ref.invalidate(gameSaveSnapshotProvider(saveId)),
      authorizeFollowUp:
          ({required updatedSave, required previousTurn, required playerId}) {
            return _followUpIdentityGuard.authorizeFollowUp(
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
            final token = _followUpIdentityGuard.authorizedFollowUpToken(
              saveId: updatedSave.id,
              previousTurn: previousTurn,
              updatedTurn: updatedSave.turn,
              playerId: playerId,
            );
            if (token == null) return null;
            return _aiTurnFollowUpRunner(token).advanceAfterAiTurn(
              updatedSave: updatedSave,
              previousTurn: previousTurn,
              playerId: playerId,
              terminalUiEffects: terminalUiEffects,
            );
          },
      onExecutionSettled: (request) {
        final settledLease = _followUpIdentityGuard.finishExecution(
          saveId: request.saveId,
          turn: request.turn,
          playerId: request.playerId,
        );
        if (settledLease != null) {
          _cancelTurnOpening(settledLease);
        }
      },
      canContinue: () => mounted,
      precomputeStats: _runtimeCoordinator.precomputeStats,
      throttleStats: _runtimeCoordinator.throttleStats,
      logThrottleChange: _runtimeCoordinator.logThrottleChange,
    );
  }

  AiTurnFollowUpRunner _aiTurnFollowUpRunner(
    AiTurnExecutionIdentityToken token,
  ) {
    final presentationDriver = _aiTurnPresentationDriver();
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
        _followUpIdentityGuard.runIfCurrent(token, () {
          ref
              .read(gamePlayerControlControllerProvider.notifier)
              .beginTurnOpening(playerId, lease: token.openingLease);
        });
      },
      prepareHumanTurn: (playerId) {
        return _followUpIdentityGuard.runAsyncIfCurrent(token, () {
          return ref
              .read(gamePlayerControlControllerProvider.notifier)
              .prepareHumanTurn(playerId, lease: token.openingLease);
        });
      },
      focusTurnStartMapTarget: (playerId) {
        return _followUpIdentityGuard.runAsyncIfCurrent(token, () {
          return ref
              .read(hudCommandDispatcherProvider)
              .focusTurnStartMapTarget(
                activePlayerId: playerId,
                state: ref
                    .read(gameStateProvider(widget.gameSave?.id ?? ''))
                    .value,
              );
        });
      },
      releaseHumanTurn: (playerId) {
        return _followUpIdentityGuard.runAsyncIfCurrent(token, () {
          return ref
              .read(gamePlayerControlControllerProvider.notifier)
              .releaseHumanTurn(playerId, lease: token.openingLease);
        });
      },
      canContinue: () => mounted && _followUpIdentityGuard.isCurrent(token),
      clearHandoff: () {
        _followUpIdentityGuard.runIfCurrent(token, () {
          ref.read(gameHandoffProvider.notifier).clear();
        });
      },
      setHandoff: (handoff) {
        _followUpIdentityGuard.runIfCurrent(token, () {
          ref.read(gameHandoffProvider.notifier).setPending(handoff);
        });
      },
      playerNameFormatter: (player) {
        return GameDisplayNames.player(AppLocalizations.of(context), player);
      },
    );
  }
}
