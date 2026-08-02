part of 'game_actions_provider.dart';

int _nextInteractionSequence = 0;

Iterable<RendererEffect> _allowedInteractionEffects(
  Object command,
  Iterable<RendererEffect> effects,
) sync* {
  for (final effect in effects) {
    if (effect is JumpCameraEffect || effect is SmoothCameraEffect) {
      yield effect;
    } else if (command is FocusTurnStartActionCommand &&
        effect is ShowCityProductionBubbleEffect) {
      yield effect;
    }
  }
}

ProjectedGameEffectBatch _commandProjection(
  _CommandDispatchRecord record, {
  required String sourceId,
  required Iterable<RendererEffect> interactionEffects,
  required AppLocalizations? l10n,
  required int? turn,
}) {
  final result = record.result;
  return projectCommandDispatchPresentation(
    identity: PresentationBatchIdentity(
      sourceId: sourceId,
      eventOffset: result.offset,
      authoritativeTick: result.authoritativeTick,
      authoritativeStartMicrosUtc: result.authoritativeStartMicrosUtc,
      interactionId: record.interactionId,
    ),
    interactionEffects: _allowedInteractionEffects(
      record.command,
      interactionEffects,
    ),
    events: result.events,
    state: result.state,
    previousState: record.previousState ?? result.state,
    movementExecutions: result.movementExecutions,
    l10n: l10n,
    turn: turn,
  );
}

HandoffPresentation _handoffPresentation(
  DomainCommand command,
  _CommandDispatchRecord record,
) {
  final result = record.result;
  return HandoffPresentation(
    command: command,
    state: result.state,
    previousState: record.previousState,
    uiEffects: result.uiEffects,
    events: result.events,
    combatAnimations: result.combatAnimations,
    movementExecutions: result.movementExecutions,
    offset: result.offset,
    interactionId: record.interactionId,
  );
}

HudFeedbackContent? _artifactGuidanceContent(
  _CommandDispatchRecord record, {
  required LanguageSettings languageSettings,
}) {
  final previousState = record.previousState;
  if (previousState == null) return null;
  final locale =
      languageSettings.locale ??
      resolveGameLocale(
        ui.PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      );
  return ArtifactGuidanceResolver(l10n: lookupAppLocalizations(locale)).resolve(
    previousState: previousState,
    state: record.result.state,
    events: record.result.events,
  );
}

extension GameCommandControllerDispatch on GameCommandController {
  Future<_CommandDispatchRecord> _dispatchOnly(
    Object command, {
    GameCommandContext context = const GameCommandContext(),
  }) async {
    if (!_isMounted) return _emptyDispatchRecord(command);
    final session = _providerRef.read(activeGameSessionProvider);
    if (session == null || session.saveId.isEmpty) {
      return _emptyDispatchRecord(command);
    }
    final previousState = _currentGameState();
    try {
      final notifier = _providerRef.read(
        gameStateProvider(session.saveId).notifier,
      );
      final result = await _executeCommand(notifier, command, context: context);
      return _CommandDispatchRecord(
        command: command,
        previousState: previousState,
        result: result,
      );
    } catch (error, stackTrace) {
      if (_isMounted) {
        _providerRef
            .read(gameLoggerProvider)
            .warn(
              'GameCommandController',
              'command dispatch failed',
              error,
              stackTrace,
            );
        _invalidateSave(session.saveId);
      }
      return _CommandDispatchRecord(
        command: command,
        previousState: previousState,
        result: DispatchCommandResult(
          state: previousState ?? GameClientState(),
        ),
      );
    }
  }

  Future<DispatchCommandResult> _executeCommand(
    GameStateNotifier notifier,
    Object command, {
    required GameCommandContext context,
  }) {
    return switch (command) {
      DomainCommand() => notifier.dispatchTransition(command, context: context),
      GameIntent() => notifier.dispatchIntentTransition(
        command,
        context: context,
      ),
      _ => throw ArgumentError.value(command, 'command'),
    };
  }

  _CommandDispatchRecord _emptyDispatchRecord(Object command) {
    return _CommandDispatchRecord(
      command: command,
      previousState: null,
      result: DispatchCommandResult(state: GameClientState()),
    );
  }
}

class _CommandDispatchRecord {
  final Object command;
  final GameClientState? previousState;
  final DispatchCommandResult result;
  final String interactionId;

  _CommandDispatchRecord({
    required this.command,
    required this.previousState,
    required this.result,
    String? interactionId,
  }) : interactionId = interactionId ?? 'intent_${_nextInteractionSequence++}';
}
