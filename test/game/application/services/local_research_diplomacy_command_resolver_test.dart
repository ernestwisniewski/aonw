import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'local research uses the engine and preserves the persistence envelope',
    () {
      final savedAt = DateTime.utc(2026, 7, 30, 12);
      const pending = PendingResearchSelection(ownerPlayerId: 'player_1');
      const state = GameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        interaction: GameInteractionState(
          pendingAction: pending,
          moveCommandActive: true,
        ),
      );
      final baseSnapshot = SaveSnapshot.fromGameState(
        save: GameSave(
          id: 'save_1',
          name: 'Research envelope',
          mapName: 'verdantia',
          turn: 4,
          playerStates: const {
            'player_1': PlayerTurnState.active,
            'player_2': PlayerTurnState.active,
          },
          savedAt: DateTime.utc(2026, 7, 30),
          camera: const CameraState(x: 7, y: 8, zoom: 1.5),
          players: const [
            Player(id: 'player_1', name: 'Alice', colorValue: 1),
            Player(id: 'player_2', name: 'Bob', colorValue: 2),
          ],
          gameMode: GameMode.multiplayer,
        ),
        state: state,
        eventLogOffset: 31,
      );

      final result =
          LocalCommandResolver(
            reducer: GameStateReducer(mapData: _mapData()),
          ).resolve(
            baseSnapshot: baseSnapshot,
            currentState: state,
            command: const SelectTechnologyCommand(
              'player_1',
              TechnologyId.agriculture,
            ),
            savedAt: savedAt,
            context: const GameCommandContext(actorPlayerId: 'player_1'),
          );

      expect(
        result.state.research.forPlayer('player_1').activeTechnologyId,
        TechnologyId.agriculture,
      );
      expect(result.state.pendingAction, isNull);
      expect(result.state.moveCommandActive, isTrue);
      expect(result.snapshot.domain.research, result.state.research);
      expect(result.snapshot.eventLogOffset, 31);
      expect(result.snapshot.save.name, 'Research envelope');
      expect(
        result.snapshot.save.camera,
        const CameraState(x: 7, y: 8, zoom: 1.5),
      );
      expect(result.snapshot.save.savedAt, savedAt);
      expect(
        result.snapshot.domain.participants,
        same(baseSnapshot.domain.participants),
      );
      expect(result.snapshot.session.turnStatesByPlayerId, {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      });
      expect(result.events, isEmpty);
      expect(result.uiEffects, isEmpty);
    },
  );

  test(
    'local diplomacy emits ordered events without entering the legacy reducer',
    () {
      final state = GameState(
        activePlayerId: 'player_1',
        diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
        interaction: const GameInteractionState(moveCommandActive: true),
      );
      final baseSnapshot = SaveSnapshot.fromGameState(
        save: GameSave(
          id: 'save_1',
          name: 'Diplomacy envelope',
          mapName: 'verdantia',
          turn: 4,
          playerStates: const {
            'player_1': PlayerTurnState.active,
            'player_2': PlayerTurnState.active,
          },
          savedAt: DateTime.utc(2026, 7, 30),
          camera: CameraState.zero,
          players: const [
            Player(id: 'player_1', name: 'Alice', colorValue: 1),
            Player(id: 'player_2', name: 'Bob', colorValue: 2),
          ],
          gameMode: GameMode.multiplayer,
        ),
        state: state,
        eventLogOffset: 37,
      );

      final result =
          LocalCommandResolver(
            reducer: GameStateReducer(mapData: _mapData()),
          ).resolve(
            baseSnapshot: baseSnapshot,
            currentState: state,
            command: const SendDiplomaticProposalCommand(
              playerId: 'player_1',
              targetPlayerId: 'player_2',
              kind: DiplomaticProposalKind.friendship,
              proposalId: 'proposal_1',
            ),
            savedAt: DateTime.utc(2026, 7, 30, 13),
            context: const GameCommandContext(actorPlayerId: 'player_1'),
          );

      expect(result.state.diplomacy.pendingProposals.keys, ['proposal_1']);
      expect(result.events.map(GameEventSerializer.toJson), [
        {
          'type': 'DiplomaticProposalSent',
          'proposalId': 'proposal_1',
          'fromPlayerId': 'player_1',
          'toPlayerId': 'player_2',
          'kind': 'friendship',
          'expiresOnTurn': 9,
        },
      ]);
      expect(result.state.moveCommandActive, isTrue);
      expect(result.snapshot.domain.diplomacy, result.state.diplomacy);
      expect(result.snapshot.eventLogOffset, 37);
      expect(result.uiEffects, isEmpty);
    },
  );

  test('cancel research selection remains on the local intent reducer', () {
    const state = GameState(
      activePlayerId: 'player_1',
      interaction: GameInteractionState(
        pendingAction: PendingResearchSelection(ownerPlayerId: 'player_1'),
      ),
    );
    final snapshot = SaveSnapshot.fromGameState(
      save: GameSave(
        id: 'save_1',
        name: 'Cancel research',
        mapName: 'verdantia',
        turn: 4,
        playerStates: const {'player_1': PlayerTurnState.active},
        savedAt: DateTime.utc(2026, 7, 30),
        camera: CameraState.zero,
        players: const [Player(id: 'player_1', name: 'Alice', colorValue: 1)],
      ),
      state: state,
    );

    final result =
        GameIntentResolver(
          reducer: GameStateReducer(mapData: _mapData()),
        ).resolve(
          state.interaction,
          const CancelResearchSelectionCommand('player_1'),
          state,
        );

    expect(result.interaction.pendingAction, isNull);
    expect(snapshot.interaction.pendingAction, isA<PendingResearchSelection>());
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
