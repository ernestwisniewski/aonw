part of 'reducer_parity_movement_characterization.dart';

List<ReducerParityFixture> _movementRejectionCases(
  ReducerParityFixture template,
) => [
  ..._movementUnitRejectionCases(template),
  ..._movementSpatialRejectionCases(template),
];

List<ReducerParityFixture> _movementUnitRejectionCases(
  ReducerParityFixture template,
) {
  final line = _movementMap(template, cols: 3);
  return [
    _movementFixture(
      template,
      id: 'movement-characterization-unit-missing-rejected',
      tickOffset: 201,
      mapData: line,
      state: _movementState(template.state, mapCols: 3, units: const []),
      command: const MoveUnitCommand('missing_mover', 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-unit-working-rejected',
      tickOffset: 202,
      mapData: line,
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit(excavatingArtifactId: 'artifact_in_progress')],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-merchant-rejected',
      tickOffset: 203,
      mapData: line,
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit(type: GameUnitType.merchant)],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-current-tile-rejected',
      tickOffset: 204,
      mapData: line,
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit()],
      ),
      command: const MoveUnitCommand(_movementUnitId, 0, 0),
    ),
  ];
}

List<ReducerParityFixture> _movementSpatialRejectionCases(
  ReducerParityFixture template,
) => [
  ..._movementTerrainAndOccupancyRejectionCases(template),
  ..._movementBoundsAndVisibilityRejectionCases(template),
  ..._movementImpassableTerrainCases(template),
];

List<ReducerParityFixture> _movementImpassableTerrainCases(
  ReducerParityFixture template,
) => [
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-ocean-land-rejected',
    tickOffset: 213,
    targetTerrains: const [TerrainType.ocean],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-lake-land-rejected',
    tickOffset: 214,
    targetTerrains: const [TerrainType.lake],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-mountain-rejected',
    tickOffset: 215,
    targetTerrains: const [TerrainType.mountain],
  ),
];

List<ReducerParityFixture> _movementTerrainAndOccupancyRejectionCases(
  ReducerParityFixture template,
) {
  final line = _movementMap(template, cols: 3);
  final visibleBlocker = _movementUnit(
    id: 'visible_blocker',
    ownerPlayerId: _movementOpponentId,
    col: 1,
  );
  return [
    _movementFixture(
      template,
      id: 'movement-characterization-fortified-move-accepted',
      tickOffset: 209,
      mapData: _movementMap(template, cols: 3),
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [
          _movementUnit(movementPoints: 0, posture: UnitPosture.fortified),
        ],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-foreign-city-rejected',
      tickOffset: 205,
      mapData: line,
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit()],
        cities: const [
          GameCity(
            id: 'foreign_city',
            ownerPlayerId: _movementOpponentId,
            name: 'Foreign city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-visible-occupied-rejected',
      tickOffset: 206,
      mapData: line,
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit(), visibleBlocker],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-path-not-found-rejected',
      tickOffset: 207,
      mapData: _movementMap(
        template,
        cols: 2,
        terrainOverrides: const {
          (col: 1, row: 0): [TerrainType.mountain],
        },
      ),
      state: _movementState(
        template.state,
        mapCols: 2,
        units: [_movementUnit()],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-capacity-rejected',
      tickOffset: 208,
      mapData: _movementMap(
        template,
        cols: 2,
        terrainOverrides: const {
          (col: 1, row: 0): [
            TerrainType.snow,
            TerrainType.forest,
            TerrainType.hills,
          ],
        },
      ),
      state: _movementState(
        template.state,
        mapCols: 2,
        units: [_movementUnit(type: GameUnitType.warrior)],
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    ..._movementPassableTerrainCases(template),
  ];
}

List<ReducerParityFixture> _movementPassableTerrainCases(
  ReducerParityFixture template,
) => [
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-plains-accepted',
    tickOffset: 228,
    targetTerrains: const [TerrainType.plains],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-desert-accepted',
    tickOffset: 229,
    targetTerrains: const [TerrainType.desert],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-tundra-accepted',
    tickOffset: 230,
    targetTerrains: const [TerrainType.tundra],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-snow-accepted',
    tickOffset: 231,
    targetTerrains: const [TerrainType.snow],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-wetlands-accepted',
    tickOffset: 232,
    targetTerrains: const [TerrainType.wetlands],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-forest-accepted',
    tickOffset: 233,
    targetTerrains: const [TerrainType.grassland, TerrainType.forest],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-jungle-accepted',
    tickOffset: 234,
    targetTerrains: const [TerrainType.grassland, TerrainType.jungle],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-hills-accepted',
    tickOffset: 235,
    targetTerrains: const [TerrainType.grassland, TerrainType.hills],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-river-accepted',
    tickOffset: 236,
    targetTerrains: const [TerrainType.grassland, TerrainType.river],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-coast-land-accepted',
    tickOffset: 237,
    targetTerrains: const [TerrainType.coast],
  ),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-terrain-ocean-naval-accepted',
    tickOffset: 238,
    originTerrains: const [TerrainType.coast],
    targetTerrains: const [TerrainType.ocean],
    unit: _movementUnit(type: GameUnitType.scoutShip),
  ),
  _movementRoadAcceptanceCase(template),
  _movementTerrainFixture(
    template,
    id: 'movement-characterization-artifact-capacity-accepted',
    tickOffset: 240,
    targetTerrains: const [
      TerrainType.snow,
      TerrainType.forest,
      TerrainType.hills,
    ],
    unit: _movementUnit(
      movementPoints: 2,
      carriedArtifactId: 'movement_carried_artifact',
    ),
  ),
];

ReducerParityFixture _movementTerrainFixture(
  ReducerParityFixture template, {
  required String id,
  required int tickOffset,
  required List<TerrainType> targetTerrains,
  List<TerrainType> originTerrains = const [TerrainType.grassland],
  GameUnit? unit,
}) {
  return _movementFixture(
    template,
    id: id,
    tickOffset: tickOffset,
    mapData: _movementMap(
      template,
      cols: 2,
      terrainOverrides: {
        (col: 0, row: 0): originTerrains,
        (col: 1, row: 0): targetTerrains,
      },
    ),
    state: _movementState(
      template.state,
      mapCols: 2,
      units: [unit ?? _movementUnit()],
    ),
    command: const MoveUnitCommand(_movementUnitId, 1, 0),
  );
}

ReducerParityFixture _movementRoadAcceptanceCase(
  ReducerParityFixture template,
) {
  final roads = TransportNetworkState(
    segments: const [
      TransportSegment(
        hex: HexCoord(col: 0, row: 0),
        builtByPlayerId: _movementActorId,
      ),
      TransportSegment(
        hex: HexCoord(col: 1, row: 0),
        builtByPlayerId: _movementActorId,
      ),
    ],
  );
  return _movementFixture(
    template,
    id: 'movement-characterization-road-half-point-accepted',
    tickOffset: 239,
    mapData: _movementMap(
      template,
      cols: 2,
      terrainOverrides: const {
        (col: 1, row: 0): [TerrainType.snow],
      },
    ),
    state: _movementState(
      template.state,
      mapCols: 2,
      units: [_movementUnit()],
      transportNetwork: roads,
    ),
    command: const MoveUnitCommand(_movementUnitId, 1, 0),
  );
}

List<ReducerParityFixture> _movementBoundsAndVisibilityRejectionCases(
  ReducerParityFixture template,
) {
  final line = _movementMap(template, cols: 3);
  return [
    _movementFixture(
      template,
      id: 'movement-characterization-invalid-origin-rejected',
      tickOffset: 210,
      mapData: line,
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit(col: -1)],
      ),
      command: const MoveUnitCommand(_movementUnitId, 0, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-far-hidden-rejected',
      tickOffset: 211,
      mapData: _movementMap(template, cols: 5),
      state: _movementState(
        template.state,
        mapCols: 5,
        units: [_movementUnit()],
        cities: const [
          GameCity(
            id: 'far_hidden_foreign_city',
            ownerPlayerId: _movementOpponentId,
            name: 'Far hidden foreign city',
            center: CityHex(col: 4, row: 0),
          ),
        ],
        fogOfWar: _movementFog(
          discovered: {const HexCoordinate(col: 0, row: 0)},
          visible: {const HexCoordinate(col: 0, row: 0)},
        ),
      ),
      command: const MoveUnitCommand(_movementUnitId, 4, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-no-fog-occupied-rejected',
      tickOffset: 212,
      mapData: _movementMap(template, cols: 2),
      state: _movementState(
        template.state,
        mapCols: 2,
        units: [
          _movementUnit(),
          _movementUnit(
            id: 'no_fog_blocker',
            ownerPlayerId: _movementOpponentId,
            col: 1,
          ),
        ],
        fogOfWar: FogOfWarState.empty,
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
  ];
}

List<ReducerParityFixture> _movementAcceptanceCases(
  ReducerParityFixture template,
) {
  return [
    _movementFixture(
      template,
      id: 'movement-characterization-partial-queued-accepted',
      tickOffset: 221,
      mapData: _movementMap(template, cols: 5),
      state: _movementState(
        template.state,
        mapCols: 5,
        units: [_movementUnit(movementPoints: 2)],
      ),
      command: const MoveUnitCommand(_movementUnitId, 4, 0),
    ),
    _roughPrefixMovementAcceptanceCase(template),
    _movementFixture(
      template,
      id: 'movement-characterization-zero-movement-queued-accepted',
      tickOffset: 222,
      mapData: _movementMap(template, cols: 3),
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [_movementUnit(movementPoints: 0)],
      ),
      command: const MoveUnitCommand(_movementUnitId, 2, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-hidden-target-no-op-accepted',
      tickOffset: 223,
      mapData: _movementMap(template, cols: 2),
      state: _movementState(
        template.state,
        mapCols: 2,
        units: [
          _movementUnit(),
          _movementUnit(
            id: 'hidden_target',
            ownerPlayerId: _movementOpponentId,
            col: 1,
          ),
        ],
        fogOfWar: _movementFog(visible: {const HexCoordinate(col: 0, row: 0)}),
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-hidden-intermediate-no-op-accepted',
      tickOffset: 224,
      mapData: _movementMap(template, cols: 3),
      state: _movementState(
        template.state,
        mapCols: 3,
        units: [
          _movementUnit(),
          _movementUnit(
            id: 'hidden_intermediate',
            ownerPlayerId: _movementOpponentId,
            col: 1,
          ),
        ],
        fogOfWar: _movementFog(
          visible: {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 2, row: 0),
          },
        ),
      ),
      command: const MoveUnitCommand(_movementUnitId, 2, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-hidden-city-no-op-accepted',
      tickOffset: 226,
      mapData: _movementMap(template, cols: 2),
      state: _movementState(
        template.state,
        mapCols: 2,
        units: [_movementUnit()],
        cities: const [
          GameCity(
            id: 'hidden_foreign_city',
            ownerPlayerId: _movementOpponentId,
            name: 'Hidden foreign city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        fogOfWar: _movementFog(visible: {const HexCoordinate(col: 0, row: 0)}),
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
    _movementFixture(
      template,
      id: 'movement-characterization-contact-discovery-accepted',
      tickOffset: 225,
      mapData: _movementMap(template, cols: 4),
      state: _movementState(
        template.state,
        mapCols: 4,
        units: [
          _movementUnit(),
          _movementUnit(
            id: 'contact_opponent',
            ownerPlayerId: _movementOpponentId,
            col: 3,
          ),
        ],
        fogOfWar: _movementFog(visible: {const HexCoordinate(col: 0, row: 0)}),
        diplomacy: DiplomacyState.empty,
      ),
      command: const MoveUnitCommand(_movementUnitId, 1, 0),
    ),
  ];
}

ReducerParityFixture _roughPrefixMovementAcceptanceCase(
  ReducerParityFixture template,
) {
  return _movementFixture(
    template,
    id: 'movement-characterization-rough-prefix-exhausted-accepted',
    tickOffset: 227,
    mapData: _movementMap(
      template,
      cols: 4,
      terrainOverrides: const {
        (col: 1, row: 0): [TerrainType.plains, TerrainType.forest],
        (col: 2, row: 0): [TerrainType.plains, TerrainType.forest],
      },
    ),
    state: _movementState(
      template.state,
      mapCols: 4,
      units: [_movementUnit(type: GameUnitType.warrior, movementPoints: 3)],
    ),
    command: const MoveUnitCommand(_movementUnitId, 3, 0),
  );
}
