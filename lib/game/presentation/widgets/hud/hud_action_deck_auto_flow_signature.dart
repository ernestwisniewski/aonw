part of 'hud_action_deck.dart';

final class _HudAutoFlowSignatureBuilder {
  const _HudAutoFlowSignatureBuilder({
    required this.activePlayerId,
    required this.unitNeedsManualOrder,
  });

  final String activePlayerId;
  final _HudUnitOrderPredicate unitNeedsManualOrder;

  String signatureFor({
    required GameState state,
    required GameSave gameSave,
    required bool readyToEndTurn,
    required int remainingActionCount,
  }) {
    final research = state.research.forPlayer(activePlayerId);
    return [
      gameSave.turn,
      readyToEndTurn,
      remainingActionCount,
      _selectionKey(state.selection),
      _pendingActionKey(state.pendingAction),
      _unitsNeedingOrdersKey(state.units),
      _citiesNeedingProductionKey(state.cities),
      research.activeTechnologyId ?? 'none',
    ].join('|');
  }

  String _selectionKey(GameSelection? selection) {
    return switch (selection?.type) {
      GameSelectionType.unit => 'unit:${selection?.unit?.id ?? ''}',
      GameSelectionType.city => 'city:${selection?.city?.id ?? ''}',
      GameSelectionType.tile =>
        'tile:${selection?.tile?.col}:${selection?.tile?.row}',
      GameSelectionType.fieldImprovement =>
        'field:${selection?.fieldImprovement?.hex.col}:${selection?.fieldImprovement?.hex.row}',
      null => 'none',
    };
  }

  String _pendingActionKey(PendingPlayerAction? pendingAction) {
    return switch (pendingAction) {
      PendingUnitTurnSkip(:final unitId) => 'skip:$unitId',
      final PendingPlayerAction pending => pending.jsonType,
      null => 'none',
    };
  }

  String _unitsNeedingOrdersKey(List<GameUnit> units) {
    return [
      for (final unit in units)
        if (unit.ownerPlayerId == activePlayerId && unitNeedsManualOrder(unit))
          '${unit.id}:${unit.movementPoints}:${unit.queuedPath != null}',
    ].join(',');
  }

  String _citiesNeedingProductionKey(List<GameCity> cities) {
    return [
      for (final city in cities)
        if (city.ownerPlayerId == activePlayerId &&
            city.productionQueue == null)
          city.id,
    ].join(',');
  }
}
