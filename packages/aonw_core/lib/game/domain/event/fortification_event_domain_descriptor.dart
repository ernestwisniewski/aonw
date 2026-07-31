part of 'game_event_domain_descriptor.dart';

GameEventDomainDescriptor? unitPresentationEventDomainDescriptor(
  GameEvent event,
) {
  if (event is! UnitPresentationEvent) return null;
  return switch (event) {
    UnitMovedEvent(
      :final unitId,
      :final fromCol,
      :final fromRow,
      :final toCol,
      :final toRow,
    ) =>
      GameEventDomainDescriptor._(
        unitIds: [unitId],
        coarseMovement: GameEventCoarseMovement(
          origin: HexCoordinate(col: fromCol, row: fromRow),
          destination: HexCoordinate(col: toCol, row: toRow),
        ),
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
