part of 'reducer_parity_movement_characterization.dart';

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
