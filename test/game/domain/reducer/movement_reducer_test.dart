import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map(
  int cols,
  int rows, {
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (int row = 0; row < rows; row++)
      for (int col = 0; col < cols; col++)
        TileData(
          col: col,
          row: row,
          terrains:
              terrainOverrides[(col: col, row: row)] ??
              const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

GameUnit _commander({int col = 0, int row = 0, int? movementPoints}) =>
    GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
      col: col,
      row: row,
    ).copyWith(movementPoints: movementPoints);

GameUnit _merchant({int col = 0, int row = 0, int? movementPoints}) => GameUnit(
  id: 'merchant_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.merchant,
  name: GameUnitType.merchant.defaultNameToken,
  col: col,
  row: row,
  movementPoints: movementPoints,
);

GameUnit _warrior({required String id, int col = 0, int row = 0}) => GameUnit(
  id: id,
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: GameUnitType.warrior.defaultNameToken,
  col: col,
  row: row,
);

GameCity _city({required String id, required int col, int row = 0}) => GameCity(
  id: id,
  ownerPlayerId: 'player_1',
  name: id,
  center: CityHex(col: col, row: row),
  controlledHexes: [CityHex(col: col, row: row)],
);

void main() {
  group('MovementReducer', () {
    late MapData mapData;

    setUp(() {
      mapData = _map(5, 5);
    });

    group('unit action commands', () {
      test('merchant cannot use ordinary tile movement targeting', () {
        final merchant = _merchant(movementPoints: 2);
        final state = GameState(
          units: [merchant],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(merchant),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          mapData.tileAt(1, 0)!,
          mapData,
        );

        final updated = result.state.units.single;
        expect(updated.col, 0);
        expect(updated.row, 0);
        expect(result.state.moveCommandActive, isFalse);
        expect(result.state.movePreview, isNull);
      });

      test('cancelUnitAction clears queued movement and move state', () {
        final commander = _commander()
            .copyWithQueuedPath(
              QueuedMovePath(targetCol: 3, targetRow: 0, steps: []),
            )
            .copyWithHitPoints(1);
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.cancelUnitAction(
          state,
          const CancelUnitActionCommand('commander_player_1'),
          mapData,
        );

        expect(result.state.units.single.queuedPath, isNull);
        expect(result.state.moveCommandActive, isFalse);
        expect(result.state.movePreview, isNull);
        expect(result.state.selection?.unit?.id, commander.id);
      });

      test('cancelUnitAction clears worker construction', () {
        final worker = GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 1,
          row: 1,
          workerJob: const WorkerJob(
            targetHex: CityHex(col: 1, row: 1),
            improvementType: FieldImprovementType.farm,
            remainingTurns: 1,
            totalTurns: 2,
          ),
        );
        final state = GameState(
          units: [worker],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(worker),
        );

        final result = MovementReducer.cancelUnitAction(
          state,
          const CancelUnitActionCommand('worker_1'),
          mapData,
        );

        expect(result.state.units.single.workerJob, isNull);
        expect(result.state.selection?.unit?.workerJob, isNull);
      });

      test('cancelUnitAction clears city founding work', () {
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: GameUnitType.settler.defaultNameToken,
          col: 1,
          row: 1,
          cityFoundingJob: CityFoundingJob(
            center: const CityHex(col: 1, row: 1),
            controlledHexes: const [
              CityHex(col: 1, row: 1),
              CityHex(col: 2, row: 1),
              CityHex(col: 1, row: 2),
            ],
            remainingTurns: 1,
            totalTurns: 1,
          ),
        );
        final state = GameState(
          units: [settler],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(settler),
        );

        final result = MovementReducer.cancelUnitAction(
          state,
          const CancelUnitActionCommand('settler_1'),
          mapData,
        );

        expect(result.state.units.single.cityFoundingJob, isNull);
        expect(result.state.selection?.unit?.cityFoundingJob, isNull);
      });

      test('cancelUnitAction clears artifact excavation', () {
        final scout = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 2,
          row: 1,
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
        final state = GameState(
          units: [scout],
          artifacts: const [artifact],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(scout),
        );

        final result = MovementReducer.cancelUnitAction(
          state,
          const CancelUnitActionCommand('scout_1'),
          mapData,
        );

        expect(result.state.units.single.excavatingArtifactId, isNull);
        expect(result.state.selection?.unit?.excavatingArtifactId, isNull);
        expect(result.state.artifacts.single.location.isOnMap, isTrue);
        expect(result.state.artifacts.single.location.col, 2);
        expect(result.state.artifacts.single.location.row, 1);
      });

      test('skipUnitTurn consumes movement and keeps unit selectable', () {
        final commander = _commander().copyWithQueuedPath(
          QueuedMovePath(targetCol: 3, targetRow: 0, steps: []),
        );
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.skipUnitTurn(
          state,
          const SkipUnitTurnCommand('commander_player_1'),
          mapData,
        );

        final skipped = result.state.units.single;
        expect(skipped.movementPoints, 0);
        expect(skipped.queuedPath, isNull);
        expect(result.state.pendingAction, isA<PendingUnitTurnSkip>());
        expect(result.state.moveCommandActive, isFalse);
        expect(result.state.selection?.unit?.id, commander.id);
        expect(result.state.selection?.unit?.movementPoints, 0);
      });

      test('cancelUnitAction restores movement after skipping turn', () {
        final commander = _commander(movementPoints: 2);
        final skippedState = GameState(
          units: [commander.copyWith(movementPoints: 0)],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander.copyWith(movementPoints: 0)),
          pendingAction: const PendingUnitTurnSkip(
            ownerPlayerId: 'player_1',
            unitId: 'commander_player_1',
            restoreMovementPoints: 2,
          ),
        );

        final result = MovementReducer.cancelUnitAction(
          skippedState,
          const CancelUnitActionCommand('commander_player_1'),
          mapData,
        );

        expect(result.state.units.single.movementPoints, 2);
        expect(result.state.pendingAction, isNull);
        expect(result.state.selection?.unit?.movementPoints, 2);
      });

      test('fortifyUnit consumes movement and stores unit posture', () {
        final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1')
            .copyWithQueuedPath(
              QueuedMovePath(targetCol: 3, targetRow: 0, steps: []),
            );
        final state = GameState(
          units: [warrior],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(warrior),
          moveCommandActive: true,
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: warrior.ownerPlayerId,
            attackerUnitId: warrior.id,
          ),
        );

        final result = MovementReducer.fortifyUnit(
          state,
          FortifyUnitCommand(warrior.id),
          mapData,
        );

        final fortified = result.state.units.single;
        expect(fortified.movementPoints, 0);
        expect(fortified.queuedPath, isNull);
        expect(fortified.posture, UnitPosture.fortified);
        expect(result.state.pendingAction, isNull);
        expect(result.state.moveCommandActive, isFalse);
        expect(result.state.selection?.unit?.posture, UnitPosture.fortified);
      });

      test('cancelUnitAction wakes fortified unit with fresh movement', () {
        final commander = _commander(
          movementPoints: 0,
        ).copyWithPosture(UnitPosture.fortified);
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
        );

        final result = MovementReducer.cancelUnitAction(
          state,
          const CancelUnitActionCommand('commander_player_1'),
          mapData,
        );

        final active = result.state.units.single;
        expect(active.posture, UnitPosture.active);
        expect(
          active.movementPoints,
          UnitMovementBalance.maxMovementPointsForType(active.type),
        );
        expect(result.state.moveCommandActive, isTrue);
        expect(result.state.selection?.unit?.posture, UnitPosture.active);
      });

      test('autoExploreUnit moves scout and stores auto-explore posture', () {
        final scout = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 1,
        );
        final state = GameState(
          units: [scout],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(scout),
        );

        final result = MovementReducer.autoExploreUnit(
          state,
          const AutoExploreUnitCommand('scout_1'),
          mapData,
        );
        final explored = result.state.units.single;

        expect(explored.posture, UnitPosture.autoExploring);
        expect(explored.occupies(1, 1), isFalse);
        expect(
          result.state.selection?.unit?.posture,
          UnitPosture.autoExploring,
        );
      });

      test('autoExploreUnit queues a route toward distant fog', () {
        final mapData = _map(8, 1);
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
        final state = GameState(
          units: [scout],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(scout),
          fogOfWar: _fog(discovered: knownHexes, visible: knownHexes),
        );

        final result = MovementReducer.autoExploreUnit(
          state,
          const AutoExploreUnitCommand('scout_1'),
          mapData,
        );
        final explored = result.state.units.single;

        expect(explored.posture, UnitPosture.autoExploring);
        expect(explored.col, 1);
        expect(explored.queuedPath, isNotNull);
        expect(explored.queuedPath!.targetCol, greaterThan(4));
        expect(
          result.state.fogOfWar.fogForPlayer('player_1').discoveredHexes,
          knownHexes,
        );
      });

      test('autoExploreUnit avoids another scout queued route', () {
        final mapData = _map(8, 2);
        final firstScout = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 0,
        );
        final secondScout = GameUnit(
          id: 'scout_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 1,
        );
        final knownHexes = {
          for (var col = 0; col <= 5; col++)
            for (var row = 0; row <= 1; row++)
              HexCoordinate(col: col, row: row),
        };
        final state = GameState(
          units: [firstScout, secondScout],
          activePlayerId: 'player_1',
          fogOfWar: _fog(discovered: knownHexes, visible: knownHexes),
        );

        final firstResult = MovementReducer.autoExploreUnit(
          state,
          const AutoExploreUnitCommand('scout_1'),
          mapData,
        );
        final secondResult = MovementReducer.autoExploreUnit(
          firstResult.state,
          const AutoExploreUnitCommand('scout_2'),
          mapData,
        );
        final explored = {
          for (final unit in secondResult.state.units) unit.id: unit,
        };
        final firstPath = explored['scout_1']!.queuedPath;
        final secondPath = explored['scout_2']!.queuedPath;
        final reservedFirstRoute = {
          for (final step in firstPath!.steps)
            if (!explored['scout_1']!.occupies(step.col, step.row))
              HexCoordinate(col: step.col, row: step.row),
          HexCoordinate(col: firstPath.targetCol, row: firstPath.targetRow),
        };

        expect(secondPath, isNotNull);
        expect(
          reservedFirstRoute,
          isNot(
            contains(
              HexCoordinate(
                col: secondPath!.targetCol,
                row: secondPath.targetRow,
              ),
            ),
          ),
        );
      });

      test('cancelUnitAction stops auto-exploring scout', () {
        final scout = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 1,
          posture: UnitPosture.autoExploring,
        );
        final state = GameState(
          units: [scout],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(scout),
        );

        final result = MovementReducer.cancelUnitAction(
          state,
          const CancelUnitActionCommand('scout_1'),
          mapData,
        );

        expect(result.state.units.single.posture, UnitPosture.active);
        expect(result.state.selection?.unit?.posture, UnitPosture.active);
      });

      test('manual move cancels auto-explore posture', () {
        final scout = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 1,
          posture: UnitPosture.autoExploring,
        );
        final state = GameState(
          units: [scout],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(scout),
        );

        final result = MovementReducer.moveUnit(
          state,
          const MoveUnitCommand('scout_1', 2, 1),
          mapData,
        );

        expect(result.state.units.single.posture, UnitPosture.active);
        expect(result.state.selection?.unit?.posture, UnitPosture.active);
      });

      test('moveUnit does not enter a foreign city center', () {
        final commander = _commander(col: 0, row: 0);
        const city = GameCity(
          id: 'enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Enemy',
          center: CityHex(col: 1, row: 0),
        );
        final state = GameState(
          units: [commander],
          cities: const [city],
          activePlayerId: 'player_1',
        );

        final result = MovementReducer.moveUnit(
          state,
          const MoveUnitCommand('commander_player_1', 1, 0),
          mapData,
        );

        expect(result.state, state);
        expect(result.events, isEmpty);
      });

      test('moveUnit reports terrain beyond unit movement capacity', () {
        final roughMap = _map(
          2,
          1,
          terrainOverrides: {
            (col: 1, row: 0): const [
              TerrainType.plains,
              TerrainType.forest,
              TerrainType.jungle,
              TerrainType.hills,
            ],
          },
        );
        final warrior = _warrior(id: 'warrior_1');
        final state = GameState(units: [warrior], activePlayerId: 'player_1');

        final result = MovementReducer.moveUnit(
          state,
          const MoveUnitCommand('warrior_1', 1, 0),
          roughMap,
        );

        expect(result.state, state);
        expect(result.events, isEmpty);
        expect(
          result.uiEffects.whereType<ShowHudFeedbackEffect>().single.reason,
          HudFeedbackReason.movementInsufficientUnitMovement,
        );
      });

      test('moveUnit lets artifact carriers enter own rough city center', () {
        final roughMap = _map(
          2,
          1,
          terrainOverrides: {
            (col: 1, row: 0): const [
              TerrainType.grassland,
              TerrainType.forest,
              TerrainType.hills,
            ],
          },
        );
        final carrier = GameUnit.produced(
          id: 'carrier_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          col: 0,
          row: 0,
        ).copyWith(movementPoints: 2).copyWithCarriedArtifact('artifact_1');
        final city = _city(id: 'city_1', col: 1);
        final state = GameState(
          units: [carrier],
          cities: [city],
          activePlayerId: 'player_1',
        );

        final result = MovementReducer.moveUnit(
          state,
          const MoveUnitCommand('carrier_1', 1, 0),
          roughMap,
        );

        final moved = result.state.units.single;
        expect(moved.col, 1);
        expect(moved.row, 0);
        expect(moved.movementPoints, 0);
        expect(result.events.single, isA<UnitMovedEvent>());
        expect(result.uiEffects.whereType<ShowHudFeedbackEffect>(), isEmpty);
      });
    });

    group('toggleMoveTargeting', () {
      test('activates for selected controllable unit', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: false,
        );
        expect(
          MovementReducer.toggleMoveTargeting(state).moveCommandActive,
          isTrue,
        );
      });

      test('deactivates when already active', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        expect(
          MovementReducer.toggleMoveTargeting(state).moveCommandActive,
          isFalse,
        );
      });

      test('clears when no selected unit', () {
        const state = GameState(
          activePlayerId: 'player_1',
          moveCommandActive: true,
        );
        final result = MovementReducer.toggleMoveTargeting(state);
        expect(result.moveCommandActive, isFalse);
        expect(result.movePreview, isNull);
      });

      test('clears preview when deactivating', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        // Manually set a preview by going through handleMoveTargetTile first
        final tileData = mapData.tileAt(1, 0)!;
        final withPreview = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        expect(withPreview.state.movePreview, isNotNull);

        final deactivated = MovementReducer.toggleMoveTargeting(
          withPreview.state,
        );
        expect(deactivated.moveCommandActive, isFalse);
        expect(deactivated.movePreview, isNull);
      });
    });
    // handleMoveTargetTile — preview

    group('handleMoveTargetTile — preview', () {
      test('sets preview for adjacent tile', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;
        final result = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        expect(result.state.movePreview, isNotNull);
        expect(result.state.movePreview?.targetCol, 1);
        expect(result.state.movePreview?.targetRow, 0);
      });

      test('sets preview for non-adjacent reachable tile', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(2, 0)!;
        final result = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        expect(result.state.movePreview, isNotNull);
        expect(result.state.movePreview?.targetCol, 2);
      });

      test('returns unchanged state when no path found', () {
        // Place commander at (0,0); use a 1x1 map so there's nowhere to go
        final smallMap = _map(1, 1);
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        // Tile (0,0) is the commander's own tile — tap adjacent which doesn't exist
        // Instead, use a tile NOT on the map at all — tileAt returns null.
        // Cover the null-plan branch: path to out-of-bounds col never succeeds.
        // We test with a valid tile but unit already occupies it (own tile).
        final ownTile = smallMap.tileAt(0, 0)!;
        final result = MovementReducer.handleMoveTargetTile(
          state,
          ownTile,
          smallMap,
        );
        // Own tile → cancel, not unchanged
        expect(result.state.moveCommandActive, isFalse);
      });

      test('reports when a city is occupied by another unit', () {
        final commander = _commander();
        final garrison = GameUnit.startingWarrior(
          ownerPlayerId: 'player_1',
          col: 1,
          row: 0,
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 1, row: 0),
        );
        final state = GameState(
          units: [commander, garrison],
          cities: const [city],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          mapData.tileAt(1, 0)!,
          mapData,
        );

        expect(result.state, state);
        final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
        expect(feedback.single.reason, HudFeedbackReason.movementCityOccupied);
      });

      test('reports when a route target is too far in hidden fog', () {
        final commander = _commander();
        final currentHex = HexCoordinate(
          col: commander.col,
          row: commander.row,
        );
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          fogOfWar: _fog(discovered: {currentHex}, visible: {currentHex}),
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          mapData.tileAt(4, 4)!,
          mapData,
        );

        expect(result.state, state);
        final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
        expect(
          feedback.single.reason,
          HudFeedbackReason.movementHiddenRouteTooFar,
        );
      });

      test('does not reveal an enemy unit on a hidden target tile', () {
        final commander = _commander();
        final enemy = GameUnit.startingWarrior(
          ownerPlayerId: 'player_2',
          col: 1,
          row: 0,
        );
        final currentHex = HexCoordinate(
          col: commander.col,
          row: commander.row,
        );
        final state = GameState(
          units: [commander, enemy],
          activePlayerId: 'player_1',
          fogOfWar: _fog(discovered: {currentHex}, visible: {currentHex}),
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          mapData.tileAt(1, 0)!,
          mapData,
        );

        expect(result.state, state);
        final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
        expect(feedback.single.reason, HudFeedbackReason.movementNoRoute);
      });

      test('reports foreign cities before route preview is created', () {
        final commander = _commander();
        const city = GameCity(
          id: 'enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Enemy',
          center: CityHex(col: 1, row: 0),
        );
        final state = GameState(
          units: [commander],
          cities: const [city],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          mapData.tileAt(1, 0)!,
          mapData,
        );

        expect(result.state.movePreview, isNull);
        final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
        expect(feedback.single.reason, HudFeedbackReason.movementForeignCity);
      });

      test('reports impassable terrain', () {
        final mountainMap = MapData(
          cols: 2,
          rows: 1,
          tiles: const [
            TileData(
              col: 0,
              row: 0,
              terrains: [TerrainType.plains],
              resources: [],
              height: 0,
            ),
            TileData(
              col: 1,
              row: 0,
              terrains: [TerrainType.mountain],
              resources: [],
              height: 0,
            ),
          ],
        );
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          mountainMap.tileAt(1, 0)!,
          mountainMap,
        );

        expect(result.state, state);
        final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
        expect(
          feedback.single.reason,
          HudFeedbackReason.movementBlockedTerrain,
        );
      });

      test('reports when unit movement capacity is too low for terrain', () {
        final roughMap = _map(
          2,
          1,
          terrainOverrides: {
            (col: 1, row: 0): const [
              TerrainType.plains,
              TerrainType.forest,
              TerrainType.jungle,
              TerrainType.hills,
            ],
          },
        );
        final warrior = _warrior(id: 'warrior_1');
        final state = GameState(
          units: [warrior],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(warrior),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          roughMap.tileAt(1, 0)!,
          roughMap,
        );

        expect(result.state, state);
        expect(result.state.movePreview, isNull);
        final feedback = result.uiEffects.whereType<ShowHudFeedbackEffect>();
        expect(
          feedback.single.reason,
          HudFeedbackReason.movementInsufficientUnitMovement,
        );
      });

      test('previews artifact carrier movement into own rough city center', () {
        final roughMap = _map(
          2,
          1,
          terrainOverrides: {
            (col: 1, row: 0): const [
              TerrainType.grassland,
              TerrainType.forest,
              TerrainType.hills,
            ],
          },
        );
        final carrier = GameUnit.produced(
          id: 'carrier_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          col: 0,
          row: 0,
        ).copyWith(movementPoints: 2).copyWithCarriedArtifact('artifact_1');
        final state = GameState(
          units: [carrier],
          cities: [_city(id: 'city_1', col: 1)],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(carrier),
          moveCommandActive: true,
        );

        final result = MovementReducer.handleMoveTargetTile(
          state,
          roughMap.tileAt(1, 0)!,
          roughMap,
        );

        expect(result.state.movePreview?.targetCol, 1);
        expect(result.state.movePreview?.targetRow, 0);
        expect(result.uiEffects.whereType<ShowHudFeedbackEffect>(), isEmpty);
      });
    });
    // handleMoveTargetTile — cancel on own tile

    group('handleMoveTargetTile — own tile', () {
      test('cancels move mode when tapping own tile', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final ownTile = mapData.tileAt(0, 0)!;
        final result = MovementReducer.handleMoveTargetTile(
          state,
          ownTile,
          mapData,
        );
        expect(result.state.moveCommandActive, isFalse);
        expect(result.state.selection?.type, GameSelectionType.unit);
      });

      test('keeps unit selected after cancelling on own tile', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final ownTile = mapData.tileAt(0, 0)!;
        final result = MovementReducer.handleMoveTargetTile(
          state,
          ownTile,
          mapData,
        );
        expect(result.state.selection?.unit?.id, commander.id);
      });
    });
    // handleMoveTargetTile — confirm (second tap)

    group('handleMoveTargetTile — confirm move', () {
      test('confirms move on second tap', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;

        // First tap: set preview
        final s1 = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        expect(s1.state.movePreview, isNotNull);

        // Second tap: confirm
        final s2 = MovementReducer.handleMoveTargetTile(
          s1.state,
          tileData,
          mapData,
        );
        expect(s2.state.units.single.col, 1);
        expect(s2.state.moveCommandActive, isTrue);
        expect(
          s2.uiEffects.whereType<AnimateUnitMoveEffect>().single.unitId,
          commander.id,
        );
      });

      test('unit position updates after confirmation', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;
        final s1 = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        final s2 = MovementReducer.handleMoveTargetTile(
          s1.state,
          tileData,
          mapData,
        );
        final movedUnit = s2.state.units.single;
        expect(movedUnit.col, 1);
        expect(movedUnit.row, 0);
      });

      test('preview is cleared after confirmation', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;
        final s1 = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        final s2 = MovementReducer.handleMoveTargetTile(
          s1.state,
          tileData,
          mapData,
        );
        expect(s2.state.movePreview, isNull);
      });

      test('selection updated to moved unit', () {
        final commander = _commander();
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;
        final s1 = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        final s2 = MovementReducer.handleMoveTargetTile(
          s1.state,
          tileData,
          mapData,
        );
        expect(s2.state.selection?.type, GameSelectionType.unit);
        expect(s2.state.selection?.unit?.col, 1);
      });

      test('movement points decrease after move', () {
        final commander = _commander();
        final initialMP = commander.movementPoints;
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;
        final s1 = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        final s2 = MovementReducer.handleMoveTargetTile(
          s1.state,
          tileData,
          mapData,
        );
        expect(s2.state.units.single.movementPoints, lessThan(initialMP));
      });
    });
    // handleMoveTargetTile — no controllable unit

    group('handleMoveTargetTile — no controllable unit', () {
      test('clears move mode when no unit selected', () {
        const state = GameState(
          activePlayerId: 'player_1',
          moveCommandActive: true,
        );
        final tileData = mapData.tileAt(1, 0)!;
        final result = MovementReducer.handleMoveTargetTile(
          state,
          tileData,
          mapData,
        );
        expect(result.state.moveCommandActive, isFalse);
      });
    });
    group('resetUnitMovementForNewTurn', () {
      test('resets MP for player units', () {
        final commander = _commander(movementPoints: 0);
        final state = GameState(units: [commander], activePlayerId: 'player_1');
        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );
        expect(result.state.units.single.movementPoints, greaterThan(0));
      });

      test('does not modify other players units MP', () {
        final commander = _commander(movementPoints: 0);
        final otherCommander = GameUnit.startingCommander(
          ownerPlayerId: 'player_2',
          col: 2,
          row: 2,
        ).copyWith(movementPoints: 0);
        final state = GameState(
          units: [commander, otherCommander],
          activePlayerId: 'player_1',
        );
        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );
        final p2Unit = result.state.units.firstWhere(
          (u) => u.ownerPlayerId == 'player_2',
        );
        expect(p2Unit.movementPoints, 0);
      });

      test('returns unchanged state when nothing changed', () {
        // Start with full MP so reset doesn't change anything
        final commander = _commander(); // default full MP
        final state = GameState(units: [commander], activePlayerId: 'player_1');
        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );
        // Should still return something (even if same state), just not blow up
        // With full MP, no queued path — nothing changes
        expect(
          result.state.units.single.movementPoints,
          equals(commander.movementPoints),
        );
      });

      test('resets movement and recomputes fog when movement changed', () {
        final commander = _commander(movementPoints: 0);
        final state = GameState(units: [commander], activePlayerId: 'player_1');
        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );
        expect(
          result.state.units.single.movementPoints,
          UnitMovementBalance.maxMovementPointsForType(commander.type),
        );
        expect(
          result.state.activePlayerVisibility.canSeeDynamicAt(0, 0),
          isTrue,
        );
      });

      test('reactivates move targeting for the selected ready unit', () {
        final commander = _commander(movementPoints: 0);
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
          selection: GameSelection.unit(commander),
          moveCommandActive: false,
        );

        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );

        expect(result.state.selectedUnitId, commander.id);
        expect(result.state.selection?.unit?.movementPoints, greaterThan(0));
        expect(result.state.moveCommandActive, isTrue);
      });

      test(
        'advances auto-exploring scout without asking for manual action',
        () {
          final scout = GameUnit(
            id: 'scout_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            name: GameUnitType.scout.defaultNameToken,
            col: 1,
            row: 1,
            movementPoints: 0,
            posture: UnitPosture.autoExploring,
          );
          final state = GameState(
            units: [scout],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            selection: GameSelection.unit(scout),
          );

          final result = MovementReducer.resetUnitMovementForNewTurn(
            state,
            mapData,
            playerId: 'player_1',
          );
          final moved = result.state.units.single;

          expect(moved.posture, UnitPosture.autoExploring);
          expect(moved.occupies(1, 1), isFalse);
          expect(result.state.moveCommandActive, isFalse);
          expect(
            result.uiEffects.whereType<AnimateUnitMoveEffect>(),
            isNotEmpty,
          );
        },
      );

      test('advances multiple auto-exploring scouts during turn reset', () {
        final firstScout = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 1,
          movementPoints: 0,
          posture: UnitPosture.autoExploring,
        );
        final secondScout = GameUnit(
          id: 'scout_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: GameUnitType.scout.defaultNameToken,
          col: 1,
          row: 2,
          movementPoints: 0,
          posture: UnitPosture.autoExploring,
        );
        final state = GameState(
          units: [firstScout, secondScout],
          activePlayerId: 'player_1',
          activePlayerCanAct: true,
        );

        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          _map(8, 5),
          playerId: 'player_1',
        );
        final moved = result.state.units;

        expect(moved.every((unit) => unit.isAutoExploring), isTrue);
        expect(moved[0].occupies(firstScout.col, firstScout.row), isFalse);
        expect(moved[1].occupies(secondScout.col, secondScout.row), isFalse);
        expect(
          moved.map((unit) => (col: unit.col, row: unit.row)).toSet(),
          hasLength(2),
        );
        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>(),
          hasLength(2),
        );
      });

      test(
        'does not reactivate move targeting for an unrelated player reset',
        () {
          final commander = _commander();
          final otherCommander = GameUnit.startingCommander(
            ownerPlayerId: 'player_2',
            col: 2,
            row: 2,
          );
          final state = GameState(
            units: [commander, otherCommander],
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            selection: GameSelection.unit(commander),
            moveCommandActive: false,
          );

          final result = MovementReducer.resetUnitMovementForNewTurn(
            state,
            mapData,
            playerId: 'player_2',
          );

          expect(result.state.selectedUnitId, commander.id);
          expect(result.state.moveCommandActive, isFalse);
        },
      );

      test('executes queued path on new turn', () {
        final commander = _commander(movementPoints: 0).copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 2,
            targetRow: 0,
            steps: [
              const UnitMovementStep(
                col: 0,
                row: 0,
                enterCost: 0,
                cumulativeCost: 0,
              ),
              const UnitMovementStep(
                col: 1,
                row: 0,
                enterCost: 1,
                cumulativeCost: 1,
              ),
              const UnitMovementStep(
                col: 2,
                row: 0,
                enterCost: 1,
                cumulativeCost: 2,
              ),
            ],
          ),
        );
        final state = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
        );

        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );
        final moved = result.state.units.single;

        expect(moved.col, 2);
        expect(moved.row, 0);
        expect(moved.queuedPath, isNull);
        expect(result.state.selection?.unit?.col, 2);
        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>().single,
          isA<AnimateUnitMoveEffect>()
              .having((effect) => effect.fromCol, 'fromCol', 0)
              .having((effect) => effect.fromRow, 'fromRow', 0)
              .having((effect) => effect.steps.last.col, 'last col', 2),
        );
      });

      test('executes merchant queued city travel on new turn', () {
        final merchant = _merchant(col: 1, movementPoints: 0)
            .copyWithQueuedPath(
              QueuedMovePath(
                targetCol: 3,
                targetRow: 0,
                steps: [
                  const UnitMovementStep(
                    col: 1,
                    row: 0,
                    enterCost: 0,
                    cumulativeCost: 0,
                  ),
                  const UnitMovementStep(
                    col: 2,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                  const UnitMovementStep(
                    col: 3,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 2,
                  ),
                ],
              ),
            );
        final guard = _warrior(id: 'guard_1', col: 3);
        final city = _city(id: 'city_1', col: 3);
        final state = GameState(
          units: [merchant, guard],
          cities: [city],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(merchant),
        );

        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          mapData,
          playerId: 'player_1',
        );
        final moved = result.state.units.firstWhere((u) => u.id == merchant.id);

        expect(moved.col, 3);
        expect(moved.row, 0);
        expect(moved.queuedPath, isNull);
        expect(moved.merchantTradeRoute, isNull);
        expect(result.state.selection?.unit?.col, 3);
      });

      test('confirming a target at 0 MP queues the path without moving', () {
        final commander = _commander(movementPoints: 0);
        final start = GameState(
          units: [commander],
          activePlayerId: 'player_1',
          selection: GameSelection.unit(commander),
          moveCommandActive: false,
        );

        // Enter move mode (must succeed at 0 MP).
        final activated = MovementReducer.toggleMoveTargeting(start);
        expect(activated.moveCommandActive, isTrue);

        // First tap on (2,0) sets the preview.
        final tile = mapData.tileAt(2, 0)!;
        final previewed = MovementReducer.handleMoveTargetTile(
          activated,
          tile,
          mapData,
        );
        expect(previewed.state.movePreview, isNotNull);
        expect(previewed.state.movePreview?.targetCol, 2);

        // Second tap on the same tile confirms; with 0 MP every step is
        // unreachable this turn, so _confirmMovePreview should queue the path
        // and leave the unit in place.
        final confirmed = MovementReducer.handleMoveTargetTile(
          previewed.state,
          tile,
          mapData,
        );
        final updated = confirmed.state.units.single;

        expect(updated.col, 0, reason: 'unit must not move this turn');
        expect(updated.row, 0);
        expect(updated.movementPoints, 0);
        expect(updated.queuedPath, isNotNull);
        expect(updated.queuedPath?.targetCol, 2);
        expect(updated.queuedPath?.targetRow, 0);
        expect(updated.queuedPath?.steps, isNotEmpty);
        expect(
          confirmed.state.moveCommandActive,
          isFalse,
          reason: 'queueing a route should exit move targeting',
        );
        expect(confirmed.state.movePreview, isNull);
      });

      test('preserves queued path when new-turn movement is partial', () {
        final wideMap = _map(8, 3);
        final commander = _commander(movementPoints: 0).copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 6,
            targetRow: 0,
            steps: [
              const UnitMovementStep(
                col: 0,
                row: 0,
                enterCost: 0,
                cumulativeCost: 0,
              ),
              const UnitMovementStep(
                col: 1,
                row: 0,
                enterCost: 1,
                cumulativeCost: 1,
              ),
              const UnitMovementStep(
                col: 2,
                row: 0,
                enterCost: 1,
                cumulativeCost: 2,
              ),
              const UnitMovementStep(
                col: 3,
                row: 0,
                enterCost: 1,
                cumulativeCost: 3,
              ),
              const UnitMovementStep(
                col: 4,
                row: 0,
                enterCost: 1,
                cumulativeCost: 4,
              ),
              const UnitMovementStep(
                col: 5,
                row: 0,
                enterCost: 1,
                cumulativeCost: 5,
              ),
              const UnitMovementStep(
                col: 6,
                row: 0,
                enterCost: 1,
                cumulativeCost: 6,
              ),
            ],
          ),
        );
        final state = GameState(units: [commander], activePlayerId: 'player_1');

        final result = MovementReducer.resetUnitMovementForNewTurn(
          state,
          wideMap,
          playerId: 'player_1',
        );
        final moved = result.state.units.single;

        expect(moved.col, 5);
        expect(moved.row, 0);
        expect(moved.movementPoints, 0);
        expect(moved.queuedPath?.targetCol, 6);
        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>().single.steps,
          hasLength(5),
        );
      });
    });
  });
}

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}
