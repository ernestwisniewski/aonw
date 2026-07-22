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
  group('local versus persistent auto-explore rejection drift', () {
    test('known foreign city primes only the local state', () {
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

      _expectAtomicityDrift(pair, reason: 'move_target_is_foreign_city_center');
      expect(pair.local.uiEffects, isEmpty);
    });

    test('over-capacity target primes only the local state', () {
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

      _expectAtomicityDrift(
        pair,
        reason: 'unit_movement_capacity_insufficient',
      );
      expect(pair.local.uiEffects, hasLength(1));
    });

    test('invalid origin primes only the local state', () {
      final input = _state(
        _scout(col: -1),
        fogOfWar: FogOfWarState.empty,
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _runBoth(input, _map(cols: 2));

      _expectAtomicityDrift(pair, reason: 'unit_out_of_bounds');
      expect(pair.local.uiEffects, isEmpty);
    });
  });

  group('local versus persistent auto-explore interaction drift', () {
    test('both clear interaction owned by the explored scout', () {
      final input = _state(
        _scout(),
        fogOfWar: _originOnlyFog(),
        interaction: _ownedInteraction(_autoExploreUnitId),
      );
      final pair = _runBoth(input, _map(cols: 2));

      expect(pair.persistent.accepted, isTrue);
      expect(pair.local.state.pendingAction, isNull);
      expect(pair.local.state.cityFoundingDraft, isNull);
      expect(pair.persistent.state.runtimeState.pendingAction, isNull);
      expect(pair.persistent.state.runtimeState.cityFoundingDraft, isNull);
      expect(
        pair.local.state.toPersistentState().toJson(),
        pair.persistent.state.toJson(),
      );
    });

    test('local clears unrelated interaction that persistent preserves', () {
      final interaction = _ownedInteraction('other_unit');
      final input = _state(
        _scout(),
        fogOfWar: _originOnlyFog(),
        interaction: interaction,
      );
      final pair = _runBoth(input, _map(cols: 2));

      expect(pair.persistent.accepted, isTrue);
      expect(pair.local.state.pendingAction, isNull);
      expect(pair.local.state.cityFoundingDraft, isNull);
      expect(
        pair.persistent.state.runtimeState.pendingAction,
        interaction.pendingAction,
      );
      expect(
        pair.persistent.state.runtimeState.cityFoundingDraft,
        interaction.cityFoundingDraft,
      );
      expect(pair.local.state.units, pair.persistent.state.units);
      expect(pair.local.state.fogOfWar, pair.persistent.state.fogOfWar);
      expect(
        pair.local.state.diplomacy,
        pair.persistent.state.runtimeState.diplomacy,
      );
    });
  });

  test('local canAct rejects while persistent has no authorization input', () {
    final input = _state(
      _scout(),
      fogOfWar: _originOnlyFog(),
    ).copyWith(activePlayerCanAct: false);
    final persistentInput = input.toPersistentState();

    final local = MovementReducer.autoExploreUnit(
      input,
      const AutoExploreUnitCommand(_autoExploreUnitId),
      _map(cols: 2),
      context: const GameCommandContext(canAct: false),
    );
    final persistent = const PersistentUnitActionResolver().autoExploreUnit(
      state: persistentInput,
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
      actorPlayerId: _actorId,
      mapData: _map(cols: 2),
    );

    expect(local.state, same(input));
    expect(local.events, isEmpty);
    expect(local.uiEffects, isEmpty);
    expect(persistent.accepted, isTrue);
    expect(persistent.state.units.first.col, 1);
    expect(persistent.events.single, isA<UnitMovedEvent>());
  });

  test('hidden full-state blocker changes destination and exact animation', () {
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
    final persistent = const PersistentUnitActionResolver().autoExploreUnit(
      state: authoritativeInput,
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
      actorPlayerId: _actorId,
      mapData: map,
    );

    expect(persistent.accepted, isTrue);
    final localScout = local.state.units.single;
    final persistentScout = persistent.state.units.first;
    expect((localScout.col, persistentScout.col), (2, 1));
    expect(local.events.single, isA<UnitMovedEvent>());
    expect(persistent.events.single, isA<UnitMovedEvent>());
    final animation = local.uiEffects.whereType<AnimateUnitMoveEffect>().single;
    expect((animation.fromCol, animation.fromRow), (0, 0));
    expect(animation.steps.map((step) => step.coord), const [
      (col: 1, row: 0),
      (col: 2, row: 0),
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
    persistent: const PersistentUnitActionResolver().autoExploreUnit(
      state: persistentInput,
      command: const AutoExploreUnitCommand(_autoExploreUnitId),
      actorPlayerId: _actorId,
      mapData: map,
    ),
  );
}

void _expectAtomicityDrift(_AutoExplorePair pair, {required String reason}) {
  expect(pair.persistent.accepted, isFalse);
  expect(pair.persistent.reason, reason);
  expect(pair.persistent.state, same(pair.persistentInput));
  expect(pair.persistent.events, isEmpty);
  expect(pair.local.state, isNot(same(pair.localInput)));
  final localScout = pair.local.state.units.single;
  expect(localScout.posture, UnitPosture.autoExploring);
  expect(localScout.coordinate, pair.localInput.units.single.coordinate);
  expect(pair.local.state.pendingAction, isNull);
  expect(pair.local.state.cityFoundingDraft, isNull);
  expect(pair.local.events, isEmpty);
}

typedef _AutoExplorePair = ({
  GameState localInput,
  PersistentGameState persistentInput,
  GameStateTransition local,
  PersistentUnitActionResult persistent,
});
