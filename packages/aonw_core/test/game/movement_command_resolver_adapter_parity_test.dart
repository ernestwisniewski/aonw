import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'movement_command_resolver_adapter_parity_test_support.dart';

part 'movement_command_resolver_adapter_parity_edge_cases.dart';

void main() {
  group('movement kernel and state adapters', () {
    test('partial move has exact state, event, and execution parity', () {
      final states = movementStates(
        mover: movementUnit(movementPoints: 2),
        fogOfWar: movementFog(visibleCols: 5),
      );
      const command = MoveUnitCommand(movementUnitId, 4, 0);

      final results = resolveMovement(states, command, movementMap(cols: 5));

      expectAcceptedMovementParity(states, results);
      final moved = results.kernel.units.first;
      expect((moved.col, moved.row, moved.movementPoints), (2, 0, 0));
      expect(moved.queuedPath?.targetCol, 4);
      expect(stepCoordinates(moved.queuedPath!.steps), const [
        (0, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (4, 0),
      ]);
      expect(stepCoordinates(results.kernel.execution!.steps), const [
        (1, 0),
        (2, 0),
      ]);
      expect(
        (
          results.kernel.execution!.unitId,
          results.kernel.execution!.fromCol,
          results.kernel.execution!.fromRow,
        ),
        (movementUnitId, 0, 0),
      );
      expect(
        () => results.kernel.execution!.steps.add(
          const UnitMovementStep(
            col: 9,
            row: 9,
            enterCost: 1,
            cumulativeCost: 9,
          ),
        ),
        throwsUnsupportedError,
      );
      expectMoveEvent(results.kernel.events, fromCol: 0, toCol: 2);
    });

    test('all boundaries honor the injected fog service', () {
      final states = movementStates(
        mover: movementUnit(),
        fogOfWar: movementFog(visibleCols: 3),
      );
      const command = MoveUnitCommand(movementUnitId, 1, 0);
      final map = movementMap(cols: 3);
      final kernelCounters = FogOfWarRecomputeCounters();
      final domainCounters = FogOfWarRecomputeCounters();

      final kernel =
          MovementCommandResolver(
            fogOfWarService: FogOfWarService(counters: kernelCounters),
          ).resolve(
            state: states.kernel,
            command: command,
            actorPlayerId: movementActorId,
            mapData: map,
          );
      final engine = const GameEngine().apply(
        snapshot: states.engine,
        command: command,
        context: GameEngineContext(
          actorPlayerId: movementActorId,
          mapView: map,
          ruleset: GameRuleset.defaults,
          commandTick: 1,
        ),
      );
      final domain =
          DomainMoveUnitResolver(
            commandResolver: MovementCommandResolver(
              fogOfWarService: FogOfWarService(counters: domainCounters),
            ),
          ).resolve(
            state: states.domain,
            command: command,
            actorPlayerId: movementActorId,
            mapData: map,
          );

      expect(
        (kernel.accepted, engine is GameEngineAccepted, domain.accepted),
        (true, true, true),
      );
      expect(kernelCounters.unitMoveIncrementalCount, 1);
      expect(domainCounters.unitMoveIncrementalCount, 1);
    });

    test('zero movement queues without an event or execution', () {
      final states = movementStates(mover: movementUnit(movementPoints: 0));
      const command = MoveUnitCommand(movementUnitId, 2, 0);

      final results = resolveMovement(states, command, movementMap(cols: 3));

      expectAcceptedMovementParity(states, results);
      expect(results.kernel.units.first.queuedPath?.targetCol, 2);
      expect(results.kernel.events, isEmpty);
      expect(results.kernel.execution, isNull);
      expect(results.engine.movementDelta.executions, isEmpty);
      expect(results.domain.execution, isNull);
      expect(
        results.engine.snapshot.domain.fogOfWar,
        same(states.engine.domain.fogOfWar),
      );
      expect(results.domain.state.fogOfWar, same(states.domain.fogOfWar));
    });

    test('land unit with 2/3 movement returns from coast to forest', () {
      final states = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 2),
      );
      final map = movementMap(
        cols: 2,
        terrainOverrides: const {
          (col: 0, row: 0): [TerrainType.coast],
          (col: 1, row: 0): [TerrainType.forest],
        },
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 1, 0),
        map,
      );

      expectAcceptedMovementParity(states, results);
      final moved = results.kernel.units.first;
      expect((moved.col, moved.row, moved.movementPoints), (1, 0, 0));
      expect(moved.queuedPath, isNull);
      expect(results.kernel.execution?.steps.single.enterCost, 4);
      expectMoveEvent(results.kernel.events, fromCol: 0, toCol: 1);
    });

    test('artifact carrier spends its turn entering rough terrain', () {
      final carrier = movementUnit(
        type: GameUnitType.warrior,
        movementPoints: 2,
      ).copyWithCarriedArtifact('artifact_1');
      final states = movementStates(mover: carrier);
      final map = movementMap(
        cols: 2,
        terrainOverrides: const {
          (col: 0, row: 0): [TerrainType.coast],
          (col: 1, row: 0): [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.hills,
          ],
        },
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 1, 0),
        map,
      );

      expectAcceptedMovementParity(states, results);
      final moved = results.kernel.units.first;
      expect((moved.col, moved.row, moved.movementPoints), (1, 0, 0));
      expect(results.kernel.execution?.steps.single.enterCost, 6);
      expectMoveEvent(results.kernel.events, fromCol: 0, toCol: 1);
    });

    test('fortified unit wakes and moves at every state boundary', () {
      final states = movementStates(
        mover: movementUnit(movementPoints: 0, posture: UnitPosture.fortified),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 1, 0),
        movementMap(cols: 2),
      );

      expectAcceptedMovementParity(states, results);
      final moved = results.kernel.units.first;
      expect((moved.col, moved.row), (1, 0));
      expect(moved.posture, UnitPosture.active);
      expect(
        moved.movementPoints,
        UnitMovementBalance.maxMovementPointsForType(moved.type) - 1,
      );
      expectMoveEvent(results.kernel.events, fromCol: 0, toCol: 1);
    });

    test('rejected fortified movement preserves fortification identity', () {
      final states = movementStates(
        mover: movementUnit(movementPoints: 0, posture: UnitPosture.fortified),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 1, 0),
        movementMap(
          cols: 2,
          terrainOverrides: const {
            (col: 1, row: 0): [TerrainType.ocean],
          },
        ),
      );

      expectRejectedMovementIdentity(
        states,
        results,
        reason: 'move_path_not_found',
      );
    });

    test('invalid origin is rejected before target validation', () {
      final states = movementStates(mover: movementUnit(col: -1));

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 0, 0),
        movementMap(cols: 2),
      );

      expectRejectedMovementIdentity(
        states,
        results,
        reason: 'unit_out_of_bounds',
      );
    });

    test('far undiscovered target is rejected by authoritative horizon', () {
      final states = movementStates(
        mover: movementUnit(),
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

    test('unrestricted pathing bypasses the terrain-knowledge horizon', () {
      final states = movementStates(
        mover: movementUnit(),
        fogOfWar: movementFog(visibleCols: 1),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 4, 0),
        movementMap(cols: 5),
        visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
      );

      expectAcceptedMovementParity(states, results);
      expect(
        (results.kernel.units.first.col, results.kernel.units.first.row),
        (4, 0),
      );
    });

    test('missing actor fog means fog disabled and exposes target blocker', () {
      final blocker = movementUnit(
        id: 'blocker',
        ownerPlayerId: movementOpponentId,
        col: 1,
      );
      final states = movementStates(
        mover: movementUnit(),
        additionalUnits: [blocker],
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 1, 0),
        movementMap(cols: 2),
      );

      expectRejectedMovementIdentity(
        states,
        results,
        reason: 'move_target_occupied',
      );
    });

    test('hidden dynamic blocker remains an accepted identity no-op', () {
      final blocker = movementUnit(
        id: 'hidden_blocker',
        ownerPlayerId: movementOpponentId,
        col: 1,
      );
      final states = movementStates(
        mover: movementUnit(),
        additionalUnits: [blocker],
        fogOfWar: movementFog(visibleCols: 1),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 1, 0),
        movementMap(cols: 2),
      );

      expect(results.kernel.accepted, isTrue);
      expect(results.engine, isA<GameEngineAccepted>());
      expect(results.domain.accepted, isTrue);
      expect(results.kernel.reason, isNull);
      expect(results.kernel.units, same(states.kernel.units));
      expect(results.kernel.fogOfWar, same(states.kernel.fogOfWar));
      expect(results.kernel.diplomacy, same(states.kernel.diplomacy));
      expect(results.kernel.events, isEmpty);
      expect(results.kernel.execution, isNull);
      expect(results.engine.snapshot, same(states.engine));
      expect(results.domain.state, same(states.domain));
    });

    test('hidden intermediate blocker cannot force an alternate route', () {
      final blocker = movementUnit(
        id: 'hidden_intermediate',
        ownerPlayerId: movementOpponentId,
        col: 1,
      );
      final states = movementStates(
        mover: movementUnit(),
        additionalUnits: [blocker],
        fogOfWar: movementFog(visibleCols: 1),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 2, 0),
        movementMap(cols: 3, rows: 2),
      );

      expect(results.kernel.accepted, isTrue);
      expect(results.engine, isA<GameEngineAccepted>());
      expect(results.domain.accepted, isTrue);
      expect(results.kernel.reason, isNull);
      expect(results.kernel.units, same(states.kernel.units));
      expect(results.kernel.fogOfWar, same(states.kernel.fogOfWar));
      expect(results.kernel.diplomacy, same(states.kernel.diplomacy));
      expect(results.kernel.events, isEmpty);
      expect(results.kernel.execution, isNull);
      expect(results.engine.snapshot, same(states.engine));
      expect(results.domain.state, same(states.domain));
    });

    test('hidden blocker cannot mask a movement-capacity rejection', () {
      final blocker = movementUnit(
        id: 'hidden_expensive_blocker',
        ownerPlayerId: movementOpponentId,
        col: 1,
      );
      final withoutBlocker = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 10),
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 2),
      );
      final withBlocker = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 10),
        additionalUnits: [blocker],
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

      final baseline = resolveMovement(withoutBlocker, command, map);
      final blocked = resolveMovement(withBlocker, command, map);

      expectRejectedMovementIdentity(
        withoutBlocker,
        baseline,
        reason: 'unit_movement_capacity_insufficient',
      );
      expectRejectedMovementIdentity(
        withBlocker,
        blocked,
        reason: 'unit_movement_capacity_insufficient',
      );
    });

    test('hidden target approach keeps known-route capacity semantics', () {
      final blocker = movementUnit(
        id: 'hidden_distant_expensive_blocker',
        ownerPlayerId: movementOpponentId,
        col: 2,
      );
      final withoutBlocker = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 10),
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 3),
      );
      final withBlocker = movementStates(
        mover: movementUnit(type: GameUnitType.warrior, movementPoints: 10),
        additionalUnits: [blocker],
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 3),
      );
      const command = MoveUnitCommand(movementUnitId, 2, 0);
      final map = movementMap(
        cols: 3,
        terrainOverrides: {
          (col: 2, row: 0): [
            TerrainType.grassland,
            TerrainType.forest,
            TerrainType.jungle,
            TerrainType.hills,
          ],
        },
      );

      final baseline = resolveMovement(withoutBlocker, command, map);
      final blocked = resolveMovement(withBlocker, command, map);

      expectRejectedMovementIdentity(
        withoutBlocker,
        baseline,
        reason: 'unit_movement_capacity_insufficient',
      );
      expectRejectedMovementIdentity(
        withBlocker,
        blocked,
        reason: 'unit_movement_capacity_insufficient',
      );
    });

    test('distant hidden target blocker preserves the direct queued path', () {
      final blocker = movementUnit(
        id: 'hidden_target',
        ownerPlayerId: movementOpponentId,
        col: 4,
      );
      final states = movementStates(
        mover: movementUnit(movementPoints: 2),
        additionalUnits: [blocker],
        fogOfWar: movementFog(visibleCols: 1, discoveredCols: 5),
      );

      final results = resolveMovement(
        states,
        const MoveUnitCommand(movementUnitId, 4, 0),
        movementMap(cols: 5, rows: 2),
      );

      expectAcceptedMovementParity(states, results);
      final moved = results.kernel.units.first;
      expect((moved.col, moved.row), (2, 0));
      expect(
        (moved.queuedPath?.targetCol, moved.queuedPath?.targetRow),
        (4, 0),
      );
      expect(stepCoordinates(moved.queuedPath!.steps), const [
        (0, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (4, 0),
      ]);
      expect(stepCoordinates(results.kernel.execution!.steps), const [
        (1, 0),
        (2, 0),
      ]);
    });

    _registerMovementCommandResolverAdapterParityEdgeCases();
  });
}
