import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local production rejection exposes strategic shortage metadata', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
      population: 8,
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      cities: const [city],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.massProduction},
          ),
        },
      ),
    );
    final snapshot = GameSnapshotFactory.fromClientState(
      save: GameSave(
        id: 'save_1',
        name: 'Strategic shortage',
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

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData),
        ).resolve(
          baseSnapshot: snapshot,
          currentState: state,
          command: const StartUnitProductionCommand(
            'city_1',
            GameUnitType.tank,
          ),
          savedAt: DateTime.utc(2026, 7, 29, 18),
          context: const GameCommandContext(actorPlayerId: 'player_1'),
        );

    expect(result.state, same(state));
    expect(result.accepted, isFalse);
    expect(
      result.rejectionReason,
      'unit_production_missing_strategic_resource',
    );
  });

  test('AI worker command preserves the human interaction owner', () {
    final humanUnit = GameUnit(
      id: 'human_unit',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Human',
      col: 2,
      row: 0,
    );
    final aiWorker = GameUnit(
      id: 'ai_worker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.worker,
      name: 'AI worker',
      col: 1,
      row: 0,
    );
    const pending = PendingAttackTargeting(
      ownerPlayerId: 'player_1',
      attackerUnitId: 'human_unit',
    );
    final preview = UnitMovementPlan(
      unitId: 'human_unit',
      targetCol: 1,
      targetRow: 0,
      totalCost: 1,
      availableMovementUnits: 3,
      steps: const [],
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      units: [humanUnit, aiWorker],
      cities: const [
        GameCity(
          id: 'ai_city',
          ownerPlayerId: 'player_2',
          name: 'AI City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 0)],
        ),
      ],
      research: ResearchState(
        players: {
          'player_2': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      ),
      interaction: InteractionState(
        selection: GameSelection.unit(humanUnit),
        pendingAction: pending,
        moveCommandActive: true,
        movePreview: preview,
      ),
    );
    final snapshot = GameSnapshotFactory.fromClientState(
      save: GameSave(
        id: 'save_ai_worker',
        name: 'AI worker projection',
        mapName: 'verdantia',
        turn: 7,
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.active,
        },
        savedAt: DateTime.utc(2026, 7, 29),
        camera: CameraState.zero,
        players: const [
          Player(id: 'player_1', name: 'Alice', colorValue: 1),
          Player(id: 'player_2', name: 'AI', colorValue: 2),
        ],
      ),
      state: state,
    );

    final result =
        LocalCommandResolver(
          reducer: GameStateReducer(mapData: _mapData),
        ).resolve(
          baseSnapshot: snapshot,
          currentState: state,
          command: const SelectWorkerImprovementCommand(
            'ai_worker',
            FieldImprovementType.farm,
          ),
          savedAt: DateTime.utc(2026, 7, 29, 19),
          context: const GameCommandContext(actorPlayerId: 'player_2'),
        );

    expect(result.accepted, isTrue);
    expect(result.state.unitById('ai_worker')?.workerJob, isNotNull);
    expect(result.state.selectedUnitId, 'human_unit');
    expect(result.state.pendingAction, same(pending));
    expect(result.state.movePreview, same(preview));
    expect(result.state.moveCommandActive, isTrue);
  });
}

final _mapData = WorldMap(
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < 3; col++)
      WorldTile(
        col: col,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
  ],
);
