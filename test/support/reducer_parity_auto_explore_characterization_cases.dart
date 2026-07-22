part of 'reducer_parity_auto_explore_characterization.dart';

List<ReducerParityFixture> _autoExploreRejectionCases(
  ReducerParityFixture template,
) {
  final map = _autoExploreMap(template, cols: 2);
  final path = _autoExploreQueuedPath(targetCol: 1);
  return [
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-unit-missing-rejected',
      tickOffset: 301,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: const [],
        interactionUnitId: 'missing_scout',
      ),
      command: const AutoExploreUnitCommand('missing_scout'),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-wrong-actor-precedence-rejected',
      tickOffset: 302,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: [
          _autoExploreUnit(
            ownerPlayerId: _autoExploreOpponentId,
            type: GameUnitType.commander,
            movementPoints: 0,
            queuedPath: path,
            excavatingArtifactId: 'busy_artifact',
          ),
        ],
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-non-scout-precedence-rejected',
      tickOffset: 303,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: [
          _autoExploreUnit(
            type: GameUnitType.commander,
            movementPoints: 0,
            queuedPath: path,
            excavatingArtifactId: 'busy_artifact',
          ),
        ],
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-working-precedence-rejected',
      tickOffset: 304,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: [
          _autoExploreUnit(
            movementPoints: 0,
            queuedPath: path,
            excavatingArtifactId: 'busy_artifact',
          ),
        ],
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-fortified-precedence-rejected',
      tickOffset: 305,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: [
          _autoExploreUnit(
            movementPoints: 0,
            queuedPath: path,
            posture: UnitPosture.fortified,
          ),
        ],
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-exhausted-precedence-rejected',
      tickOffset: 306,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: [_autoExploreUnit(movementPoints: 0, queuedPath: path)],
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-queued-path-rejected',
      tickOffset: 307,
      mapData: map,
      state: _autoExploreState(
        template.state,
        units: [_autoExploreUnit(movementPoints: 1, queuedPath: path)],
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
  ];
}

List<ReducerParityFixture> _autoExploreAcceptanceCases(
  ReducerParityFixture template,
) {
  final knownThroughFour = {
    for (var col = 0; col <= 4; col++) HexCoordinate(col: col, row: 0),
  };
  return [
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-partial-queued-accepted',
      tickOffset: 321,
      mapData: _autoExploreMap(template, cols: 8),
      state: _autoExploreState(
        template.state,
        units: [_autoExploreUnit(movementPoints: 1)],
        fogOfWar: _autoExploreFog(
          discovered: knownThroughFour,
          visible: knownThroughFour,
        ),
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-tie-break-accepted',
      tickOffset: 322,
      mapData: _autoExploreMap(template, cols: 3),
      state: _autoExploreState(
        template.state,
        units: [_autoExploreUnit(col: 1)],
        fogOfWar: _autoExploreFog(
          discovered: {const HexCoordinate(col: 1, row: 0)},
          visible: {const HexCoordinate(col: 1, row: 0)},
        ),
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-no-fog-accepted',
      tickOffset: 323,
      mapData: _autoExploreMap(template, cols: 3),
      state: _autoExploreState(
        template.state,
        units: [_autoExploreUnit()],
        fogOfWar: FogOfWarState.empty,
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-hidden-city-no-op-accepted',
      tickOffset: 324,
      mapData: _autoExploreMap(template, cols: 2),
      state: _autoExploreState(
        template.state,
        units: [_autoExploreUnit()],
        cities: const [
          GameCity(
            id: 'hidden_foreign_city',
            ownerPlayerId: _autoExploreOpponentId,
            name: 'Hidden foreign city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        fogOfWar: _autoExploreFog(
          discovered: {const HexCoordinate(col: 0, row: 0)},
          visible: {const HexCoordinate(col: 0, row: 0)},
        ),
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
    _autoExploreFixture(
      template,
      id: 'auto-explore-characterization-contact-discovery-accepted',
      tickOffset: 325,
      mapData: _autoExploreMap(template, cols: 4),
      state: _autoExploreState(
        template.state,
        units: [
          _autoExploreUnit(),
          _autoExploreUnit(
            id: 'contact_unit',
            ownerPlayerId: _autoExploreOpponentId,
            col: 3,
          ),
        ],
        fogOfWar: _autoExploreFog(
          discovered: {const HexCoordinate(col: 0, row: 0)},
          visible: {const HexCoordinate(col: 0, row: 0)},
        ),
      ),
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
    ),
  ];
}
