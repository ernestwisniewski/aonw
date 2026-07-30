part of 'game_event_domain_descriptor.dart';

GameEventDomainDescriptor? unitPresentationEventDomainDescriptor(
  GameEvent event,
) {
  if (event is! UnitPresentationEvent) return null;
  return switch (event) {
    UnitMovedEvent(:final unitId) => GameEventDomainDescriptor._(
      unitIds: [unitId],
    ),
    FortifiedUnitThreatenedEvent(
      :final unitId,
      :final ownerPlayerId,
      :final targets,
    ) =>
      GameEventDomainDescriptor._(
        playerIds: [ownerPlayerId],
        unitIds: [unitId, for (final target in targets) target.unitId],
        visiblePlayerIds: [ownerPlayerId],
      ),
    UnitGainedExperienceEvent(:final ownerPlayerId) =>
      GameEventDomainDescriptor._(playerIds: [ownerPlayerId]),
  };
}
