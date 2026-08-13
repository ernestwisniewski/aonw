import 'dart:convert';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local skip preserves presentation targeting owned by another unit', () {
    final actedUnit = GameUnit(
      id: 'acted',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 3,
    );
    final selectedUnit = GameUnit(
      id: 'selected',
      ownerPlayerId: 'player_1',
      type: GameUnitType.scout,
      name: GameUnitType.scout.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 3,
    );
    final preview = UnitMovementPlan(
      unitId: selectedUnit.id,
      targetCol: 0,
      targetRow: 0,
      totalCost: 0,
      availableMovementUnits: 3,
      steps: const [],
    );
    final selection = GameSelection.unit(selectedUnit);
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [actedUnit, selectedUnit],
      interaction: InteractionState(
        selection: selection,
        movePreview: preview,
        moveCommandActive: true,
      ),
    );
    final baseSnapshot = GameSnapshotFactory.fromClientState(
      save: _unitActionSave(),
      state: state,
    );

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData()),
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: state,
          command: SkipUnitTurnCommand(actedUnit.id),
          savedAt: DateTime.utc(2026, 7, 29, 18),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

    expect(result.state.selection, same(selection));
    expect(result.state.movePreview, same(preview));
    expect(result.state.moveCommandActive, isTrue);
    expect(result.state.units.byId(actedUnit.id)?.movementPoints, 0);
  });

  test('local fortify refreshes acted selection and clears its targeting', () {
    final actedUnit = GameUnit(
      id: 'acted',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 3,
    );
    final preview = UnitMovementPlan(
      unitId: actedUnit.id,
      targetCol: 0,
      targetRow: 0,
      totalCost: 0,
      availableMovementUnits: 3,
      steps: const [],
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [actedUnit],
      interaction: InteractionState(
        selection: GameSelection.unit(actedUnit),
        movePreview: preview,
        moveCommandActive: true,
      ),
    );
    final baseSnapshot = GameSnapshotFactory.fromClientState(
      save: _unitActionSave(),
      state: state,
    );

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData()),
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: state,
          command: FortifyUnitCommand(actedUnit.id),
          savedAt: DateTime.utc(2026, 7, 29, 18),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

    final fortified = result.state.units.single;
    expect(fortified.posture, UnitPosture.fortified);
    expect(result.state.selection?.unit, same(fortified));
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('local unit action preserves the canonical persistence envelope', () {
    final unit = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 3,
    );
    final baseSnapshot = GameSnapshotFactory.create(
      save: _unitActionSave().copyWith(
        players: const [
          Player(id: 'player_1', name: 'One', colorValue: 0xFF010203),
          Player(id: 'player_2', name: 'Two', colorValue: 0xFF020304),
          Player(id: 'player_3', name: 'Three', colorValue: 0xFF030405),
          Player(id: 'player_4', name: 'Four', colorValue: 0xFF040506),
          Player(id: 'player_5', name: 'Five', colorValue: 0xFF050607),
          Player(
            id: 'player_6',
            name: 'Six',
            colorValue: 0xFF060708,
            country: PlayerCountry.canada,
          ),
        ],
        gameMode: GameMode.multiplayer,
      ),
      units: [unit],

      submittedPlayerIds: const {'player_2'},
      timeoutStreaksByPlayerId: const {'player_3': 2},
      afkPlayerIds: const {'player_4'},
      kickedPlayerIds: const {'player_5'},

      eventLogOffset: 73,
    );
    final before = SaveSnapshotCodec.toJson(baseSnapshot);
    final savedAt = DateTime.utc(2026, 7, 29, 20);
    final mapData = _mapData();
    final ruleset = GameRuleset.standard();
    const command = SkipUnitTurnCommand('unit_1');

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: mapData, ruleset: ruleset),
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: baseSnapshot.toClientState(activePlayerId: 'player_1'),
          command: command,
          savedAt: savedAt,
          context: const GameCommandContext(
            actorPlayerId: 'player_1',
            commandTick: 3,
          ),
        );
    final serverEngine = const GameEngine().apply(
      snapshot: baseSnapshot,
      command: command,
      context: GameEngineContext(
        actorPlayerId: 'player_1',
        commandTick: 3,
        mapView: mapData,
        ruleset: ruleset,
      ),
    );
    final ai = const SimulationGameEngineAdapter().apply(
      snapshot: baseSnapshot,
      state: baseSnapshot.domain,
      command: command,
      actorPlayerId: 'player_1',
      commandTick: 3,
      mapView: mapData,
      ruleset: ruleset,
    );
    final after = SaveSnapshotCodec.toJson(result.snapshot);

    expect(
      _unreviewedUnitActionEnvelopeBytes(after),
      _unreviewedUnitActionEnvelopeBytes(before),
    );
    expect(
      (after['save'] as Map<String, dynamic>)['savedAt'],
      savedAt.toIso8601String(),
    );
    expect(result.snapshot.save.players, hasLength(6));
    expect(result.snapshot.eventLogOffset, 73);
    expect(result.snapshot.units.single.movementPoints, 0);
    expect(result.snapshot.persistedTurnStartedAt, isNull);
    expect(result.snapshot.domain.submittedPlayerIds, {'player_2'});
    expect(result.snapshot.domain.timeoutStreaksByPlayerId, {'player_3': 2});
    expect(result.snapshot.domain.afkPlayerIds, {'player_4'});
    expect(result.snapshot.domain.kickedPlayerIds, {'player_5'});
    expect(ai.snapshot, serverEngine.snapshot);
    expect(result.snapshot.domain, serverEngine.snapshot.domain);
    expect(result.snapshot.domain, serverEngine.snapshot.domain);
    expect(
      result.snapshot.domain.actions,
      serverEngine.snapshot.domain.actions,
    );
  });
}

String _unreviewedUnitActionEnvelopeBytes(Map<String, dynamic> source) {
  final copy = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  (copy['save'] as Map<String, dynamic>).remove('savedAt');
  copy
    ..remove('units')
    ..remove('artifacts');
  (copy['lifecycle'] as Map<String, dynamic>)
    ..remove('cityFoundingDraft')
    ..remove('pendingAction');
  return jsonEncode(copy);
}

GameSave _unitActionSave() => GameSave(
  id: 'save_1',
  name: 'Local unit action',
  mapName: 'verdantia',
  turn: 7,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 7, 29),
  camera: CameraState.zero,
  players: const [
    Player(id: 'player_1', name: 'Alice', colorValue: 0xFF000001),
  ],
);

WorldMap _mapData() => WorldMap(
  cols: 1,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
