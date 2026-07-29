import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local submit rejection falls back to persisted player states', () {
    final save = GameSave(
      id: 'save_1',
      name: 'Metadata-free local save',
      mapName: 'verdantia',
      turn: 7,
      playerStates: const {'player_1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 7, 11),
      camera: CameraState.zero,
    );
    const state = GameState(activePlayerId: 'player_1');
    final savedAt = DateTime.utc(2026, 7, 11, 12);

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData()),
        ).resolve(
          baseSnapshot: SaveSnapshot.fromGameState(save: save, state: state),
          currentState: state,
          command: const SubmitTurnCommand('not-a-player'),
          savedAt: savedAt,
        );

    expect(result.snapshot.save.playerStates, save.playerStates);
    expect(result.snapshot.save.savedAt, savedAt);
    expect(result.snapshot.eventLogOffset, 0);
    expect(result.snapshot.domain.turn, 7);
    expect(result.context.combatSeedTurn, 7);
    expect(
      result.context.paceBalance,
      result.snapshot.domain.matchRules.paceBalance,
    );
    expect(
      result.context.victoryRules,
      result.snapshot.domain.matchRules.victory,
    );
    expect(result.state, state);
    expect(result.events, isEmpty);
  });

  test('local submit accepts a participant synthesized from sparse roster', () {
    final save = GameSave(
      id: 'save_1',
      name: 'Sparse local save',
      mapName: 'verdantia',
      turn: 7,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'legacy_only': PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 7, 11),
      camera: CameraState.zero,
      players: const [
        Player(id: 'player_1', name: 'Alice', colorValue: 0xFF000001),
      ],
    );
    const state = GameState(activePlayerId: 'legacy_only');

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData()),
        ).resolve(
          baseSnapshot: SaveSnapshot.fromGameState(save: save, state: state),
          currentState: state,
          command: const SubmitTurnCommand('legacy_only'),
          savedAt: DateTime.utc(2026, 7, 11, 12),
          context: const GameCommandContext(actorPlayerId: 'legacy_only'),
        );

    expect(
      result.snapshot.session.turnStatesByPlayerId['legacy_only'],
      PlayerTurnState.finished,
    );
    expect(result.state.submittedPlayerIds, {'legacy_only'});
  });

  test(
    'local final submit preserves presentation and persisted interaction',
    () {
      final save = GameSave(
        id: 'save_1',
        name: 'Canonical local turn',
        mapName: 'verdantia',
        turn: 7,
        playerStates: const {
          'player_1': PlayerTurnState.finished,
          'player_2': PlayerTurnState.active,
        },
        savedAt: DateTime.utc(2026, 7, 11),
        camera: CameraState.zero,
        players: const [
          Player(id: 'player_1', name: 'Alice', colorValue: 0xFF000001),
          Player(id: 'player_2', name: 'Bob', colorValue: 0xFF000002),
        ],
        gameMode: GameMode.multiplayer,
      );
      const pendingAction = PendingResearchSelection(ownerPlayerId: 'player_1');
      const state = GameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        submittedPlayerIds: {'player_1'},
        interaction: GameInteractionState(pendingAction: pendingAction),
      );
      final baseSnapshot = SaveSnapshot.fromGameState(
        save: save,
        state: state,
        eventLogOffset: 17,
      );

      final result =
          LocalCommandResolver(
            reducer: GameStateReducer(mapData: _mapData()),
          ).resolve(
            baseSnapshot: baseSnapshot,
            currentState: state,
            command: const SubmitTurnCommand('player_2'),
            savedAt: DateTime.utc(2026, 7, 11, 12),
          );

      expect(result.snapshot.save.turn, 8);
      expect(result.snapshot.eventLogOffset, 17);
      expect(result.snapshot.domain.turn, 8);
      expect(result.state.submittedPlayerIds, isEmpty);
      expect(result.state.pendingAction, pendingAction);
      expect(result.state.activePlayerId, 'player_1');
      expect(result.state.activePlayerCanAct, isTrue);
    },
  );

  test(
    'local skip uses canonical engine state and preserves presentation envelope',
    () {
      final savedAt = DateTime.utc(2026, 7, 29, 14);
      final state = GameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [
          GameUnit(
            id: 'unit_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: GameUnitType.warrior.defaultNameToken,
            col: 0,
            row: 0,
            movementPoints: 3,
            queuedPath: QueuedMovePath(
              targetCol: 1,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          ),
        ],
      );
      final baseSnapshot = SaveSnapshot.fromGameState(
        save: GameSave(
          id: 'save_1',
          name: 'Local engine',
          mapName: 'verdantia',
          turn: 7,
          playerStates: const {'player_1': PlayerTurnState.active},
          savedAt: DateTime.utc(2026, 7, 29),
          camera: const CameraState(x: 4, y: 5, zoom: 1.25),
          players: const [
            Player(id: 'player_1', name: 'Alice', colorValue: 0xFF000001),
          ],
        ),
        state: state,
        eventLogOffset: 23,
      );

      final result =
          LocalCommandResolver(
            reducer: _NoUnitActionLegacyReducer(mapData: _mapData()),
          ).resolve(
            baseSnapshot: baseSnapshot,
            currentState: state,
            command: const SkipUnitTurnCommand('unit_1'),
            savedAt: savedAt,
            context: const GameCommandContext(
              actorPlayerId: 'player_1',
              commandTick: 9,
            ),
          );

      expect(result.state.activePlayerId, 'player_1');
      expect(result.state.activePlayerCanAct, isTrue);
      expect(result.state.units.single.movementPoints, 0);
      expect(result.state.units.single.queuedPath, isNull);
      expect(
        result.state.pendingAction,
        const PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
          restoreMovementPoints: 3,
        ),
      );
      expect(result.snapshot.domain.units, result.state.units);
      expect(
        result.snapshot.interaction.pendingAction,
        result.state.pendingAction,
      );
      expect(result.snapshot.eventLogOffset, 23);
      expect(result.snapshot.save.id, 'save_1');
      expect(result.snapshot.save.name, 'Local engine');
      expect(
        result.snapshot.save.camera,
        const CameraState(x: 4, y: 5, zoom: 1.25),
      );
      expect(result.snapshot.save.savedAt, savedAt);
      expect(result.events, isEmpty);
      expect(result.uiEffects, isEmpty);
    },
  );

  test('local engine rejection and accepted no-op retain state identity', () {
    final unit = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 0,
      posture: UnitPosture.fortified,
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [unit],
      interaction: const GameInteractionState(
        pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
      ),
    );
    final baseSnapshot = SaveSnapshot.fromGameState(
      save: GameSave(
        id: 'save_1',
        name: 'Local identity',
        mapName: 'verdantia',
        turn: 7,
        playerStates: const {'player_1': PlayerTurnState.active},
        savedAt: DateTime.utc(2026, 7, 29),
        camera: CameraState.zero,
        players: const [
          Player(id: 'player_1', name: 'Alice', colorValue: 0xFF000001),
        ],
      ),
      state: state,
    );
    final resolver = LocalCommandResolver(
      reducer: _NoUnitActionLegacyReducer(mapData: _mapData()),
    );

    final rejected = resolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: state,
      command: const SkipUnitTurnCommand('unit_1'),
      savedAt: DateTime.utc(2026, 7, 29, 15),
      context: const GameCommandContext(actorPlayerId: 'player_2'),
    );
    final noOp = resolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: state,
      command: const FortifyUnitCommand('unit_1'),
      savedAt: DateTime.utc(2026, 7, 29, 16),
      context: const GameCommandContext(actorPlayerId: 'player_1'),
    );
    final inactiveState = state.copyWith(activePlayerCanAct: false);
    final inactive = resolver.resolve(
      baseSnapshot: baseSnapshot,
      currentState: inactiveState,
      command: const SkipUnitTurnCommand('unit_1'),
      savedAt: DateTime.utc(2026, 7, 29, 17),
    );

    expect(rejected.state, same(state));
    expect(rejected.snapshot.domain, baseSnapshot.domain);
    expect(noOp.state, same(state));
    expect(noOp.snapshot.domain, baseSnapshot.domain);
    expect(noOp.snapshot.interaction, baseSnapshot.interaction);
    expect(inactive.state, same(inactiveState));
    expect(inactive.snapshot.domain.units.single, unit);
  });

  test(
    'unit action fixtures keep local server-oracle and AI snapshots byte equal',
    () {
      for (final fixtureName in const [
        'unit-action-skip-accepted',
        'unit-action-fortify-unrelated-pending-accepted',
      ]) {
        final fixture =
            jsonDecode(
                  File(
                    'test/fixtures/reducer_parity/$fixtureName.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final input = fixture['input'] as Map<String, dynamic>;
        final expected = fixture['expected'] as Map<String, dynamic>;
        final now = DateTime.parse(input['now'] as String);
        final save = GameSave.fromJson(input['save'] as Map<String, dynamic>);
        final persistent = PersistentGameState.fromJson(
          input['state'] as Map<String, dynamic>,
        );
        final mapData = MapDataCodec.fromJson(jsonEncode(input['map']));
        final command = GameCommandSerializer.fromJson(
          input['command'] as Map<String, dynamic>,
        );
        final actorPlayerId = input['actorPlayerId'] as String;
        final tick = input['tick'] as int;
        final baseSnapshot = SaveSnapshot.fromPersistentState(
          save: save,
          state: persistent,
        );
        final ruleset = GameRuleset.standard().copyWith(
          paceBalance: save.matchRules.paceBalance,
        );

        final local =
            LocalCommandResolver(
              reducer: _NoUnitActionLegacyReducer(
                mapData: mapData,
                ruleset: ruleset,
              ),
            ).resolve(
              baseSnapshot: baseSnapshot,
              currentState: baseSnapshot.toGameState(
                activePlayerId: actorPlayerId,
              ),
              command: command,
              savedAt: now,
              context: GameCommandContext(
                actorPlayerId: actorPlayerId,
                commandTick: tick,
              ),
            );
        final ai = const SimulationGameEngineAdapter().apply(
          snapshot: baseSnapshot.canonical,
          state: persistent,
          command: command,
          actorPlayerId: actorPlayerId,
          commandTick: tick,
          mapView: mapData,
          ruleset: ruleset,
        );
        final engineOracle = const GameEngine().apply(
          snapshot: baseSnapshot.canonical,
          command: command,
          context: GameEngineContext(
            actorPlayerId: actorPlayerId,
            commandTick: tick,
            mapView: mapData,
            ruleset: ruleset,
          ),
        );
        final serverOracle = SaveSnapshot.fromPersistentState(
          save: GameSave.fromJson({
            ...expected['save'] as Map<String, dynamic>,
            'savedAt': now.toIso8601String(),
          }),
          state: PersistentGameState.fromJson(
            expected['state'] as Map<String, dynamic>,
          ),
        ).canonical;

        expect(ai.accepted, isTrue, reason: fixtureName);
        expect(
          _canonicalSnapshotBytes(local.snapshot.canonical),
          _canonicalSnapshotBytes(serverOracle),
          reason: fixtureName,
        );
        expect(ai.snapshot, engineOracle.snapshot, reason: fixtureName);
      }
    },
  );
}

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

String _canonicalSnapshotBytes(CanonicalGameSnapshot snapshot) {
  final legacy = const LegacyGameSnapshotAdapter().toLegacy(snapshot);
  return jsonEncode({
    'save': legacy.save.toJson(),
    'state': legacy.state.toJson(),
    'eventLogOffset': legacy.eventLogOffset,
  });
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
