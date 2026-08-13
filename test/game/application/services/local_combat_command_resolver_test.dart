import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'accepted combat is resolved by the engine and projected losslessly',
    () {
      final attacker = _unit('attacker', 'player_1', 0);
      final defender = _unit('defender', 'player_2', 1);
      final state = GameClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [attacker, defender],
        fogOfWar: _visibleFog,
        interaction: InteractionState(
          selection: GameSelection.unit(attacker),
          moveCommandActive: true,
          movePreview: UnitMovementPlan(
            unitId: 'attacker',
            targetCol: 1,
            targetRow: 0,
            totalCost: 1,
            availableMovementUnits: 3,
            steps: [],
          ),
          cityFoundingDraft: CityFoundingDraft(
            unitId: 'attacker',
            ownerPlayerId: 'player_1',
            center: const CityHex(col: 0, row: 0),
          ),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'attacker',
            defenderCol: 1,
            defenderRow: 0,
          ),
        ),
      );
      final snapshot = GameSnapshotFactory.fromClientState(
        save: _save(),
        state: state,
        eventLogOffset: 19,
      );
      final savedAt = DateTime.utc(2026, 7, 29, 19);
      final reducer = GameStateReducer(mapData: _map);

      final result = LocalCommandResolver(reducer: reducer).resolve(
        baseSnapshot: snapshot,
        currentState: state,
        command: const AttackHexCommand('attacker', 1, 0),
        savedAt: savedAt,
        context: const GameCommandContext(
          actorPlayerId: 'player_1',
          commandTick: 13,
        ),
      );

      expect(result.events.map((event) => event.runtimeType), [
        UnitAttackedEvent,
        CombatResolvedEvent,
        UnitGainedExperienceEvent,
        UnitGainedExperienceEvent,
      ]);
      expect(result.combatAnimations, [
        isA<CombatAnimationFact>()
            .having((fact) => fact.eventIndex, 'eventIndex', 1)
            .having((fact) => fact.attackerUnitId, 'attackerUnitId', 'attacker')
            .having((fact) => fact.defenderId, 'defenderId', 'defender')
            .having((fact) => fact.attackerFromCol, 'attackerFromCol', 0)
            .having((fact) => fact.attackerToCol, 'attackerToCol', 1),
      ]);
      expect(result.state.pendingAction, isNull);
      expect(result.state.movePreview, isNull);
      expect(result.state.moveCommandActive, isFalse);
      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.selectedUnit, same(result.state.units.first));
      expect(result.snapshot.units, result.state.units);
      expect(result.snapshot.fogOfWar, result.state.fogOfWar);
      expect(result.snapshot.domain.diplomacy, result.state.diplomacy);
      expect(result.snapshot.eventLogOffset, 19);
      expect(result.snapshot.save.players, snapshot.save.players);
      expect(result.snapshot.save.savedAt, savedAt);
    },
  );

  test('treaty rejection remains presentation-only engine feedback', () {
    final attacker = _unit('attacker', 'player_1', 0);
    final defender = _unit('defender', 'player_2', 1);
    final state = GameClientState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      units: [attacker, defender],
      fogOfWar: _visibleFog,
      diplomacy: DiplomacyState.empty.setStatus(
        'player_1',
        'player_2',
        DiplomaticRelationStatus.truce,
      ),
    );
    final snapshot = GameSnapshotFactory.fromClientState(
      save: _save(),
      state: state,
    );
    final reducer = GameStateReducer(mapData: _map);

    final result = LocalCommandResolver(reducer: reducer).resolve(
      baseSnapshot: snapshot,
      currentState: state,
      command: const AttackHexCommand('attacker', 1, 0),
      savedAt: DateTime.utc(2026, 7, 29, 20),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );

    expect(result.state, same(state));
    expect(result.events, isEmpty);
    expect(result.uiEffects, [
      isA<ShowHudFeedbackEffect>().having(
        (effect) => effect.reason,
        'reason',
        HudFeedbackReason.attackProtectedByTreaty,
      ),
    ]);
  });
}

GameUnit _unit(String id, String ownerPlayerId, int col) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: id,
    col: col,
    row: 0,
  );
}

GameSave _save() => GameSave(
  id: 'save_1',
  name: 'Combat engine',
  mapName: 'combat',
  turn: 7,
  playerStates: const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
  savedAt: DateTime.utc(2026, 7, 29),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'One', colorValue: 1),
    Player(id: 'player_2', name: 'Two', colorValue: 2),
  ],
);

final _visibleHexes = {
  const HexCoordinate(col: 0, row: 0),
  const HexCoordinate(col: 1, row: 0),
};

final _visibleFog = FogOfWarState(
  players: {
    'player_1': PlayerFogOfWar(
      playerId: 'player_1',
      discoveredHexes: _visibleHexes,
      visibleHexes: _visibleHexes,
    ),
  },
);

final _map = WorldMap(
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < 3; col++)
      WorldTile(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);
