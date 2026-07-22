import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('local movement animation characterization', () {
    test(
      'emits the exact immediate path once and preserves unrelated unit',
      () {
        final mover = _mover(movementPoints: 5);
        final sentinel = _sentinel(col: 5);
        final state = _state(
          mover,
          additionalUnits: [sentinel],
          fogOfWar: _visibleFog(cols: 6),
        );
        final beforeUnits = state.units;

        final result = MovementReducer.moveUnit(
          state,
          MoveUnitCommand(mover.id, 3, 0),
          _map(cols: 6),
        );

        final moved = result.state.units.first;
        expect(result.uiEffects, hasLength(1));
        expect(result.uiEffects.single, isA<AnimateUnitMoveEffect>());
        final animation = result.uiEffects.single as AnimateUnitMoveEffect;
        expect(result.events, hasLength(1));
        expect(result.events.single, isA<UnitMovedEvent>());
        final event = result.events.single as UnitMovedEvent;
        expect(_stepSnapshots(animation.steps), const [
          (col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          (col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          (col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
        ]);
        expect(
          (animation.unitId, animation.fromCol, animation.fromRow),
          (mover.id, 0, 0),
        );
        expect(
          (
            event.unitId,
            event.fromCol,
            event.fromRow,
            event.toCol,
            event.toRow,
          ),
          (mover.id, 0, 0, 3, 0),
        );
        expect((moved.col, moved.row, moved.movementPoints), (3, 0, 2));
        expect(
          (animation.steps.last.col, animation.steps.last.row),
          (event.toCol, event.toRow),
        );
        expect(result.state.units, isNot(same(beforeUnits)));
        expect(result.state.units.last, same(sentinel));
        expect(result.state.selection?.unit, same(moved));
      },
    );

    test('animates only the executed prefix and queues the full path', () {
      final mover = _mover(movementPoints: 2);
      final state = _state(mover, fogOfWar: _visibleFog(cols: 5));

      final result = MovementReducer.moveUnit(
        state,
        MoveUnitCommand(mover.id, 4, 0),
        _map(cols: 5),
      );

      final moved = result.state.units.single;
      expect(result.uiEffects, hasLength(1));
      expect(result.uiEffects.single, isA<AnimateUnitMoveEffect>());
      final animation = result.uiEffects.single as AnimateUnitMoveEffect;
      expect(result.events, hasLength(1));
      expect(result.events.single, isA<UnitMovedEvent>());
      final event = result.events.single as UnitMovedEvent;
      expect(_stepSnapshots(animation.steps), const [
        (col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        (col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
      ]);
      expect(_stepSnapshots(moved.queuedPath!.steps), const [
        (col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        (col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        (col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        (col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
        (col: 4, row: 0, enterCost: 1, cumulativeCost: 4),
      ]);
      expect((moved.col, moved.row, moved.movementPoints), (2, 0, 0));
      expect(
        (animation.unitId, animation.fromCol, animation.fromRow),
        (mover.id, 0, 0),
      );
      expect(
        (event.unitId, event.fromCol, event.fromRow, event.toCol, event.toRow),
        (mover.id, 0, 0, 2, 0),
      );
      expect(animation.steps.last.coord, (col: event.toCol, row: event.toRow));
      expect(
        () => moved.queuedPath!.steps.add(
          const UnitMovementStep(
            col: 9,
            row: 9,
            enterCost: 1,
            cumulativeCost: 9,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('zero movement queues without an event or animation', () {
      final mover = _mover(movementPoints: 0);
      final preview = UnitMovementPlan(
        unitId: mover.id,
        targetCol: 3,
        targetRow: 0,
        totalCost: 3,
        availableMovementPoints: 0,
        steps: _lineSteps(3),
      );
      const pending = PendingResearchSelection(ownerPlayerId: 'player_1');
      final draft = CityFoundingDraft(
        unitId: 'sentinel_founder',
        ownerPlayerId: 'player_1',
        center: const CityHex(col: 5, row: 0),
      );
      final state = _state(
        mover,
        interaction: GameInteractionState(
          selection: GameSelection.unit(mover),
          movePreview: preview,
          cityFoundingDraft: draft,
          pendingAction: pending,
          moveCommandActive: true,
        ),
      );

      final result = MovementReducer.moveUnit(
        state,
        MoveUnitCommand(mover.id, 3, 0),
        _map(cols: 6),
      );

      final queued = result.state.units.single;
      expect((queued.col, queued.row, queued.movementPoints), (0, 0, 0));
      expect(
        _stepSnapshots(queued.queuedPath!.steps),
        _stepSnapshots(_lineSteps(3)),
      );
      expect(result.events, isEmpty);
      expect(result.uiEffects, isEmpty);
      expect(result.state.movePreview, isNull);
      expect(result.state.moveCommandActive, isTrue);
      expect(result.state.pendingAction, same(pending));
      expect(result.state.cityFoundingDraft, same(draft));
      expect(result.state.selection?.unit, same(queued));
    });
  });

  group('local and persistent movement drift characterization', () {
    test('fortified zero-MP unit is local reject but persistent queue', () {
      final mover = _mover(movementPoints: 0, posture: UnitPosture.fortified);
      final pair = _runBoth(
        _state(mover),
        MoveUnitCommand(mover.id, 1, 0),
        _map(cols: 3),
      );

      expect(pair.local.state, same(pair.localInput));
      expect(pair.local.events, isEmpty);
      expect(pair.persistent.accepted, isTrue);
      expect(pair.persistent.reason, isNull);
      expect(pair.persistent.state.units.single.posture, UnitPosture.active);
      expect(pair.persistent.state.units.single.queuedPath?.targetCol, 1);
    });

    test('invalid origin is local move but persistent unit_out_of_bounds', () {
      final mover = _mover(col: -1, movementPoints: 5);
      final pair = _runBoth(
        _state(mover),
        MoveUnitCommand(mover.id, 0, 0),
        _map(cols: 3),
      );

      expect(
        (pair.local.state.units.single.col, pair.local.state.units.single.row),
        (0, 0),
      );
      expect(pair.local.events, hasLength(1));
      expect(pair.persistent.accepted, isFalse);
      expect(pair.persistent.reason, 'unit_out_of_bounds');
      expect(pair.persistent.state, same(pair.persistentInput));
    });

    test('hidden target at distance three moves in both reducers', () {
      final mover = _mover(movementPoints: 5);
      final state = _state(mover, fogOfWar: _originOnlyFog());
      final pair = _runBoth(
        state,
        MoveUnitCommand(mover.id, 3, 0),
        _map(cols: 4),
      );

      final localMover = pair.local.state.units.single;
      expect(
        (localMover.col, localMover.row, localMover.movementPoints),
        (3, 0, 2),
      );
      expect(pair.local.uiEffects, hasLength(1));
      final animation = pair.local.uiEffects.single as AnimateUnitMoveEffect;
      expect(
        (animation.unitId, animation.fromCol, animation.fromRow),
        (mover.id, 0, 0),
      );
      expect(_stepSnapshots(animation.steps), const [
        (col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        (col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        (col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
      ]);
      expect(pair.local.events, hasLength(1));
      expect(pair.local.events.single, isA<UnitMovedEvent>());
      final localEvent = pair.local.events.single as UnitMovedEvent;
      expect(
        (
          localEvent.unitId,
          localEvent.fromCol,
          localEvent.fromRow,
          localEvent.toCol,
          localEvent.toRow,
        ),
        (mover.id, 0, 0, 3, 0),
      );
      expect(pair.persistent.accepted, isTrue);
      expect(pair.persistent.reason, isNull);
      expect(
        (
          pair.persistent.state.units.first.col,
          pair.persistent.state.units.first.row,
          pair.persistent.state.units.first.movementPoints,
        ),
        (3, 0, 2),
      );
      expect(pair.persistent.events, hasLength(1));
      final persistentEvent = pair.persistent.events.single as UnitMovedEvent;
      expect(
        (
          persistentEvent.unitId,
          persistentEvent.fromCol,
          persistentEvent.fromRow,
          persistentEvent.toCol,
          persistentEvent.toRow,
        ),
        (mover.id, 0, 0, 3, 0),
      );
    });

    test('far hidden target is local no-op but persistent move', () {
      final mover = _mover(movementPoints: 5);
      final state = _state(mover, fogOfWar: _originOnlyFog());
      final pair = _runBoth(
        state,
        MoveUnitCommand(mover.id, 4, 0),
        _map(cols: 5),
      );

      expect(pair.local.state, same(pair.localInput));
      expect(pair.local.events, isEmpty);
      expect(pair.local.uiEffects, isEmpty);
      expect(pair.persistent.accepted, isTrue);
      expect(
        (
          pair.persistent.state.units.first.col,
          pair.persistent.state.units.first.row,
        ),
        (4, 0),
      );
      expect(pair.persistent.events, hasLength(1));
    });

    test(
      'missing fog entry hides local blocker but not persistent blocker',
      () {
        final mover = _mover(movementPoints: 5);
        final blocker = _enemy(col: 1);
        final state = _state(mover, additionalUnits: [blocker]);
        final pair = _runBoth(
          state,
          MoveUnitCommand(mover.id, 1, 0),
          _map(cols: 2),
        );

        expect(pair.local.state, same(pair.localInput));
        expect(pair.local.events, isEmpty);
        expect(pair.local.uiEffects, isEmpty);
        expect(pair.persistent.accepted, isFalse);
        expect(pair.persistent.reason, 'move_target_occupied');
        expect(pair.persistent.state, same(pair.persistentInput));
      },
    );
  });
}

typedef _StepSnapshot = ({int col, int row, int enterCost, int cumulativeCost});

List<_StepSnapshot> _stepSnapshots(Iterable<UnitMovementStep> steps) => [
  for (final step in steps)
    (
      col: step.col,
      row: step.row,
      enterCost: step.enterCost,
      cumulativeCost: step.cumulativeCost,
    ),
];

List<UnitMovementStep> _lineSteps(int targetCol) => [
  for (var col = 0; col <= targetCol; col++)
    UnitMovementStep(
      col: col,
      row: 0,
      enterCost: col == 0 ? 0 : 1,
      cumulativeCost: col,
    ),
];

GameUnit _mover({
  int col = 0,
  int movementPoints = 5,
  UnitPosture posture = UnitPosture.active,
}) => GameUnit(
  id: 'mover',
  ownerPlayerId: 'player_1',
  type: GameUnitType.commander,
  name: 'Mover',
  col: col,
  row: 0,
  movementPoints: movementPoints,
  posture: posture,
);

GameUnit _sentinel({required int col}) => GameUnit(
  id: 'sentinel',
  ownerPlayerId: 'player_1',
  type: GameUnitType.warrior,
  name: 'Sentinel',
  col: col,
  row: 0,
);

GameUnit _enemy({required int col}) => GameUnit(
  id: 'enemy',
  ownerPlayerId: 'player_2',
  type: GameUnitType.warrior,
  name: 'Enemy',
  col: col,
  row: 0,
);

GameState _state(
  GameUnit mover, {
  List<GameUnit> additionalUnits = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  GameInteractionState? interaction,
}) => GameState(
  playerColors: const {'player_1': 0xff112233, 'player_2': 0xff445566},
  activePlayerId: 'player_1',
  units: [mover, ...additionalUnits],
  fogOfWar: fogOfWar,
  interaction:
      interaction ?? GameInteractionState(selection: GameSelection.unit(mover)),
);

FogOfWarState _originOnlyFog() => FogOfWarState(
  players: {
    'player_1': PlayerFogOfWar(
      playerId: 'player_1',
      discoveredHexes: {const HexCoordinate(col: 0, row: 0)},
      visibleHexes: {const HexCoordinate(col: 0, row: 0)},
    ),
  },
);

FogOfWarState _visibleFog({required int cols}) {
  final hexes = {
    for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: 0),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: hexes,
        visibleHexes: hexes,
      ),
    },
  );
}

MapTraversalView _map({required int cols}) => WorldMapReadView(
  WorldMap(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col++)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  ),
);

_MovementPair _runBoth(
  GameState state,
  MoveUnitCommand command,
  MapTraversalView map,
) {
  final persistentInput = state.toPersistentState();
  return _MovementPair(
    localInput: state,
    persistentInput: persistentInput,
    local: MovementReducer.moveUnit(state, command, map),
    persistent: const PersistentMoveUnitResolver().resolve(
      state: persistentInput,
      command: command,
      actorPlayerId: 'player_1',
      mapData: map,
    ),
  );
}

final class _MovementPair {
  const _MovementPair({
    required this.localInput,
    required this.persistentInput,
    required this.local,
    required this.persistent,
  });

  final GameState localInput;
  final PersistentGameState persistentInput;
  final GameStateTransition local;
  final PersistentMoveUnitResult persistent;
}
