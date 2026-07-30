import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authoritative ACK movement', () {
    test(
      'returns exact global movement facts without local domain effects',
      () async {
        final before = _beforeState();
        final after = _afterState();
        const camera = JumpCameraEffect(col: 3, row: 3);
        final reducer = _EffectReducer([..._localMovementEffects(), camera]);
        final dispatcher = _ScriptedDispatcher(
          (_) => _acceptedAck(
            after: after,
            movementExecutions: _exactMovementExecutions(),
          ),
        );
        final transport = _transport(
          dispatcher: dispatcher,
          reducer: reducer,
          repository: _Repository(_snapshot(before, offset: 0, turn: 1)),
        );

        final result = await transport.dispatch(
          saveId: 'save_1',
          currentState: before,
          command: const SubmitTurnCommand('player_1'),
        );

        expect(result.snapshot, isNotNull);
        expect(result.uiEffects, isEmpty);
        expect(result.movementExecutions.map(_movementSnapshot), const [
          ('unit_a', 0, 0, 1, 0, 7, 7),
          ('unit_b', 0, 1, 1, 1, 11, 11),
          ('unit_a', 1, 0, 2, 0, 13, 20),
        ]);
        expect(result.movementExecutions, hasLength(3));
        expect(result.uiEffects.clear, throwsUnsupportedError);
      },
    );

    test('explicit empty suppresses local and inferred movement', () async {
      final before = _beforeState();
      final after = _afterState();
      const camera = JumpCameraEffect(col: 3, row: 3);
      final reducer = _EffectReducer([..._localMovementEffects(), camera]);
      final dispatcher = _ScriptedDispatcher(
        (_) => _acceptedAck(
          after: after,
          movementExecutions: WireMovementExecutionList(const []),
        ),
      );
      final transport = _transport(
        dispatcher: dispatcher,
        reducer: reducer,
        repository: _Repository(_snapshot(before, offset: 0, turn: 1)),
      );

      final result = await transport.dispatch(
        saveId: 'save_1',
        currentState: before,
        command: const SubmitTurnCommand('player_1'),
      );

      expect(result.snapshot, isNotNull);
      expect(result.movementExecutions, isEmpty);
      expect(result.uiEffects, isEmpty);
    });

    test('lost ACK retry commits and animates the stored plan once', () async {
      final before = _beforeState();
      final after = _afterState();
      final reducer = _EffectReducer(_localMovementEffects());
      final dispatcher = _CommitThenDropDispatcher(
        _acceptedAck(
          after: after,
          movementExecutions: _exactMovementExecutions(),
        ),
      );
      final repository = _Repository(_snapshot(before, offset: 0, turn: 1));
      final transport = _transport(
        dispatcher: dispatcher,
        reducer: reducer,
        repository: repository,
      );
      const command = SubmitTurnCommand('player_1');

      await expectLater(
        transport.dispatch(
          saveId: 'save_1',
          currentState: before,
          command: command,
        ),
        throwsA(isA<TimeoutException>()),
      );
      final retried = await transport.dispatch(
        saveId: 'save_1',
        currentState: before,
        command: command,
      );

      expect(dispatcher.commits, 1);
      expect(reducer.calls, 0);
      expect(dispatcher.sent.map((value) => value.wire.tick), [31, 31]);
      expect(
        dispatcher.sent.map((value) => value.clientMessageId).toSet(),
        hasLength(1),
      );
      expect(retried.snapshot, isNotNull);
      expect(retried.movementExecutions, hasLength(3));
    });

    test('catch-up snapshot prevents stored ACK movement replay', () async {
      final before = _beforeState();
      final after = _afterState();
      final reducer = _EffectReducer(_localMovementEffects());
      final dispatcher = _CommitThenDropDispatcher(
        _acceptedAck(
          after: after,
          movementExecutions: _exactMovementExecutions(),
        ),
      );
      final repository = _Repository(_snapshot(before, offset: 0, turn: 1));
      final transport = _transport(
        dispatcher: dispatcher,
        reducer: reducer,
        repository: repository,
      );
      const command = SubmitTurnCommand('player_1');

      await expectLater(
        transport.dispatch(
          saveId: 'save_1',
          currentState: before,
          command: command,
        ),
        throwsA(isA<TimeoutException>()),
      );
      repository.snapshot = _snapshot(after, offset: 1, turn: 2);
      final retried = await transport.dispatch(
        saveId: 'save_1',
        currentState: after,
        command: command,
      );

      expect(dispatcher.commits, 1);
      expect(reducer.calls, 0);
      expect(retried.snapshot, isNotNull);
      expect(retried.movementExecutions, hasLength(3));
    });
  });
}

NetworkCommandTransport _transport({
  required WireCommandDispatcher dispatcher,
  required GameStateReducer reducer,
  required _Repository repository,
}) {
  return NetworkCommandTransport(
    commandDispatcher: dispatcher,
    token: AuthToken('jwt-token'),
    actorPlayerId: 'player_1',
    tickGenerator: ClientTickGenerator(startAt: 31),
    localReducer: reducer,
    gameRepository: repository,
  );
}

GameState _beforeState() {
  final unitA =
      GameUnit.produced(
        id: 'unit_a',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 0, row: 1, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 1, row: 1, enterCost: 1, cumulativeCost: 2),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 3),
          ],
        ),
      );
  final unitB = GameUnit.produced(
    id: 'unit_b',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: 0,
    row: 1,
  );
  return GameState(
    units: [unitA, unitB],
    activePlayerId: 'player_1',
    activePlayerCanAct: true,
  );
}

GameState _afterState() {
  final before = _beforeState();
  return before.copyWith(
    units: [
      before.units[0].copyWith(col: 2, row: 0).copyWithQueuedPath(null),
      before.units[1].copyWith(col: 1, row: 1),
    ],
  );
}

List<AnimateUnitMoveEffect> _localMovementEffects() {
  return const [
    AnimateUnitMoveEffect(
      unitId: 'unit_a',
      fromCol: 0,
      fromRow: 0,
      steps: [
        UnitMovementStep(col: 0, row: 1, enterCost: 1, cumulativeCost: 1),
        UnitMovementStep(col: 1, row: 1, enterCost: 1, cumulativeCost: 2),
        UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 3),
      ],
    ),
    AnimateUnitMoveEffect(
      unitId: 'unit_b',
      fromCol: 0,
      fromRow: 1,
      steps: [
        UnitMovementStep(col: 1, row: 1, enterCost: 1, cumulativeCost: 1),
      ],
    ),
  ];
}

WireMovementExecutionList _exactMovementExecutions() {
  return WireMovementExecutionList([
    _wireExecution('unit_a', 0, 0, 1, 0, enterCost: 7, cumulativeCost: 7),
    _wireExecution('unit_b', 0, 1, 1, 1, enterCost: 11, cumulativeCost: 11),
    _wireExecution('unit_a', 1, 0, 2, 0, enterCost: 13, cumulativeCost: 20),
  ]);
}

WireMovementExecution _wireExecution(
  String unitId,
  int fromCol,
  int fromRow,
  int toCol,
  int toRow, {
  required int enterCost,
  required int cumulativeCost,
}) {
  return WireMovementExecution(
    unitId: unitId,
    fromCol: fromCol,
    fromRow: fromRow,
    steps: [
      WireMovementStep(
        col: toCol,
        row: toRow,
        enterCost: enterCost,
        cumulativeCost: cumulativeCost,
      ),
    ],
  );
}

WireCommandAck _acceptedAck({
  required GameState after,
  required WireMovementExecutionList movementExecutions,
}) {
  const snapshotCodec = SnapshotCodec();
  return WireCommandAck(
    matchId: 'save_1',
    accepted: true,
    offset: 1,
    snapshot: snapshotCodec.toWire(
      matchId: 'save_1',
      snapshot: _snapshot(after, offset: 1, turn: 2),
    ),
    movementExecutions: movementExecutions,
  );
}

typedef _MovementSnapshot = (String, int, int, int, int, int, int);

_MovementSnapshot _movementSnapshot(MovementCommandExecution effect) {
  final step = effect.steps.single;
  return (
    effect.unitId,
    effect.fromCol,
    effect.fromRow,
    step.col,
    step.row,
    step.enterCost,
    step.cumulativeCost,
  );
}

final class _EffectReducer extends GameStateReducer {
  _EffectReducer(this.effects) : super(mapData: _map());

  final List<UiEffect> effects;
  var calls = 0;

  @override
  GameStateTransition reduce(
    GameState state,
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    calls += 1;
    return GameStateTransition(state: state, uiEffects: effects);
  }
}

final class _SentCommand {
  const _SentCommand({required this.wire, required this.clientMessageId});

  final WireCommand wire;
  final String clientMessageId;
}

typedef _AckHandler = FutureOr<WireCommandAck> Function(_SentCommand command);

class _ScriptedDispatcher implements WireCommandDispatcher {
  _ScriptedDispatcher(this.handler);

  final _AckHandler handler;
  final List<_SentCommand> sent = [];

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    final command = _SentCommand(wire: wire, clientMessageId: clientMessageId);
    sent.add(command);
    return handler(command);
  }
}

class _CommitThenDropDispatcher implements WireCommandDispatcher {
  _CommitThenDropDispatcher(this.ack);

  final WireCommandAck ack;
  final List<_SentCommand> sent = [];
  var commits = 0;

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    sent.add(_SentCommand(wire: wire, clientMessageId: clientMessageId));
    if (commits == 0) {
      commits += 1;
      throw TimeoutException('ACK was lost after commit');
    }
    return ack;
  }
}

final class _Repository implements GameRepository {
  _Repository(this.snapshot);

  SaveSnapshot snapshot;

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    return snapshot;
  }
}

SaveSnapshot _snapshot(
  GameState state, {
  required int offset,
  required int turn,
}) {
  return SaveSnapshot.fromGameState(
    save: _save(turn),
    state: state,
    eventLogOffset: offset,
  );
}

GameSave _save(int turn) {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
}

MapData _map() {
  return MapData(
    cols: 4,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
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
