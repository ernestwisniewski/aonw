import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/movement_engine_test_driver.dart';

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
      final pair = _resolveAutoExplore(
        input,
        _map(
          cols: 3,
          terrainOverrides: const {
            2: [TerrainType.mountain],
          },
        ),
      );

      _expectAtomicRejection(pair);
    });

    test('over-capacity target keeps the exact local state without HUD', () {
      final input = _state(
        _scout(),
        fogOfWar: _originOnlyFog(),
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _resolveAutoExplore(
        input,
        _map(
          cols: 2,
          terrainOverrides: const {
            1: [TerrainType.snow, TerrainType.forest, TerrainType.hills],
          },
        ),
      );

      _expectAtomicRejection(pair);
    });

    test('invalid origin keeps the exact local state', () {
      final input = _state(
        _scout(col: -1),
        fogOfWar: FogOfWarState.empty,
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _resolveAutoExplore(input, _map(cols: 2));

      _expectAtomicRejection(pair);
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
      final pair = _resolveAutoExplore(input, _map(cols: 2));

      expect(pair.local.state.pendingAction, isNull);
      expect(pair.local.state.cityFoundingDraft, isNull);
      expect(pair.local.state.moveCommandActive, isFalse);
      expect(pair.local.state.movePreview, isNull);
      expect(
        pair.local.state.selection?.unit,
        same(pair.local.state.units.single),
      );
    });

    test('unrelated interaction keeps exact local field identities', () {
      final interaction = _ownedInteraction('other_unit');
      final input = _state(
        _scout(),
        fogOfWar: _originOnlyFog(),
        interaction: interaction,
      );
      final pair = _resolveAutoExplore(input, _map(cols: 2));

      expect(pair.local.state.pendingAction, same(interaction.pendingAction));
      expect(
        pair.local.state.cityFoundingDraft,
        same(interaction.cityFoundingDraft),
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

      final pair = _resolveAutoExplore(input, _map(cols: 2));

      expect(pair.local.state.pendingAction, isNull);
      expect(pair.local.state.cityFoundingDraft, same(unrelatedDraft));
    });
  });

  test('local engine rejects atomically when canAct is false', () {
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
    final local = resolveMovementCommandForTest(
      input,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      _map(cols: 2),
      context: const GameCommandContext(canAct: false),
    );
    expect(local.state, same(input));
    expect(local.events, isEmpty);
    expect(local.uiEffects, isEmpty);
  });

  test('explicit actor overrides active player and rejects atomically', () {
    final input = _state(_scout(), fogOfWar: _originOnlyFog());

    final result = resolveMovementCommandForTest(
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

    final local = resolveMovementCommandForTest(
      projected,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      map,
    );
    final authoritativeInput = projected.copyWith(
      units: [projected.units.single, hiddenBlocker],
    );
    final authoritative = resolveMovementCommandForTest(
      authoritativeInput,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      map,
    );

    final localScout = local.state.units.single;
    final authoritativeScout = authoritative.state.units.first;
    expect((localScout.col, authoritativeScout.col), (2, 1));
    expect(local.events.single, isA<UnitMovedEvent>());
    expect(authoritative.events.single, isA<UnitMovedEvent>());
    final authoritativeAnimation = authoritative.uiEffects
        .whereType<AnimateUnitMoveEffect>()
        .single;
    expect(_stepSnapshots(authoritativeAnimation.steps), const [
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
    final event = authoritative.events.single as UnitMovedEvent;
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

_AutoExplorePair _resolveAutoExplore(GameState input, MapTraversalView map) {
  return (
    localInput: input,
    local: resolveMovementCommandForTest(
      input,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      map,
    ),
  );
}

void _expectAtomicRejection(_AutoExplorePair pair) {
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

typedef _AutoExplorePair = ({GameState localInput, GameStateTransition local});
