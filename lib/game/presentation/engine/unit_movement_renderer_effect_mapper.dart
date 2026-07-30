part of 'game_event_renderer_effect_mapper.dart';

List<RendererEffect> unitMovementRendererEffects(
  UnitMovedEvent event,
  Set<String> skipUnitMoveIds,
) {
  if (skipUnitMoveIds.contains(event.unitId) ||
      (event.fromCol == event.toCol && event.fromRow == event.toRow)) {
    return const [];
  }
  return [
    AnimateUnitMoveEffect(
      unitId: event.unitId,
      fromCol: event.fromCol,
      fromRow: event.fromRow,
      steps: [
        UnitMovementStep(
          col: event.toCol,
          row: event.toRow,
          enterCost: 0,
          cumulativeCost: 0,
        ),
      ],
    ),
  ];
}
