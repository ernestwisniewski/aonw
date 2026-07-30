part of 'game_event_descriptor.dart';

GameEventDescriptor? _unitPresentationDescriptor(GameEvent event) {
  if (event is! UnitPresentationEvent) return null;
  return switch (event) {
    UnitMovedEvent(:final unitId) => GameEventDescriptor._(
      activityWorthy: false,
      messageGroup: GameEventMessageGroup.unit,
      rendererEffectKind: GameEventRendererEffectKind.unitMoved,
      unitIds: [unitId],
      focusHints: [UnitGameEventFocusHint(unitId)],
      playerIdsResolver: _unitOwnerPlayerIds(unitId),
    ),
    FortifiedUnitThreatenedEvent(
      :final unitId,
      :final ownerPlayerId,
      :final targets,
    ) =>
      GameEventDescriptor._(
        activityWorthy: false,
        messageGroup: GameEventMessageGroup.unit,
        rendererEffectKind: GameEventRendererEffectKind.fortifiedUnitThreatened,
        unitIds: [unitId, for (final target in targets) target.unitId],
        focusHints: [UnitGameEventFocusHint(unitId)],
        playerIds: [ownerPlayerId],
        showAsTopNotification: false,
      ),
    UnitGainedExperienceEvent(:final unitId, :final ownerPlayerId) =>
      GameEventDescriptor._(
        activityWorthy: false,
        messageGroup: GameEventMessageGroup.unit,
        unitIds: [unitId],
        focusHints: [UnitGameEventFocusHint(unitId)],
        playerIds: [ownerPlayerId],
      ),
  };
}
