part of 'game_event_renderer_effect_mapper.dart';

RendererEffect? _cityFoundedEffect(
  GameClientState state,
  String cityId,
  String ownerPlayerId, {
  String? viewerPlayerId,
}) {
  final city = state.cityById(cityId);
  if (city == null) return null;
  if (!_canRenderTransientAt(
    state,
    city.center.col,
    city.center.row,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  return SpawnParticleBurstEffect(
    kind: ParticleBurstKind.cityFounded,
    col: city.center.col,
    row: city.center.row,
    colorValue: _colorForPlayer(state, ownerPlayerId),
  );
}

RendererEffect? _cityProducedUnitEffect(
  GameClientState state,
  String cityId, {
  String? viewerPlayerId,
}) {
  final city = state.cityById(cityId);
  if (city == null) return null;
  if (!_canRenderTransientAt(
    state,
    city.center.col,
    city.center.row,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  return SpawnParticleBurstEffect(
    kind: ParticleBurstKind.unitProduced,
    col: city.center.col,
    row: city.center.row,
    colorValue: _colorForPlayer(state, city.ownerPlayerId),
  );
}

RendererEffect? _claimedHexEffect(
  GameClientState state,
  String cityId,
  int col,
  int row, {
  String? viewerPlayerId,
}) {
  final city = state.cityById(cityId);
  if (city == null) return null;
  if (!_canRenderTransientAt(state, col, row, viewerPlayerId: viewerPlayerId)) {
    return null;
  }
  return SpawnParticleBurstEffect(
    kind: ParticleBurstKind.hexClaimed,
    col: col,
    row: row,
    colorValue: _colorForPlayer(state, city.ownerPlayerId),
  );
}

RendererEffect? _technologyResearchedEffect(
  GameClientState state,
  String playerId, {
  String? viewerPlayerId,
}) {
  final anchor = _playerAnchor(state, playerId);
  if (anchor == null) return null;
  if (!_canRenderTransientAt(
    state,
    anchor.col,
    anchor.row,
    viewerPlayerId: viewerPlayerId,
  )) {
    return null;
  }
  return SpawnParticleBurstEffect(
    kind: ParticleBurstKind.technologyResearched,
    col: anchor.col,
    row: anchor.row,
    colorValue: _colorForPlayer(state, playerId),
  );
}

({int col, int row})? _playerAnchor(_S state, String playerId) {
  for (final city in state.cities) {
    if (city.ownerPlayerId == playerId) {
      return (col: city.center.col, row: city.center.row);
    }
  }
  for (final unit in state.units) {
    if (unit.ownerPlayerId == playerId) {
      return (col: unit.col, row: unit.row);
    }
  }
  return null;
}
