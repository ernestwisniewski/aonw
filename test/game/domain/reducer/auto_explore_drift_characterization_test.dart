import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
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
  group('local auto-explore rejection atomicity', () {
    test('known foreign city keeps the exact local state', () {
      const city = GameCity(
        id: 'foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final input = _state(
        _scout(),
        cities: const [city],
        fogOfWar: _fog(discovered: _lineHexes(2), visible: _lineHexes(2)),
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _runBoth(
        input,
        _map(
          cols: 3,
          terrainOverrides: const {
            2: [TerrainType.mountain],
          },
        ),
      );

      _expectAtomicRejection(pair, persistentReason: 'auto_explore_no_target');
    });

    test('over-capacity target keeps the exact local state without HUD', () {
      final input = _state(
        _scout(),
        fogOfWar: _originOnlyFog(),
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _runBoth(
        input,
        _map(
          cols: 2,
          terrainOverrides: const {
            1: [TerrainType.snow, TerrainType.forest, TerrainType.hills],
          },
        ),
      );

      _expectAtomicRejection(
        pair,
        persistentReason: 'unit_movement_capacity_insufficient',
      );
    });

    test('invalid origin keeps the exact local state', () {
      final input = _state(
        _scout(col: -1),
        fogOfWar: FogOfWarState.empty,
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _runBoth(input, _map(cols: 2));

      _expectAtomicRejection(pair, persistentReason: 'unit_out_of_bounds');
    });
  });

  group('local auto-explore interaction projection', () {
    test('owned interaction clears with move UI and refreshed selection', () {
      final scout = _scout();
      final interaction = _ownedInteraction(_autoExploreUnitId).copyWith(
        selection: GameSelection.unit(scout),
        movePreview: _movePreview(_autoExploreUnitId),
        moveCommandActive: true,
      );
      final input = _state(
        scout,
        fogOfWar: _originOnlyFog(),
        interaction: interaction,
      );
      final pair = _runBoth(input, _map(cols: 2));

      expect(pair.persistent.accepted, isTrue);
      expect(pair.local.state.pendingAction, isNull);
      expect(pair.local.state.cityFoundingDraft, isNull);
      expect(pair.local.state.moveCommandActive, isFalse);
      expect(pair.local.state.movePreview, isNull);
      expect(
        pair.local.state.selection?.unit,
        same(pair.local.state.units.single),
      );
      expect(pair.persistent.state.runtimeState.pendingAction, isNull);
      expect(pair.persistent.state.runtimeState.cityFoundingDraft, isNull);
      expect(
        pair.local.state.toPersistentState().toJson(),
        pair.persistent.state.toJson(),
      );
    });

    test('unrelated interaction keeps exact local field identities', () {
      final interaction = _ownedInteraction('other_unit');
      final input = _state(
        _scout(),
        fogOfWar: _originOnlyFog(),
        interaction: interaction,
      );
      final pair = _runBoth(input, _map(cols: 2));

      expect(pair.persistent.accepted, isTrue);
      expect(pair.local.state.pendingAction, same(interaction.pendingAction));
      expect(
        pair.local.state.cityFoundingDraft,
        same(interaction.cityFoundingDraft),
      );
      expect(
        pair.persistent.state.runtimeState.pendingAction,
        same(interaction.pendingAction),
      );
      expect(
        pair.persistent.state.runtimeState.cityFoundingDraft,
        same(interaction.cityFoundingDraft),
      );
      expect(
        pair.local.state.toPersistentState().toJson(),
        pair.persistent.state.toJson(),
      );
    });

    test('mixed interaction clears only the pending action owned by scout', () {
      final scout = _scout();
      final unrelatedDraft = CityFoundingDraft(
        unitId: 'other_unit',
        ownerPlayerId: _actorId,
        center: const CityHex(col: 7, row: 7),
      );
      final input = _state(
        scout,
        fogOfWar: _originOnlyFog(),
        interaction: GameInteractionState(
          selection: GameSelection.unit(scout),
          cityFoundingDraft: unrelatedDraft,
          pendingAction: const PendingUnitTurnSkip(
            ownerPlayerId: _actorId,
            unitId: _autoExploreUnitId,
            restoreMovementPoints: 2,
          ),
        ),
      );

      final pair = _runBoth(input, _map(cols: 2));

      expect(pair.local.state.pendingAction, isNull);
      expect(pair.local.state.cityFoundingDraft, same(unrelatedDraft));
      expect(pair.persistent.state.runtimeState.pendingAction, isNull);
      expect(
        pair.persistent.state.runtimeState.cityFoundingDraft,
        same(pair.persistentInput.runtimeState.cityFoundingDraft),
      );
      expect(
        pair.local.state.toPersistentState().toJson(),
        pair.persistent.state.toJson(),
      );
    });
  });

  test('local and persistent reject atomically when canAct is false', () {
    final scout = _scout();
    final input = _state(
      scout,
      fogOfWar: _originOnlyFog(),
      interaction: _ownedInteraction(_autoExploreUnitId).copyWith(
        selection: GameSelection.unit(scout),
        movePreview: _movePreview(_autoExploreUnitId),
        moveCommandActive: true,
      ),
    ).copyWith(activePlayerCanAct: false);
    final persistentInput = input.toPersistentState();

    final local = MovementReducer.autoExploreUnit(
      input,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      _map(cols: 2),
      context: const GameCommandContext(canAct: false),
    );
    final persistent = const PersistentAutoExploreCommandResolver().resolve(
      state: persistentInput,
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
      actorPlayerId: _actorId,
      mapData: _map(cols: 2),
      phase: AutoExploreCommandPhase.direct,
      canAct: false,
    );

    expect(local.state, same(input));
    expect(local.events, isEmpty);
    expect(local.uiEffects, isEmpty);
    expect(persistent.accepted, isFalse);
    expect(persistent.reason, 'unit_not_controlled');
    expect(persistent.state, same(persistentInput));
    expect(persistent.events, isEmpty);
    expect(persistent.execution, isNull);
  });

  test('explicit actor overrides active player and rejects atomically', () {
    final input = _state(_scout(), fogOfWar: _originOnlyFog());

    final result = MovementReducer.autoExploreUnit(
      input,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      _map(cols: 2),
      context: const GameCommandContext(actorPlayerId: 'player_2'),
    );

    expect(result.state, same(input));
    expect(result.events, isEmpty);
    expect(result.uiEffects, isEmpty);
  });

  test('authoritative hidden-input gap keeps exact local full animation', () {
    final projected = _state(_scout(), fogOfWar: _originOnlyFog());
    final hiddenBlocker = GameUnit(
      id: 'hidden_blocker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Hidden blocker',
      col: 2,
      row: 0,
    );
    final map = _map(cols: 5);

    final local = MovementReducer.autoExploreUnit(
      projected,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      map,
    );
    final authoritativeInput = projected.toPersistentState().copyWith(
      units: [projected.units.single, hiddenBlocker],
    );
    final persistent = const PersistentAutoExploreCommandResolver().resolve(
      state: authoritativeInput,
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
      actorPlayerId: _actorId,
      mapData: map,
      phase: AutoExploreCommandPhase.direct,
    );

    expect(persistent.accepted, isTrue);
    final localScout = local.state.units.single;
    final persistentScout = persistent.state.units.first;
    expect((localScout.col, persistentScout.col), (2, 1));
    expect(local.events.single, isA<UnitMovedEvent>());
    expect(persistent.events.single, isA<UnitMovedEvent>());
    expect(_stepSnapshots(persistent.execution!.steps), const [
      (col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    ]);
    final localEvent = local.events.single as UnitMovedEvent;
    expect(
      (
        localEvent.unitId,
        localEvent.fromCol,
        localEvent.fromRow,
        localEvent.toCol,
        localEvent.toRow,
      ),
      (_autoExploreUnitId, 0, 0, 2, 0),
    );
    expect(local.uiEffects, hasLength(1));
    final animation = local.uiEffects.whereType<AnimateUnitMoveEffect>().single;
    expect(
      (animation.unitId, animation.fromCol, animation.fromRow),
      (_autoExploreUnitId, 0, 0),
    );
    expect(_stepSnapshots(animation.steps), const [
      (col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      (col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
    ]);
    final event = persistent.events.single as UnitMovedEvent;
    expect(
      (event.unitId, event.fromCol, event.fromRow, event.toCol, event.toRow),
      (_autoExploreUnitId, 0, 0, 1, 0),
    );
  });
}

const _actorId = 'player_1';
const _autoExploreUnitId = 'auto_explore_scout';

GameUnit _scout({int col = 0}) => GameUnit(
  id: _autoExploreUnitId,
  ownerPlayerId: _actorId,
  type: GameUnitType.scout,
  name: 'Scout',
  col: col,
  row: 0,
  movementPoints: 2,
);

GameState _state(
  GameUnit scout, {
  List<GameCity> cities = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  GameInteractionState? interaction,
}) {
  return GameState(
    playerColors: const {'player_1': 0xff112233, 'player_2': 0xff445566},
    activePlayerId: _actorId,
    units: [scout],
    cities: cities,
    fogOfWar: fogOfWar,
    interaction:
        interaction ??
        GameInteractionState(selection: GameSelection.unit(scout)),
  );
}

GameInteractionState _ownedInteraction(String unitId) {
  return GameInteractionState(
    pendingAction: PendingUnitTurnSkip(
      ownerPlayerId: _actorId,
      unitId: unitId,
      restoreMovementPoints: 2,
    ),
    cityFoundingDraft: CityFoundingDraft(
      unitId: unitId,
      ownerPlayerId: _actorId,
      center: const CityHex(col: 7, row: 7),
      controlledHexes: const [CityHex(col: 8, row: 7)],
    ),
  );
}

UnitMovementPlan _movePreview(String unitId) {
  return UnitMovementPlan(
    unitId: unitId,
    targetCol: 1,
    targetRow: 0,
    totalCost: 1,
    availableMovementPoints: 2,
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    ],
  );
}

FogOfWarState _originOnlyFog() => _fog(
  discovered: {const HexCoordinate(col: 0, row: 0)},
  visible: {const HexCoordinate(col: 0, row: 0)},
);

FogOfWarState _fog({
  required Set<HexCoordinate> discovered,
  required Set<HexCoordinate> visible,
}) {
  return FogOfWarState(
    players: {
      _actorId: PlayerFogOfWar(
        playerId: _actorId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

Set<HexCoordinate> _lineHexes(int count) => {
  for (var col = 0; col < count; col++) HexCoordinate(col: col, row: 0),
};

MapTraversalView _map({
  required int cols,
  Map<int, List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMapReadView(
    WorldMap(
      cols: cols,
      rows: 1,
      tiles: [
        for (var col = 0; col < cols; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: 0),
            terrains: terrainOverrides[col] ?? const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
      ],
    ),
  );
}

_AutoExplorePair _runBoth(GameState input, MapTraversalView map) {
  final persistentInput = input.toPersistentState();
  return (
    localInput: input,
    persistentInput: persistentInput,
    local: MovementReducer.autoExploreUnit(
      input,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      map,
    ),
    persistent: const PersistentAutoExploreCommandResolver().resolve(
      state: persistentInput,
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
      actorPlayerId: _actorId,
      mapData: map,
      phase: AutoExploreCommandPhase.direct,
    ),
  );
}

void _expectAtomicRejection(
  _AutoExplorePair pair, {
  required String persistentReason,
}) {
  expect(pair.persistent.accepted, isFalse);
  expect(pair.persistent.reason, persistentReason);
  expect(pair.persistent.state, same(pair.persistentInput));
  expect(pair.persistent.events, isEmpty);
  expect(pair.persistent.execution, isNull);
  expect(pair.local.state, same(pair.localInput));
  expect(pair.local.events, isEmpty);
  expect(pair.local.uiEffects, isEmpty);
}

List<({int col, int row, int enterCost, int cumulativeCost})> _stepSnapshots(
  Iterable<UnitMovementStep> steps,
) => [
  for (final step in steps)
    (
      col: step.col,
      row: step.row,
      enterCost: step.enterCost,
      cumulativeCost: step.cumulativeCost,
    ),
];

typedef _AutoExplorePair = ({
  GameState localInput,
  PersistentGameState persistentInput,
  GameStateTransition local,
  PersistentAutoExploreCommandResult persistent,
});
