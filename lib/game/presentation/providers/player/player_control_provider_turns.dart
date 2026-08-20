part of 'player_control_provider.dart';

extension GamePlayerControlTurns on GamePlayerControlController {
  Future<GameSave?> endTurn(GameSave gameSave) async {
    final keepAlive = _providerRef.keepAlive();
    try {
      return await _performEndTurn(gameSave);
    } finally {
      keepAlive.close();
    }
  }

  Future<GameSave?> _performEndTurn(GameSave gameSave) async {
    final context = _beginEndTurn(gameSave);
    if (context == null) return null;

    final result = await _executeEndTurn(gameSave, context);
    if (result == null) return null;
    if (!_isMounted) return result.updatedSave;

    await _publishEndTurnResult(gameSave.id, result, context);
    return result.updatedSave;
  }

  _EndTurnContext? _beginEndTurn(GameSave gameSave) {
    final control = _currentControl;
    if (control.activePlayerId.isEmpty) return null;

    final session = _providerRef.read(activeGameSessionProvider);
    if (session == null || session.saveId != gameSave.id) return null;

    _clearTurnOpening();
    final localSinglePlayer =
        _phaseForSave(gameSave) != LocalSinglePlayerTurnPhase.notApplicable;
    if (localSinglePlayer && !_currentControl.canInteract) return null;
    if (localSinglePlayer) {
      _currentControl = _currentControl.copyWith(
        phase: LocalSinglePlayerTurnPhase.aiResolving,
      );
    }
    return _EndTurnContext(
      gameMode: session.gameMode,
      previousControl: control,
    );
  }

  Future<EndTurnResult?> _executeEndTurn(
    GameSave gameSave,
    _EndTurnContext context,
  ) async {
    try {
      final result =
          await EndTurnUseCase(
            repository: gameRepositoryForSave(_providerRef, gameSave.id),
            strategy: EndTurnStrategies.forMode(context.gameMode),
          ).execute(
            save: gameSave,
            control: _currentControl,
            dispatch: (command) => _dispatchEndTurnCommand(command, context),
          );
      if (result == null) {
        _restoreControlAfterFailedEndTurn(context.previousControl, gameSave);
      }
      return result;
    } catch (error, stackTrace) {
      _restoreControlAfterFailedEndTurn(context.previousControl, gameSave);
      _providerRef
          .read(gameLoggerProvider)
          .warn(
            'GamePlayerControlController',
            'end turn failed',
            error,
            stackTrace,
          );
      return null;
    }
  }

  Future<List<UiEffect>> _dispatchEndTurnCommand(
    DomainCommand command,
    _EndTurnContext context,
  ) async {
    if (context.gameMode != GameMode.hotSeat || command is! EndTurnCommand) {
      return _dispatchAndHandle(command);
    }
    final presentation = await _providerRef
        .read(gameCommandControllerProvider.notifier)
        .dispatchForHandoffPresentation(command);
    context.pendingPresentation = presentation;
    return presentation.uiEffects;
  }

  Future<void> _publishEndTurnResult(
    String saveId,
    EndTurnResult result,
    _EndTurnContext context,
  ) async {
    _invalidateSave(saveId);
    final handoff = result.handoff;
    if (handoff != null) {
      _publishEndTurnHandoff(handoff, context.pendingPresentation);
      return;
    }
    await _completeEndTurnControl(result, context.pendingPresentation);
  }

  void _publishEndTurnHandoff(
    HandoffData handoff,
    HandoffPresentation? presentation,
  ) {
    _providerRef.read(gameHandoffProvider.notifier).setPending(handoff);
    if (presentation != null) {
      _providerRef
          .read(gameCommandControllerProvider.notifier)
          .addHandoffNotifications(presentation);
    }
  }

  Future<void> _completeEndTurnControl(
    EndTurnResult result,
    HandoffPresentation? presentation,
  ) async {
    if (presentation != null) {
      await _providerRef
          .read(gameCommandControllerProvider.notifier)
          .presentHandoffPresentation(presentation);
      if (!_isMounted) return;
    }
    await _setAndSyncAndWait(
      _withSavePhase(
        result.nextControl,
        save: result.updatedSave,
        previous: _currentControl,
      ),
    );
  }

  void _restoreControlAfterFailedEndTurn(
    PlayerControlState previous,
    GameSave save,
  ) {
    if (!_isMounted ||
        _currentControl.activePlayerId != previous.activePlayerId) {
      return;
    }
    _currentControl = previous.copyWith(phase: _phaseForSave(save));
  }
}

final class _EndTurnContext {
  final GameMode gameMode;
  final PlayerControlState previousControl;
  HandoffPresentation? pendingPresentation;

  _EndTurnContext({required this.gameMode, required this.previousControl});
}
