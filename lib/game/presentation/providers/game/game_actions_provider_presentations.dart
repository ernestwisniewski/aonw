part of 'game_actions_provider.dart';

int _nextInteractionSequence = 0;

Iterable<RendererEffect> _allowedInteractionEffects(
  GameCommand command,
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
  GameCommand command,
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

class _CommandDispatchRecord {
  final GameCommand command;
  final GameState? previousState;
  final DispatchCommandResult result;
  final String interactionId;

  _CommandDispatchRecord({
    required this.command,
    required this.previousState,
    required this.result,
    String? interactionId,
  }) : interactionId = interactionId ?? 'intent_${_nextInteractionSequence++}';
}
