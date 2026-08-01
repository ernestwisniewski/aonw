import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/game_intent_test_resolver.dart';

WorldMap _map() => WorldMap(
  cols: 5,
  rows: 5,
  tiles: [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

GameCity _city() => const GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'City',
  center: CityHex(col: 2, row: 2),
  controlledHexes: [CityHex(col: 2, row: 3)],
);

GameUnit _commander() =>
    GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 1, row: 1);

GameUnit _worker() => GameUnit(
  id: 'worker_player_1',
  ownerPlayerId: 'player_1',
  type: GameUnitType.worker,
  name: GameUnitType.worker.defaultNameToken,
  col: 1,
  row: 1,
);

void main() {
  late GameStateReducer reducer;

  setUp(() {
    reducer = GameStateReducer(mapData: _map());
  });

  test('start city worked hex selection enters pending interaction mode', () {
    final city = _city();
    final state = GameClientState(
      cities: [city],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: const InteractionState(moveCommandActive: true),
    );

    final result = resolveGameIntent(
      reducer,
      state,
      const StartCityWorkedHexSelectionCommand('city_1'),
    );

    expect(
      result.state.pendingAction,
      const PendingCityWorkedHexSelection(
        ownerPlayerId: 'player_1',
        cityId: 'city_1',
      ),
    );
    expect(result.state.moveCommandActive, isFalse);
  });

  test('cancel city worked hex selection clears matching pending mode', () {
    final state = GameClientState(
      interaction: const InteractionState(
        pendingAction: PendingCityWorkedHexSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
      ),
    );

    final result = resolveGameIntent(
      reducer,
      state,
      const CancelCityWorkedHexSelectionCommand('city_1'),
    );

    expect(result.state.pendingAction, isNull);
  });

  test('start city expansion selection enters pending interaction mode', () {
    final city = _city();
    final state = GameClientState(
      cities: [city],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: const InteractionState(moveCommandActive: true),
    );

    final result = resolveGameIntent(
      reducer,
      state,
      const StartCityExpansionSelectionCommand('city_1'),
    );

    expect(
      result.state.pendingAction,
      const PendingCityExpansionSelection(
        ownerPlayerId: 'player_1',
        cityId: 'city_1',
      ),
    );
    expect(result.state.moveCommandActive, isFalse);
  });

  test('cancel city expansion selection clears matching pending mode', () {
    final state = GameClientState(
      interaction: const InteractionState(
        pendingAction: PendingCityExpansionSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
      ),
    );

    final result = resolveGameIntent(
      reducer,
      state,
      const CancelCityExpansionSelectionCommand('city_1'),
    );

    expect(result.state.pendingAction, isNull);
  });

  test(
    'select worker improvement records the previewed type without starting a job',
    () {
      final worker = _worker();
      final startingState = GameClientState(
        units: [worker],
        cities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_1',
            name: 'City',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 1)],
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
            ),
          },
        ),
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
      );
      final withMode = resolveGameIntent(
        reducer,
        startingState,
        StartWorkerActionSelectionCommand(worker.id),
      );

      final result = resolveGameIntent(
        reducer,
        withMode.state,
        SelectWorkerImprovementCommand(worker.id, FieldImprovementType.farm),
      );

      final pending = result.state.pendingAction;
      expect(pending, isA<PendingWorkerActionSelection>());
      expect(
        (pending as PendingWorkerActionSelection).improvementType,
        FieldImprovementType.farm,
      );
      expect(result.state.units.single.workerJob, isNull);
    },
  );

  test('confirm worker improvement creates the job and clears the preview', () {
    final worker = _worker();
    final startingState = GameClientState(
      units: [worker],
      cities: const [
        GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 1)],
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      ),
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
    );
    final withMode = resolveGameIntent(
      reducer,
      startingState,
      StartWorkerActionSelectionCommand(worker.id),
    );
    final afterSelect = resolveGameIntent(
      reducer,
      withMode.state,
      SelectWorkerImprovementCommand(worker.id, FieldImprovementType.farm),
    );

    final result = resolveGameIntent(
      reducer,
      afterSelect.state,
      ConfirmWorkerImprovementCommand(worker.id),
    );

    expect(result.state.pendingAction, isNull);
    expect(
      result.state.units.single.workerJob?.improvementType,
      FieldImprovementType.farm,
    );
  });

  test('tile taps are reserved while a pending interaction mode is active', () {
    final commander = _commander();
    final selected = GameSelection.unit(
      commander,
      tile: _map().tileAt(commander.col, commander.row),
    );
    final state = GameClientState(
      units: [commander],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      interaction: InteractionState(
        selection: selected,
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'commander_player_1',
        ),
      ),
    );

    final result = resolveGameIntent(
      reducer,
      state,
      const TileTappedCommand(3, 3),
    );
    expect(result.state, equals(state));
  });

  test('worker action mode lets tile taps move the worker target', () {
    final worker = _worker();
    final selected = GameSelection.unit(
      worker,
      tile: _map().tileAt(worker.col, worker.row),
    );
    final state = GameClientState(
      units: [worker],
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 1, row: 1),
              const HexCoordinate(col: 2, row: 1),
            },
          ),
        },
      ),
      interaction: InteractionState(
        selection: selected,
        pendingAction: PendingWorkerActionSelection(
          ownerPlayerId: worker.ownerPlayerId,
          unitId: worker.id,
        ),
      ),
    );

    final preview = resolveGameIntent(
      reducer,
      state,
      const TileTappedCommand(2, 1),
    );

    expect(preview.state.pendingAction, state.pendingAction);
    expect(preview.state.movePreview?.targetCol, 2);
    expect(preview.state.movePreview?.targetRow, 1);

    final moved = resolveGameIntent(
      reducer,
      preview.state,
      const TileTappedCommand(2, 1),
    );

    expect(moved.state.pendingAction, state.pendingAction);
    expect(moved.state.units.single.col, 2);
    expect(moved.state.units.single.row, 1);
  });

  test('set active player clears pending interaction mode', () {
    final state = GameClientState(
      activePlayerId: 'player_1',
      interaction: const InteractionState(
        pendingAction: PendingCommanderMergeSelection(
          ownerPlayerId: 'player_1',
          commanderUnitId: 'commander_player_1',
        ),
      ),
    );

    final result = reducer.syncActivePlayer(
      state,
      playerId: 'player_2',
      canAct: true,
    );

    expect(result.state.pendingAction, isNull);
  });
}
