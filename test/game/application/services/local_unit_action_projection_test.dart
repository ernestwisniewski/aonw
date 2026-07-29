import 'dart:convert';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
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
      availableMovementPoints: 3,
      steps: const [],
    );
    final selection = GameSelection.unit(selectedUnit);
    final state = GameState(
      activePlayerId: 'player_1',
      units: [actedUnit, selectedUnit],
      interaction: GameInteractionState(
        selection: selection,
        movePreview: preview,
        moveCommandActive: true,
      ),
    );
    final baseSnapshot = SaveSnapshot.fromGameState(
      save: _unitActionSave(),
      state: state,
    );

    final result =
        LocalCommandResolver(
          reducer: _NoUnitActionLegacyReducer(mapData: _mapData()),
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
      availableMovementPoints: 3,
      steps: const [],
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [actedUnit],
      interaction: GameInteractionState(
        selection: GameSelection.unit(actedUnit),
        movePreview: preview,
        moveCommandActive: true,
      ),
    );
    final baseSnapshot = SaveSnapshot.fromGameState(
      save: _unitActionSave(),
      state: state,
    );

    final result =
        LocalCommandResolver(
          reducer: _NoUnitActionLegacyReducer(mapData: _mapData()),
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

  test('local unit action preserves sparse raw persistence envelope bytes', () {
    final unit = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 3,
    );
    final baseSnapshot = SaveSnapshot(
      save: _unitActionSave().copyWith(
        players: const [],
        gameMode: GameMode.multiplayer,
      ),
      playerColors: const {'player_1': 0xFF010203},
      playerCountries: const {'country_only': PlayerCountry.canada},
      units: [unit],
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: const {'session_only'},
        timeoutStreaksByPlayerId: const {'timeout_only': 2},
        afkPlayerIds: const {'afk_only'},
        kickedPlayerIds: const {'kicked_only'},
      ),
      eventLogOffset: 73,
    );
    final before = SaveSnapshotCodec.toJson(baseSnapshot);
    final savedAt = DateTime.utc(2026, 7, 29, 20);
    final mapData = _mapData();
    final ruleset = GameRuleset.standard();
    const command = SkipUnitTurnCommand('unit_1');

    final result =
        LocalCommandResolver(
          reducer: _NoUnitActionLegacyReducer(
            mapData: mapData,
            ruleset: ruleset,
          ),
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: baseSnapshot.toGameState(activePlayerId: 'player_1'),
          command: command,
          savedAt: savedAt,
          context: const GameCommandContext(
            actorPlayerId: 'player_1',
            commandTick: 3,
          ),
        );
    final serverEngine = const GameEngine().apply(
      snapshot: baseSnapshot.canonical,
      command: command,
      context: GameEngineContext(
        actorPlayerId: 'player_1',
        commandTick: 3,
        mapView: mapData,
        ruleset: ruleset,
      ),
    );
    final ai = const SimulationGameEngineAdapter().apply(
      snapshot: baseSnapshot.canonical,
      state: baseSnapshot.rawPersistentState,
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
    expect(result.snapshot.save.players, isEmpty);
    expect(result.snapshot.eventLogOffset, 73);
    expect(result.snapshot.units.single.movementPoints, 0);
    expect(result.snapshot.persistedTurnStartedAt, isNull);
    expect(result.snapshot.runtimeState.submittedPlayerIds, {'session_only'});
    expect(result.snapshot.runtimeState.timeoutStreaksByPlayerId, {
      'timeout_only': 2,
    });
    expect(result.snapshot.runtimeState.afkPlayerIds, {'afk_only'});
    expect(result.snapshot.runtimeState.kickedPlayerIds, {'kicked_only'});
    expect(ai.snapshot, serverEngine.snapshot);
    expect(result.snapshot.domain, serverEngine.snapshot.domain);
    expect(result.snapshot.session, serverEngine.snapshot.session);
    expect(result.snapshot.interaction, serverEngine.snapshot.interaction);
  });
}

String _unreviewedUnitActionEnvelopeBytes(Map<String, dynamic> source) {
  final copy = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  (copy['save'] as Map<String, dynamic>).remove('savedAt');
  copy
    ..remove('units')
    ..remove('artifacts');
  (copy['runtimeState'] as Map<String, dynamic>)
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

final class _NoUnitActionLegacyReducer extends GameStateReducer {
  const _NoUnitActionLegacyReducer({required super.mapData, super.ruleset});

  @override
  GameStateTransition reduce(
    GameState state,
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    if (command is SkipUnitTurnCommand || command is FortifyUnitCommand) {
      throw StateError('Migrated unit action reached the legacy reducer.');
    }
    return super.reduce(state, command, context: context);
  }
}

MapData _mapData() => MapData(
  cols: 1,
  rows: 1,
  tiles: [
    const TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
