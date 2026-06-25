import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReplayService', () {
    test('builds timeline from initial snapshot and logged commands', () async {
      final initial = _snapshot();
      final service = _service(
        replayStore: _MemoryReplayStore({'save_1': initial}),
        eventLog: _MemoryEventLog([
          LoggedCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 12, 1),
            turn: 1,
            command: const SetActivePlayerCommand('p1', canAct: true),
          ),
        ]),
      );

      final timeline = await service.buildTimeline('save_1');

      expect(timeline.initialState.activePlayerId, isEmpty);
      expect(timeline.steps, hasLength(1));
      expect(timeline.steps.single.offset, 1);
      expect(timeline.steps.single.previousState.activePlayerId, isEmpty);
      expect(timeline.steps.single.state.activePlayerId, 'p1');
      expect(
        timeline.steps.single.save.savedAt,
        DateTime.utc(2026, 4, 24, 12, 1),
      );
    });

    test('infers actors for legacy merchant replay commands', () {
      final merchant = GameUnit.produced(
        id: 'merchant_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.merchant,
        col: 0,
        row: 0,
      );
      final commands = [
        const AssignMerchantTradeRouteCommand('merchant_1', 'city_target'),
        const MoveMerchantToCityCommand('merchant_1', 'city_target'),
      ];

      for (final command in commands) {
        final actorPlayerId = ReplayStep.inferEffectiveActorPlayerId(
          loggedCommand: LoggedCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 12, 1),
            turn: 1,
            command: command,
          ),
          state: GameState(units: [merchant]),
        );

        expect(actorPlayerId, 'p1');
      }
    });

    test(
      'includes merchant route movement effects when finalizing replay',
      () async {
        final merchant =
            GameUnit.produced(
                  id: 'merchant_1',
                  ownerPlayerId: 'p1',
                  type: GameUnitType.merchant,
                  col: 0,
                  row: 0,
                )
                .copyWith(movementPoints: 0)
                .copyWithMerchantTradeRoute(
                  _merchantRoute(
                    originCityId: 'city_origin',
                    destinationCityId: 'city_target',
                    toCol: 3,
                  ),
                );
        const origin = GameCity(
          id: 'city_origin',
          ownerPlayerId: 'p1',
          name: 'Origin',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 0, row: 0)],
        );
        const target = GameCity(
          id: 'city_target',
          ownerPlayerId: 'p1',
          name: 'Target',
          center: CityHex(col: 3, row: 0),
          controlledHexes: [CityHex(col: 3, row: 0)],
        );
        final service = _service(
          replayStore: _MemoryReplayStore({
            'save_1': _snapshot(
              units: [merchant],
              cities: const [origin, target],
            ),
          }),
          eventLog: _MemoryEventLog([
            LoggedCommand(
              offset: 1,
              timestamp: DateTime.utc(2026, 4, 24, 12, 1),
              turn: 1,
              command: const SubmitTurnCommand('p1'),
            ),
          ]),
          mapData: _map(cols: 4, rows: 1),
        );

        final timeline = await service.buildTimeline('save_1');

        final step = timeline.steps.single;
        final movedMerchant = step.state.units.single;
        expect(movedMerchant.col, 3);
        expect(movedMerchant.row, 0);
        expect(movedMerchant.merchantTradeRoute?.originCityId, 'city_target');

        final effect = step.uiEffects.whereType<AnimateUnitMoveEffect>().single;
        expect(effect.unitId, merchant.id);
        expect(effect.fromCol, 0);
        expect(effect.fromRow, 0);
        expect(effect.steps.map((step) => step.col), [1, 2, 3]);
      },
    );

    test('infers actor before reducing legacy artifact commands', () async {
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.ancientImperialCrown,
        col: 0,
        row: 0,
      );
      final unit = GameUnit(
        id: 'warrior_player_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final service = _service(
        replayStore: _MemoryReplayStore({
          'save_1': _snapshot(units: [unit], artifacts: [artifact]),
        }),
        eventLog: _MemoryEventLog([
          LoggedCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 12, 1),
            turn: 1,
            command: const StartArtifactExcavationCommand('warrior_player_1'),
          ),
        ]),
      );

      final timeline = await service.buildTimeline('save_1');

      final step = timeline.steps.single;
      final replayedUnit = step.state.units.single;
      final replayedArtifact = step.state.artifacts.single;
      expect(step.loggedCommand.actorPlayerId, isNull);
      expect(step.effectiveActorPlayerId, 'p1');
      expect(replayedUnit.excavatingArtifactId, artifact.id);
      expect(replayedArtifact.location.isBeingExcavated, isTrue);
      expect(replayedArtifact.location.unitId, unit.id);
      expect(replayedArtifact.location.remainingTurns, 2);
    });

    test('infers actor before reducing legacy artifact storage', () async {
      final artifact = WorldArtifact(
        id: WorldArtifact.idForType(WorldArtifactType.ancientImperialCrown),
        type: WorldArtifactType.ancientImperialCrown,
        location: const WorldArtifactLocation.carried(
          unitId: 'warrior_player_1',
        ),
      );
      final unit = GameUnit(
        id: 'warrior_player_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        carriedArtifactId: artifact.id,
      );
      const city = GameCity(
        id: 'city_p1_0_0',
        ownerPlayerId: 'p1',
        name: 'Warsaw',
        center: CityHex(col: 0, row: 0),
      );
      final service = _service(
        replayStore: _MemoryReplayStore({
          'save_1': _snapshot(
            units: [unit],
            cities: [city],
            artifacts: [artifact],
          ),
        }),
        eventLog: _MemoryEventLog([
          LoggedCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 24, 12, 1),
            turn: 1,
            command: const StoreArtifactInCityCommand('warrior_player_1'),
          ),
        ]),
      );

      final timeline = await service.buildTimeline('save_1');

      final step = timeline.steps.single;
      final replayedUnit = step.state.units.single;
      final replayedArtifact = step.state.artifacts.single;
      expect(step.loggedCommand.actorPlayerId, isNull);
      expect(step.effectiveActorPlayerId, 'p1');
      expect(replayedUnit.carriedArtifactId, isNull);
      expect(replayedArtifact.location.isStored, isTrue);
      expect(replayedArtifact.location.cityId, city.id);
    });

    test('rejects logs with offset gaps', () async {
      final service = _service(
        replayStore: _MemoryReplayStore({'save_1': _snapshot()}),
        eventLog: _MemoryEventLog([
          LoggedCommand(
            offset: 2,
            timestamp: DateTime.utc(2026, 4, 24, 12, 1),
            turn: 1,
            command: const SetActivePlayerCommand('p1', canAct: true),
          ),
        ]),
      );

      await expectLater(
        service.buildTimeline('save_1'),
        throwsA(
          isA<ReplayBuildException>().having(
            (error) => error.reason,
            'reason',
            ReplayBuildFailureReason.offsetGap,
          ),
        ),
      );
    });

    test('rejects saves without replay seed snapshots', () async {
      final service = _service(
        replayStore: _MemoryReplayStore(),
        eventLog: _MemoryEventLog(),
      );

      await expectLater(
        service.buildTimeline('save_1'),
        throwsA(
          isA<ReplayBuildException>().having(
            (error) => error.reason,
            'reason',
            ReplayBuildFailureReason.missingInitialSnapshot,
          ),
        ),
      );
    });
  });
}

ReplayService _service({
  required ReplayStore replayStore,
  required EventLog eventLog,
  MapData? mapData,
}) {
  final reducer = GameStateReducer(mapData: mapData ?? _map());
  return ReplayService(
    replayStore: replayStore,
    eventLog: eventLog,
    commandResolver: LocalCommandResolver(reducer: reducer),
  );
}

SaveSnapshot _snapshot({
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  List<WorldArtifact> artifacts = const [],
}) {
  return SaveSnapshot(
    save: GameSave(
      id: 'save_1',
      name: 'Campaign',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 1,
      playerStates: const {'p1': PlayerTurnState.active},
      savedAt: DateTime.utc(2026, 4, 24, 12),
      camera: CameraState.zero,
      players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
    ),
    units: units,
    cities: cities,
    artifacts: artifacts,
  );
}

MerchantTradeRoute _merchantRoute({
  required String originCityId,
  required String destinationCityId,
  required int toCol,
}) {
  return MerchantTradeRoute(
    originCityId: originCityId,
    destinationCityId: destinationCityId,
    steps: [
      for (var col = 0; col <= toCol; col++)
        UnitMovementStep(
          col: col,
          row: 0,
          enterCost: col == 0 ? 0 : 1,
          cumulativeCost: col,
        ),
    ],
  );
}

MapData _map({int cols = 1, int rows = 1}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

class _MemoryReplayStore implements ReplayStore {
  final Map<String, SaveSnapshot> snapshots;

  _MemoryReplayStore([Map<String, SaveSnapshot>? snapshots])
    : snapshots = Map.of(snapshots ?? const {});

  @override
  Future<void> delete(String saveId) async {
    snapshots.remove(saveId);
  }

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async =>
      snapshots[saveId];

  @override
  Future<void> saveInitialSnapshot(String saveId, SaveSnapshot snapshot) async {
    snapshots.putIfAbsent(saveId, () => snapshot);
  }
}

class _MemoryEventLog implements EventLog {
  final List<LoggedCommand> commands;

  _MemoryEventLog([List<LoggedCommand> commands = const []])
    : commands = List.of(commands)
        ..sort((a, b) => a.offset.compareTo(b.offset));

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    commands
      ..add(command)
      ..sort((a, b) => a.offset.compareTo(b.offset));
  }

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    for (final command in commands) {
      if (command.offset > latest) latest = command.offset;
    }
    return latest;
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}
