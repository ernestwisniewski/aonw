part of 'reducer_parity_auto_explore_characterization.dart';

PersistentGameState _autoExploreExpectedState(
  String fixtureId,
  PersistentGameState state,
) {
  if (fixtureId.endsWith('-rejected')) return state;
  return switch (fixtureId) {
    'auto-explore-characterization-partial-queued-accepted' =>
      _autoExploreAfterMove(
        state,
        fromCol: 0,
        toCol: 1,
        movementPoints: 0,
        queuedPath: _autoExploreQueuedPath(targetCol: 5),
        fogOfWar: state.fogOfWar,
      ),
    'auto-explore-characterization-tie-break-accepted' => _autoExploreAfterMove(
      state,
      fromCol: 1,
      toCol: 0,
      movementPoints: 1,
      fogOfWar: _autoExploreFog(
        discovered: _autoExploreLineHexes(3),
        visible: _autoExploreLineHexes(3),
      ),
    ),
    'auto-explore-characterization-no-fog-accepted' => _autoExploreAfterMove(
      state,
      fromCol: 0,
      toCol: 1,
      movementPoints: 1,
      fogOfWar: _autoExploreFog(
        discovered: _autoExploreLineHexes(3),
        visible: _autoExploreLineHexes(3),
      ),
    ),
    'auto-explore-characterization-hidden-city-no-op-accepted' =>
      _autoExploreAfterAcceptedNoOp(state),
    'auto-explore-characterization-contact-discovery-accepted' =>
      _autoExploreAfterMove(
        state,
        fromCol: 0,
        toCol: 1,
        movementPoints: 1,
        fogOfWar: _autoExploreFog(
          discovered: _autoExploreLineHexes(4),
          visible: _autoExploreLineHexes(4),
        ),
        diplomacy: state.runtimeState.diplomacy.addContactKeys(const {
          'player_1|player_2',
        }),
      ),
    _ => throw StateError('Missing auto-explore oracle: $fixtureId.'),
  };
}

List<GameEvent> _autoExploreExpectedEvents(String fixtureId) {
  return switch (fixtureId) {
    'auto-explore-characterization-partial-queued-accepted' => const [
      UnitMovedEvent(
        unitId: _autoExploreUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
    ],
    'auto-explore-characterization-tie-break-accepted' => const [
      UnitMovedEvent(
        unitId: _autoExploreUnitId,
        fromCol: 1,
        fromRow: 0,
        toCol: 0,
        toRow: 0,
      ),
    ],
    'auto-explore-characterization-no-fog-accepted' ||
    'auto-explore-characterization-contact-discovery-accepted' => const [
      UnitMovedEvent(
        unitId: _autoExploreUnitId,
        fromCol: 0,
        fromRow: 0,
        toCol: 1,
        toRow: 0,
      ),
    ],
    _ => const [],
  };
}

PersistentGameState _autoExploreAfterMove(
  PersistentGameState state, {
  required int fromCol,
  required int toCol,
  required int movementPoints,
  required FogOfWarState fogOfWar,
  QueuedMovePath? queuedPath,
  DiplomacyState? diplomacy,
}) {
  final unit = state.units.singleWhere(
    (candidate) => candidate.id == _autoExploreUnitId,
  );
  if (unit.col != fromCol || unit.row != 0) {
    throw StateError('Auto-explore oracle received an unexpected origin.');
  }
  final moved = unit
      .copyWith(
        col: toCol,
        row: 0,
        movementPoints: movementPoints,
        posture: UnitPosture.autoExploring,
      )
      .copyWithQueuedPath(queuedPath);
  return state.copyWith(
    units: _autoExploreReplaceUnit(state.units, moved),
    fogOfWar: fogOfWar,
    runtimeState: state.runtimeState.copyWith(
      cityFoundingDraft: null,
      pendingAction: null,
      diplomacy: diplomacy ?? state.runtimeState.diplomacy,
    ),
  );
}

PersistentGameState _autoExploreAfterAcceptedNoOp(PersistentGameState state) {
  final unit = state.units.singleWhere(
    (candidate) => candidate.id == _autoExploreUnitId,
  );
  final exploring = unit
      .copyWith(posture: UnitPosture.autoExploring)
      .copyWithQueuedPath(null);
  return state.copyWith(
    units: _autoExploreReplaceUnit(state.units, exploring),
    runtimeState: state.runtimeState.copyWith(
      cityFoundingDraft: null,
      pendingAction: null,
    ),
  );
}

Set<HexCoordinate> _autoExploreLineHexes(int cols) => {
  for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: 0),
};

List<GameUnit> _autoExploreReplaceUnit(List<GameUnit> units, GameUnit updated) {
  return [
    for (final unit in units)
      if (unit.id == updated.id) updated else unit,
  ];
}
