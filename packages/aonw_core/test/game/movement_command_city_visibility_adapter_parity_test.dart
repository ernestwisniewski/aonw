import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'movement_command_resolver_adapter_parity_test_support.dart';

void main() {
  group('movement command city visibility adapter parity', () {
    test('hidden foreign city does not expose a city-specific rejection', () {
      const hiddenCity = GameCity(
        id: 'hidden_city',
        ownerPlayerId: movementOpponentId,
        name: 'Hidden city',
        center: CityHex(col: 1, row: 0),
      );
      final states = movementStates(
        mover: movementUnit(),
        cities: const [hiddenCity],
        fogOfWar: movementFog(visibleCols: 1),
      );
      const command = MoveUnitCommand(movementUnitId, 1, 0);
      final map = movementMap(cols: 2);

      final authoritative = resolveMovement(states, command, map);
      final unrestricted = resolveMovement(
        states,
        command,
        map,
        visibilityMode: MovementCommandVisibilityMode.unrestricted,
      );

      expect(authoritative.kernel.accepted, isTrue);
      expect(authoritative.kernel.reason, isNull);
      expect(authoritative.kernel.units, same(states.kernel.units));
      expect(authoritative.kernel.events, isEmpty);
      expect(authoritative.kernel.execution, isNull);
      expect(authoritative.engine.snapshot, same(states.engine));
      expect(authoritative.domain.state, same(states.domain));
      expectRejectedMovementIdentity(
        states,
        unrestricted,
        reason: 'move_target_is_foreign_city_center',
      );
    });

    test('far unknown foreign city is hidden behind the pathing horizon', () {
      const hiddenCity = GameCity(
        id: 'far_hidden_city',
        ownerPlayerId: movementOpponentId,
        name: 'Far hidden city',
        center: CityHex(col: 4, row: 0),
      );
      final states = movementStates(
        mover: movementUnit(),
        cities: const [hiddenCity],
        fogOfWar: movementFog(visibleCols: 1),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 4, 0),
        movementMap(cols: 5),
      );

      expectRejectedMovementIdentity(
        states,
        results,
        reason: 'move_path_not_found',
      );
    });

    test('terrain memory does not reveal a currently hidden foreign city', () {
      const rememberedCity = GameCity(
        id: 'remembered_city',
        ownerPlayerId: movementOpponentId,
        name: 'Remembered city',
        center: CityHex(col: 1, row: 0),
      );
      final states = movementStates(
        mover: movementUnit(),
        cities: const [rememberedCity],
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 2),
      );

      const command = MoveUnitCommand(movementUnitId, 1, 0);
      final map = movementMap(cols: 2);
      final authoritative = resolveMovement(states, command, map);
      final pathing = resolveMovement(
        states,
        command,
        map,
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
      );
      final unrestricted = resolveMovement(
        states,
        command,
        map,
        visibilityMode: MovementCommandVisibilityMode.unrestricted,
      );

      expectAcceptedMovementIdentity(states, authoritative);
      expectAcceptedMovementIdentity(states, pathing);
      expectRejectedMovementIdentity(
        states,
        unrestricted,
        reason: 'move_target_is_foreign_city_center',
      );
    });

    test('hidden foreign city cannot mask a capacity rejection', () {
      const hiddenCity = GameCity(
        id: 'hidden_expensive_city',
        ownerPlayerId: movementOpponentId,
        name: 'Hidden expensive city',
        center: CityHex(col: 1, row: 0),
      );
      final withoutCity = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 10),
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 2),
      );
      final withCity = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 10),
        cities: const [hiddenCity],
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 2),
      );
      const command = MoveUnitCommand(movementUnitId, 1, 0);
      final map = movementMap(
        cols: 2,
        terrainOverrides: {
          (col: 1, row: 0): [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.jungle,
            TerrainType.hills,
          ],
        },
      );

      final baseline = resolveMovement(withoutCity, command, map);
      final blocked = resolveMovement(withCity, command, map);

      expectRejectedMovementIdentity(
        withoutCity,
        baseline,
        reason: 'unit_movement_capacity_insufficient',
      );
      expectRejectedMovementIdentity(
        withCity,
        blocked,
        reason: 'unit_movement_capacity_insufficient',
      );
    });

    test('known intermediate foreign city blocks the route', () {
      const city = GameCity(
        id: 'visible_intermediate_city',
        ownerPlayerId: movementOpponentId,
        name: 'Visible intermediate city',
        center: CityHex(col: 1, row: 0),
      );
      final states = movementStates(
        mover: movementUnit(),
        cities: const [city],
        fogOfWar: movementFog(visibleCols: 3),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 2, 0),
        movementMap(cols: 3),
      );

      expectRejectedMovementIdentity(
        states,
        results,
        reason: 'move_path_not_found',
      );
    });

    test('hidden intermediate foreign city stops the reachable prefix', () {
      const city = GameCity(
        id: 'hidden_intermediate_city',
        ownerPlayerId: movementOpponentId,
        name: 'Hidden intermediate city',
        center: CityHex(col: 1, row: 0),
      );
      final states = movementStates(
        mover: movementUnit(),
        cities: const [city],
        fogOfWar: movementFog(visibleCols: 1),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 2, 0),
        movementMap(cols: 3),
      );

      expectAcceptedMovementIdentity(states, results);
    });

    test('unknown foreign city preserves the reachable movement prefix', () {
      const hiddenCity = GameCity(
        id: 'partial_hidden_city',
        ownerPlayerId: movementOpponentId,
        name: 'Partial hidden city',
        center: CityHex(col: 3, row: 0),
      );
      final withoutCity = movementStates(
        mover: movementUnit(movementPoints: 1),
        fogOfWar: movementFog(visibleCols: 1),
      );
      final withCity = movementStates(
        mover: movementUnit(movementPoints: 1),
        cities: const [hiddenCity],
        fogOfWar: movementFog(visibleCols: 1),
      );
      const command = MoveUnitCommand(movementUnitId, 3, 0);
      final map = movementMap(cols: 4);

      final baseline = resolveMovement(withoutCity, command, map);
      final results = resolveMovement(withCity, command, map);

      expectAcceptedMovementParity(withoutCity, baseline);
      expectAcceptedMovementParity(withCity, results);
      expect(results.kernel.units.first, baseline.kernel.units.first);
      expect(
        executionSnapshot(results.kernel.execution),
        executionSnapshot(baseline.kernel.execution),
      );
      expect(results.kernel.units.first.col, 1);
      expect(results.kernel.units.first.queuedPath?.targetCol, 3);
    });
  });
}
