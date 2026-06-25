import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentUnitActionResolver', () {
    test(
      'cancelUnitAction clears queued movement, worker state, and runtime action',
      () {
        final worker = GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: 'Worker',
          col: 0,
          row: 0,
          queuedPath: _queuedPath(),
          workerJob: const WorkerJob(
            targetHex: CityHex(col: 0, row: 0),
            improvementType: FieldImprovementType.farm,
            remainingTurns: 1,
            totalTurns: 2,
          ),
          workerAssignment: const WorkerAssignment(
            targetHex: CityHex(col: 0, row: 0),
          ),
        );
        final state = PersistentGameState(
          units: [worker],
          runtimeState: GameRuntimeState(
            cityFoundingDraft: CityFoundingDraft(
              unitId: 'worker_1',
              ownerPlayerId: 'player_1',
              center: const CityHex(col: 0, row: 0),
            ),
            pendingAction: const PendingWorkerActionSelection(
              ownerPlayerId: 'player_1',
              unitId: 'worker_1',
            ),
            submittedPlayerIds: const {'player_2'},
            turnStartedAt: DateTime.utc(2026, 4, 27),
          ),
        );

        final result = const PersistentUnitActionResolver().cancelUnitAction(
          state: state,
          command: const CancelUnitActionCommand('worker_1'),
          actorPlayerId: 'player_1',
        );

        final updated = result.state.units.single;
        expect(result.accepted, isTrue);
        expect(updated.queuedPath, isNull);
        expect(updated.workerJob, isNull);
        expect(updated.workerAssignment, isNull);
        expect(result.state.runtimeState.cityFoundingDraft, isNull);
        expect(result.state.runtimeState.pendingAction, isNull);
        expect(result.state.runtimeState.submittedPlayerIds, {'player_2'});
        expect(
          result.state.runtimeState.turnStartedAt,
          DateTime.utc(2026, 4, 27),
        );
      },
    );

    test('skipUnitTurn consumes movement and clears queued path', () {
      final unit = GameUnit(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        name: 'Commander',
        col: 0,
        row: 0,
        movementPoints: 3,
        queuedPath: _queuedPath(),
      );
      final state = PersistentGameState(units: [unit]);

      final result = const PersistentUnitActionResolver().skipUnitTurn(
        state: state,
        command: const SkipUnitTurnCommand('commander_1'),
        actorPlayerId: 'player_1',
      );

      final skipped = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(skipped.movementPoints, 0);
      expect(skipped.queuedPath, isNull);
      expect(
        result.state.runtimeState.pendingAction,
        isA<PendingUnitTurnSkip>(),
      );
    });

    test('cancelUnitAction restores movement after skipping turn', () {
      final unit = GameUnit(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        name: 'Commander',
        col: 0,
        row: 0,
        movementPoints: 0,
      );
      final state = PersistentGameState(
        units: [unit],
        runtimeState: const GameRuntimeState(
          pendingAction: PendingUnitTurnSkip(
            ownerPlayerId: 'player_1',
            unitId: 'commander_1',
            restoreMovementPoints: 3,
          ),
        ),
      );

      final result = const PersistentUnitActionResolver().cancelUnitAction(
        state: state,
        command: const CancelUnitActionCommand('commander_1'),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.movementPoints, 3);
      expect(result.state.runtimeState.pendingAction, isNull);
    });

    test('cancelUnitAction cancels artifact excavation back to the map', () {
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 2,
        row: 1,
        movementPoints: 0,
        excavatingArtifactId: 'artifact_1',
      );
      const artifact = WorldArtifact(
        id: 'artifact_1',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.excavation(
          unitId: 'scout_1',
          col: 2,
          row: 1,
          remainingTurns: 2,
        ),
      );
      final state = PersistentGameState(units: [unit], artifacts: [artifact]);

      final result = const PersistentUnitActionResolver().cancelUnitAction(
        state: state,
        command: const CancelUnitActionCommand('scout_1'),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.excavatingArtifactId, isNull);
      expect(result.state.artifacts.single.location.isOnMap, isTrue);
      expect(result.state.artifacts.single.location.col, 2);
      expect(result.state.artifacts.single.location.row, 1);
    });

    test('fortifyUnit stores posture and clears transient action state', () {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        movementPoints: 2,
        queuedPath: _queuedPath(),
      ).copyWithHitPoints(7);
      final state = PersistentGameState(
        units: [unit],
        runtimeState: const GameRuntimeState(
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'warrior_1',
          ),
        ),
      );

      final result = const PersistentUnitActionResolver().fortifyUnit(
        state: state,
        command: const FortifyUnitCommand('warrior_1'),
        actorPlayerId: 'player_1',
      );

      final fortified = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(fortified.movementPoints, 0);
      expect(fortified.queuedPath, isNull);
      expect(fortified.posture, UnitPosture.fortified);
      expect(result.state.runtimeState.pendingAction, isNull);
    });

    test('fortifyUnit accepts full-health units for regular fortification', () {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        movementPoints: 2,
      );
      final state = PersistentGameState(units: [unit]);

      final result = const PersistentUnitActionResolver().fortifyUnit(
        state: state,
        command: const FortifyUnitCommand('warrior_1'),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.movementPoints, 0);
      expect(result.state.units.single.posture, UnitPosture.fortified);
    });

    test('cancelUnitAction wakes fortified unit with fresh movement', () {
      final unit = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        movementPoints: 0,
        posture: UnitPosture.fortified,
      );
      final state = PersistentGameState(units: [unit]);

      final result = const PersistentUnitActionResolver().cancelUnitAction(
        state: state,
        command: const CancelUnitActionCommand('warrior_1'),
        actorPlayerId: 'player_1',
      );

      final active = result.state.units.single;
      expect(result.accepted, isTrue);
      expect(active.posture, UnitPosture.active);
      expect(
        active.movementPoints,
        UnitMovementBalance.maxMovementPointsForType(active.type),
      );
    });

    test('autoExploreUnit moves scout and keeps auto-explore posture', () {
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [scout],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
              visibleHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
            ),
          },
        ),
      );

      final result = const PersistentUnitActionResolver().autoExploreUnit(
        state: state,
        command: const AutoExploreUnitCommand('scout_1'),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 6, rows: 1),
      );
      final moved = result.state.units.single;

      expect(result.accepted, isTrue);
      expect(moved.posture, UnitPosture.autoExploring);
      expect(moved.col, greaterThan(1));
    });

    test('autoExploreUnit queues a distant fog target', () {
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 1,
      );
      final knownHexes = {
        for (var col = 0; col <= 4; col++) HexCoordinate(col: col, row: 0),
      };
      final state = PersistentGameState(
        units: [scout],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: knownHexes,
              visibleHexes: knownHexes,
            ),
          },
        ),
      );

      final result = const PersistentUnitActionResolver().autoExploreUnit(
        state: state,
        command: const AutoExploreUnitCommand('scout_1'),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(cols: 8, rows: 1),
      );
      final moved = result.state.units.single;

      expect(result.accepted, isTrue);
      expect(moved.posture, UnitPosture.autoExploring);
      expect(moved.col, 1);
      expect(moved.queuedPath, isNotNull);
      expect(moved.queuedPath!.targetCol, greaterThan(4));
    });

    test('rejects unit action for another player unit', () {
      final state = PersistentGameState(
        units: [
          GameUnit(
            id: 'commander_2',
            ownerPlayerId: 'player_2',
            type: GameUnitType.commander,
            name: 'Commander',
            col: 0,
            row: 0,
          ),
        ],
      );

      final result = const PersistentUnitActionResolver().skipUnitTurn(
        state: state,
        command: const SkipUnitTurnCommand('commander_2'),
        actorPlayerId: 'player_1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'unit_not_controlled');
      expect(result.state, state);
    });
  });
}

MapDefinition _mapDefinition({required int cols, required int rows}) {
  return MapDefinition(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const <ResourceType>[],
            height: 0,
          ),
    ],
  );
}

QueuedMovePath _queuedPath() {
  return QueuedMovePath(
    targetCol: 2,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
    ],
  );
}
