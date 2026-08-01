part of 'game_event_descriptor.dart';

_GameEventPlayerIdsResolver _cityOwnerPlayerIds(String cityId) {
  return (state, previousState, visiblePlayerId) =>
      _orderedPlayerIds([_cityOwner(state, cityId)]);
}

_GameEventPlayerIdsResolver _unitOwnerPlayerIds(String unitId) {
  return (state, previousState, visiblePlayerId) => _orderedPlayerIds([
    _unitOwner(state, unitId) ?? _unitOwner(previousState, unitId),
  ]);
}

_GameEventPlayerIdsResolver _combatPlayerIds({
  required String attackerUnitId,
  required String defenderUnitId,
}) {
  return (state, previousState, visiblePlayerId) => _orderedPlayerIds([
    _unitOwner(state, attackerUnitId) ??
        _unitOwner(previousState, attackerUnitId),
    _unitOwner(state, defenderUnitId) ??
        _unitOwner(previousState, defenderUnitId) ??
        _cityOwner(state, defenderUnitId) ??
        _cityOwner(previousState, defenderUnitId),
  ]);
}

_GameEventPlayerIdsResolver _unitKilledPlayerIds({
  required String ownerPlayerId,
  required String? attackerUnitId,
}) {
  return (state, previousState, visiblePlayerId) => _orderedPlayerIds([
    ownerPlayerId,
    if (attackerUnitId != null)
      _unitOwner(state, attackerUnitId) ??
          _unitOwner(previousState, attackerUnitId) ??
          _cityOwner(state, attackerUnitId) ??
          _cityOwner(previousState, attackerUnitId),
  ]);
}

_GameEventPlayerIdsResolver _visiblePlayerAnd(String playerId) {
  return (state, previousState, visiblePlayerId) =>
      _orderedPlayerIds([visiblePlayerId, playerId]);
}

_GameEventPlayerIdsResolver _visiblePlayer() {
  return (state, previousState, visiblePlayerId) =>
      _orderedPlayerIds([visiblePlayerId]);
}

List<String> _orderedPlayerIds(Iterable<String?> playerIds) {
  final ordered = <String>[];
  final seen = <String>{};
  for (final playerId in playerIds) {
    if (playerId == null || playerId.isEmpty || !seen.add(playerId)) continue;
    ordered.add(playerId);
  }
  return List.unmodifiable(ordered);
}

String? _cityOwner(GameClientState? state, String cityId) {
  return state?.cityById(cityId)?.ownerPlayerId;
}

String? _unitOwner(GameClientState? state, String unitId) {
  return state?.unitById(unitId)?.ownerPlayerId;
}

bool _unitBelongsTo(GameClientState state, String unitId, String playerId) {
  return _unitOwner(state, unitId) == playerId;
}
