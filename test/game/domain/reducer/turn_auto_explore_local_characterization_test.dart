import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('local turn auto-explore continuation characterization', () {
    test('animates a queued prefix before the next automatic plan', () {
      final scout = _autoExploringScout(movementPoints: 0).copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 1,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
          ],
        ),
      );
      final guardedBeforeQueue = _resolveCoreContinuation(
        scout: scout.copyWith(movementPoints: _fullScoutMovement),
        fogOfWar: _originOnlyFog(),
        mapData: _map(cols: 6),
      );

      final result = _reset(
        units: [scout],
        fogOfWar: _originOnlyFog(),
        mapData: _map(cols: 6),
      );
      final moved = result.state.units.single;
      final effects = result.uiEffects
          .whereType<AnimateUnitMoveEffect>()
          .toList();

      expect(guardedBeforeQueue.accepted, isFalse);
      expect(guardedBeforeQueue.reason, 'unit_has_path');
      expect(
        (
          col: moved.col,
          row: moved.row,
          movementPoints: moved.movementPoints,
          queuedTargetCol: moved.queuedPath?.targetCol,
          queuedTargetRow: moved.queuedPath?.targetRow,
          posture: moved.posture,
        ),
        (
          col: 3,
          row: 0,
          movementPoints: 0,
          queuedTargetCol: 4,
          queuedTargetRow: 0,
          posture: UnitPosture.autoExploring,
        ),
      );
      expect(effects.map(_effectSnapshot), [
        'turn_auto_scout:0,0->1,0;steps=1,0:2/2',
        'turn_auto_scout:1,0->3,0;steps=2,0:2/2|3,0:2/4',
      ]);
      expect(moved.queuedPath!.steps.map(_stepSnapshot), const [
        '1,0:0/0',
        '2,0:2/2',
        '3,0:2/4',
        '4,0:2/6',
      ]);
      expect(result.events, hasLength(1));
      expect(
        result.events.single,
        isA<UnitMovedEvent>()
            .having((event) => event.unitId, 'unitId', 'turn_auto_scout')
            .having((event) => event.fromCol, 'fromCol', 1)
            .having((event) => event.fromRow, 'fromRow', 0)
            .having((event) => event.toCol, 'toCol', 3)
            .having((event) => event.toRow, 'toRow', 0),
      );
    });

    test('clears only interaction owned by the continued scout', () {
      final scout = _autoExploringScout(movementPoints: 0);
      final unrelatedDraft = CityFoundingDraft(
        unitId: 'other_unit',
        ownerPlayerId: _playerId,
        center: const CityHex(col: 7, row: 7),
      );

      final result = _reset(
        units: [scout],
        fogOfWar: _originOnlyFog(),
        mapData: _map(cols: 3),
        interaction: InteractionState(
          cityFoundingDraft: unrelatedDraft,
          pendingAction: const PendingUnitTurnSkip(
            ownerPlayerId: _playerId,
            unitId: 'turn_auto_scout',
            restoreMovementPoints: 2,
          ),
        ),
      );

      expect(result.state.pendingAction, isNull);
      expect(result.state.cityFoundingDraft, unrelatedDraft);
      expect(result.uiEffects.whereType<AnimateUnitMoveEffect>(), isEmpty);
      expect(result.events, isEmpty);
    });

    test(
      'passes queued-movement contact discovery into continuation and final diplomacy',
      () {
        final scout = _autoExploringScout(movementPoints: 0).copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 1,
            targetRow: 0,
            steps: const [
              UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
              UnitMovementStep(col: 1, row: 0, enterCost: 2, cumulativeCost: 2),
            ],
          ),
        );
        final opponent = GameUnit(
          id: 'contact_unit',
          ownerPlayerId: _opponentId,
          type: GameUnitType.warrior,
          name: 'Contact unit',
          col: 3,
          row: 0,
        );

        final result = _reset(
          units: [scout, opponent],
          fogOfWar: _originOnlyFog(),
          mapData: _map(cols: 4),
        );

        expect(
          _unitSnapshot(result.state.units.first),
          'turn_auto_scout:1,0;mp=2;target=-;steps=-',
        );
        expect(result.state.units.first.posture, UnitPosture.active);
        expect(
          result.uiEffects.whereType<AnimateUnitMoveEffect>().map(
            _effectSnapshot,
          ),
          ['turn_auto_scout:0,0->1,0;steps=1,0:2/2'],
        );
        expect(result.events, isEmpty);
        expect(result.state.diplomacy.contactKeys, {'player_1|player_2'});
        expect(
          result.state.diplomacy.hasContact(_playerId, _opponentId),
          isTrue,
        );
      },
    );

    test('plans in order with reserved route exclusions', () {
      final first = _autoExploringScout(
        id: 'first_scout',
        row: 0,
        movementPoints: 0,
      );
      final second = _autoExploringScout(
        id: 'second_scout',
        row: 1,
        movementPoints: 0,
      );
      final known = {
        for (var col = 0; col <= 3; col++)
          for (var row = 0; row <= 1; row++) HexCoordinate(col: col, row: row),
      };

      final result = _reset(
        units: [first, second],
        fogOfWar: _fog(discovered: known, visible: known),
        mapData: _map(cols: 10, rows: 2),
      );

      expect(result.state.units.map(_unitSnapshot), [
        'first_scout:3,0;mp=0;target=6,0;'
            'steps=0,0|1,0|2,0|3,0|4,0|5,0|6,0',
        'second_scout:3,1;mp=0;target=7,0;'
            'steps=0,1|1,0|2,1|3,1|4,1|5,1|6,1|7,0',
      ]);
      expect(
        result.uiEffects.whereType<AnimateUnitMoveEffect>().map(
          _effectSnapshot,
        ),
        [
          'first_scout:0,0->3,0;steps=1,0:2/2|2,0:2/4|3,0:2/6',
          'second_scout:0,1->3,1;steps=1,0:2/2|2,1:2/4|3,1:2/6',
        ],
      );
      expect(
        _sortedHexes(
          result.state.fogOfWar.fogForPlayer(_playerId).discoveredHexes,
        ),
        const [
          '0,0',
          '0,1',
          '1,0',
          '1,1',
          '2,0',
          '2,1',
          '3,0',
          '3,1',
          '4,0',
          '4,1',
          '5,0',
          '5,1',
        ],
      );
      final firstFutureRoute = result.state.units.first.queuedPath!.steps
          .where((step) => step.col > result.state.units.first.col)
          .map((step) => '${step.col},${step.row}')
          .toSet();
      final secondFutureRoute = result.state.units.last.queuedPath!.steps
          .where((step) => step.col > result.state.units.last.col)
          .map((step) => '${step.col},${step.row}')
          .toSet();
      expect(firstFutureRoute.intersection(secondFutureRoute), isEmpty);
      expect(result.events, hasLength(2));
      expect(
        result.events.whereType<UnitMovedEvent>().map(
          (event) => (
            event.unitId,
            event.fromCol,
            event.fromRow,
            event.toCol,
            event.toRow,
          ),
        ),
        const [('first_scout', 0, 0, 3, 0), ('second_scout', 0, 1, 3, 1)],
      );
    });

    test('no target finishes local and core continuation posture', () {
      final input = _autoExploringScout(movementPoints: _fullScoutMovement);
      final fog = _originOnlyFog();
      final map = _map(cols: 1);

      final local = _reset(units: [input], fogOfWar: fog, mapData: map);
      final localScout = local.state.units.single;
      final core = _resolveCoreContinuation(
        scout: input,
        fogOfWar: fog,
        mapData: map,
      );

      expect(localScout.posture, UnitPosture.active);
      expect(local.uiEffects, isEmpty);
      expect(local.events, isEmpty);
      expect(core.accepted, isTrue);
      expect(core.units.single.posture, UnitPosture.active);
      expect(core.execution, isNull);
      expect(core.events, isEmpty);
    });

    test('hidden unit closes the same local and core no-op', () {
      final scout = _autoExploringScout(movementPoints: _fullScoutMovement);
      final blocker = GameUnit(
        id: 'hidden_blocker',
        ownerPlayerId: _opponentId,
        type: GameUnitType.warrior,
        name: 'Hidden blocker',
        col: 1,
        row: 0,
      );
      final fog = _originOnlyFog();
      final map = _map(cols: 2);

      final local = _reset(
        units: [scout, blocker],
        fogOfWar: fog,
        mapData: map,
      );
      final localScout = local.state.units.first;
      final core = _resolveCoreContinuation(
        scout: scout,
        additionalUnits: [blocker],
        fogOfWar: fog,
        mapData: map,
      );

      expect((localScout.col, localScout.row), (0, 0));
      expect(localScout.posture, UnitPosture.active);
      expect(local.uiEffects, isEmpty);
      expect(core.accepted, isTrue);
      expect((core.units.first.col, core.units.first.row), (0, 0));
      expect(core.units.first.posture, UnitPosture.active);
      expect(core.execution, isNull);
      expect(core.events, isEmpty);
    });

    test('hidden city closes the same local and core no-op', () {
      final scout = _autoExploringScout(movementPoints: _fullScoutMovement);
      const city = GameCity(
        id: 'hidden_city',
        ownerPlayerId: _opponentId,
        name: 'Hidden city',
        center: CityHex(col: 1, row: 0),
      );
      final fog = _originOnlyFog();
      final map = _map(cols: 2);

      final local = _reset(
        units: [scout],
        cities: const [city],
        fogOfWar: fog,
        mapData: map,
      );
      final localScout = local.state.units.single;
      final core = _resolveCoreContinuation(
        scout: scout,
        cities: const [city],
        fogOfWar: fog,
        mapData: map,
      );

      expect((localScout.col, localScout.row), (0, 0));
      expect(localScout.posture, UnitPosture.active);
      expect(local.uiEffects, isEmpty);
      expect(core.accepted, isTrue);
      expect((core.units.single.col, core.units.single.row), (0, 0));
      expect(core.units.single.posture, UnitPosture.active);
      expect(core.execution, isNull);
      expect(core.events, isEmpty);
    });
  });
}

const _playerId = 'player_1';
const _opponentId = 'player_2';
final _fullScoutMovement = UnitMovementBalance.maxMovementPointsForType(
  GameUnitType.scout,
);

GameUnit _autoExploringScout({
  String id = 'turn_auto_scout',
  int col = 0,
  int row = 0,
  required int movementPoints,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: GameUnitType.scout,
    name: id,
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: UnitPosture.autoExploring,
  );
}

GameStateTransition _reset({
  required List<GameUnit> units,
  required FogOfWarState fogOfWar,
  required WorldMap mapData,
  List<GameCity> cities = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
  InteractionState interaction = InteractionState.empty,
}) {
  return MovementReducer.resetUnitMovementForNewTurn(
    GameClientState(
      playerColors: const {_playerId: 0xff112233, _opponentId: 0xff445566},
      activePlayerId: _playerId,
      units: units,
      cities: cities,
      diplomacy: diplomacy,
      fogOfWar: fogOfWar,
      interaction: interaction,
    ),
    mapData,
    playerId: _playerId,
  );
}

AutoExploreCommandResult _resolveCoreContinuation({
  required GameUnit scout,
  required FogOfWarState fogOfWar,
  required WorldMap mapData,
  List<GameUnit> additionalUnits = const [],
  List<GameCity> cities = const [],
}) {
  return const AutoExploreCommandResolver().resolve(
    state: AutoExploreCommandState(
      movement: MovementCommandState(
        units: [scout, ...additionalUnits],
        cities: cities,
        fogOfWar: fogOfWar,
        diplomacy: DiplomacyState.empty,
        playerIds: const [_playerId, _opponentId],
      ),
      interaction: DomainActionState.empty,
    ),
    command: AutoExploreUnitCommand(scout.id),
    actorPlayerId: _playerId,
    mapData: mapData,
    phase: AutoExploreCommandPhase.continuation,
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
      _playerId: PlayerFogOfWar(
        playerId: _playerId,
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

WorldMap _map({required int cols, int rows = 1}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

String _effectSnapshot(AnimateUnitMoveEffect effect) {
  final destination = effect.steps.last;
  return '${effect.unitId}:${effect.fromCol},${effect.fromRow}'
      '->${destination.col},${destination.row};steps='
      '${effect.steps.map(_stepSnapshot).join('|')}';
}

String _stepSnapshot(UnitMovementStep step) {
  return '${step.col},${step.row}:${step.enterCost}/${step.cumulativeCost}';
}

String _unitSnapshot(GameUnit unit) {
  final path = unit.queuedPath;
  final target = path == null ? '-' : '${path.targetCol},${path.targetRow}';
  final steps = path == null
      ? '-'
      : path.steps.map((step) => '${step.col},${step.row}').join('|');
  return '${unit.id}:${unit.col},${unit.row};mp=${unit.movementPoints};'
      'target=$target;steps=$steps';
}

List<String> _sortedHexes(Iterable<HexCoordinate> hexes) {
  return [for (final hex in hexes) '${hex.col},${hex.row}']..sort();
}
