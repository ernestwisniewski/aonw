import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sequential turn follows canonical participant order', () {
    final queuedUnit = _queuedUnit(ownerPlayerId: 'player_1');
    final state = GameState(activePlayerId: 'player_2', units: [queuedUnit]);
    final snapshot = _snapshot(
      state: state,
      playerStates: const {
        'player_2': PlayerTurnState.active,
        'player_1': PlayerTurnState.active,
        'player_3': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'player_2', name: 'Two', colorValue: 2),
        Player(id: 'player_1', name: 'One', colorValue: 1),
        Player(id: 'player_3', name: 'Three', colorValue: 3),
      ],
    );

    final result = _resolver.resolve(
      baseSnapshot: snapshot,
      currentState: state,
      command: const EndTurnCommand('player_2'),
      savedAt: DateTime.utc(2026, 7, 30, 12),
      context: const GameCommandContext(actorPlayerId: 'player_2'),
    );

    expect(result.state.units.single.col, 1);
    expect(result.movementExecutions, hasLength(1));
    expect(result.movementExecutions.single.unitId, queuedUnit.id);
  });

  test('accepted turn owns persisted interaction and preserves selection', () {
    final queuedUnit = _queuedUnit(
      ownerPlayerId: 'player_2',
      autoExploring: true,
    );
    final selectedUnit = GameUnit(
      id: 'selected_unit',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 0,
    );
    final selection = GameSelection.unit(selectedUnit);
    final state = GameState(
      activePlayerId: 'player_1',
      units: [queuedUnit, selectedUnit],
      interaction: GameInteractionState(
        selection: selection,
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: 'player_2',
          unitId: 'queued_unit',
          restoreMovementPoints: 3,
        ),
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'queued_unit',
          ownerPlayerId: 'player_2',
          center: const CityHex(col: 0, row: 0),
        ),
      ),
    );
    final snapshot = _snapshot(
      state: state,
      playerStates: const {
        'player_1': PlayerTurnState.active,
        'player_2': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'player_1', name: 'One', colorValue: 1),
        Player(id: 'player_2', name: 'Two', colorValue: 2),
      ],
    );

    final result = _resolver.resolve(
      baseSnapshot: snapshot,
      currentState: state,
      command: const EndTurnCommand('player_1'),
      savedAt: DateTime.utc(2026, 7, 30, 12),
    );

    expect(result.state.pendingAction, isNull);
    expect(result.state.cityFoundingDraft, isNull);
    expect(result.state.selection, same(selection));
    expect(result.snapshot.interaction.pendingAction, isNull);
    expect(result.snapshot.interaction.cityFoundingDraft, isNull);
  });
}

final _resolver = LocalCommandResolver(
  reducer: GameStateReducer(mapData: _lineMapData()),
);

SaveSnapshot _snapshot({
  required GameState state,
  required Map<String, PlayerTurnState> playerStates,
  required List<Player> players,
}) {
  return SaveSnapshot.fromGameState(
    save: GameSave(
      id: 'save_1',
      name: 'Turn projection',
      mapName: 'verdantia',
      turn: 7,
      playerStates: playerStates,
      savedAt: DateTime.utc(2026, 7, 30),
      camera: CameraState.zero,
      players: players,
      gameMode: GameMode.hotSeat,
    ),
    state: state,
  );
}

GameUnit _queuedUnit({
  required String ownerPlayerId,
  bool autoExploring = false,
}) {
  final type = autoExploring ? GameUnitType.scout : GameUnitType.warrior;
  return GameUnit(
    id: 'queued_unit',
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: 0,
    row: 0,
    movementPoints: 0,
    posture: autoExploring ? UnitPosture.autoExploring : UnitPosture.active,
    queuedPath: QueuedMovePath(
      targetCol: 1,
      targetRow: 0,
      steps: const [
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      ],
    ),
  );
}

MapData _lineMapData() => MapData(
  cols: 2,
  rows: 1,
  tiles: [
    for (var col = 0; col < 2; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);
