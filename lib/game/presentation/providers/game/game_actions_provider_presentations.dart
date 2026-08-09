part of 'game_actions_provider.dart';

int _nextInteractionSequence = 0;

Iterable<RendererEffect> _allowedInteractionEffects(
  Object command,
  Iterable<RendererEffect> effects,
) sync* {
  for (final effect in effects) {
    if (effect is JumpCameraEffect || effect is SmoothCameraEffect) {
      yield effect;
    } else if ((command is FocusNextPendingActionCommand ||
            command is FocusTurnStartActionCommand) &&
        effect is ShowActionTargetFocusEffect) {
      yield effect;
    } else if (command is FocusTurnStartActionCommand &&
        effect is ShowCityProductionBubbleEffect) {
      yield effect;
    }
  }
}

extension GameCommandControllerProjectedPresentation on GameCommandController {
  Future<void> _presentRendererRecord(
    _CommandDispatchRecord record, {
    required String sourceId,
    required int? eventTurn,
    required int? currentTurn,
    required RendererViewModel renderer,
  }) async {
    final result = record.result;
    final commandRendererEffects = GameCameraEffectNormalizer.forCommand(
      command: record.command,
      effects: result.uiEffects.rendererEffects,
    );
    final visibleCommandRendererEffects =
        await _dedupeTurnStartProductionBubbles(
          command: record.command,
          saveId: sourceId,
          effects: commandRendererEffects,
        );
    final rendererEffects = _commandProjection(
      record,
      sourceId: sourceId,
      interactionEffects: visibleCommandRendererEffects,
      l10n: renderer.l10n,
      turn: eventTurn,
    );
    final soundCues = _commandAndTransitionSoundCues(
      command: record.command,
      previousState: record.previousState,
      result: result,
      rendererEffects: rendererEffects.effects,
    );
    final audioController = _providerRef.read(gameAudioControllerProvider);
    await renderer.applyProjectedTransition(
      result.state,
      rendererEffects,
      currentTurn: currentTurn,
      onPresentationStart: _presentationSoundStart(audioController, soundCues),
    );
  }
}

List<GameSoundCue> _commandAndTransitionSoundCues({
  required Object command,
  required GameClientState? previousState,
  required DispatchCommandResult result,
  required Iterable<RendererEffect> rendererEffects,
}) {
  return [
    ...GameSoundCueMapper.forCommand(
      command: command,
      previousState: previousState,
      state: result.state,
      events: result.events,
      uiEffects: result.uiEffects,
    ),
    ...GameSoundCueMapper.forRendererEffects(
      effects: rendererEffects,
      state: result.state,
      previousState: previousState,
    ),
    ...GameSoundCueMapper.forEvents(
      events: result.events,
      state: result.state,
      previousState: previousState,
    ),
  ];
}

PresentationStartCallback? _presentationSoundStart(
  GameAudioController audioController,
  List<GameSoundCue> cues,
) {
  if (cues.isEmpty) return null;
  return () => audioController.playAll(cues);
}

void _playSoundCues(
  GameAudioController audioController,
  List<GameSoundCue> cues,
) {
  if (cues.isEmpty) return;
  audioController.playAll(cues);
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
    sequenceDirective: result.offset > 0
        ? PresentationSequenceDirective.advance
        : PresentationSequenceDirective.interactionOnly,
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
