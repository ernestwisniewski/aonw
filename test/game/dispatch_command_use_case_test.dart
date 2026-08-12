import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DispatchCommandUseCase', () {
    test('delegates command dispatch to CommandTransport', () async {
      final transport = _FakeCommandTransport(
        state: GameClientState(activePlayerId: 'player_1'),
        uiEffects: const [JumpCameraEffect(col: 2, row: 3)],
        events: const [TurnEndedEvent(playerId: 'player_1')],
      );
      final useCase = DispatchCommandUseCase(commandTransport: transport);

      final result = await useCase.execute(
        saveId: 'save_1',
        currentState: GameClientState(),
        command: const EndTurnCommand('player_1'),
        context: const GameCommandContext(actorPlayerId: 'player_1'),
      );

      expect(result.state.activePlayerId, 'player_1');
      expect(result.uiEffects.single, isA<JumpCameraEffect>());
      expect(result.events.single, isA<TurnEndedEvent>());
      expect(result.accepted, isTrue);
      expect(transport.saveId, 'save_1');
      expect(transport.command, isA<EndTurnCommand>());
      expect(transport.context.actorPlayerId, 'player_1');
    });

    test('preserves typed command rejection metadata', () async {
      final useCase = DispatchCommandUseCase(
        commandTransport: _FakeCommandTransport(
          state: GameClientState(),
          accepted: false,
          rejectionReason: 'unit_production_missing_strategic_resource',
        ),
      );

      final result = await useCase.execute(
        saveId: 'save_1',
        currentState: GameClientState(),
        command: const StartUnitProductionCommand('city_1', GameUnitType.tank),
      );

      expect(result.accepted, isFalse);
      expect(
        result.rejectionReason,
        'unit_production_missing_strategic_resource',
      );
    });
  });
}

class _FakeCommandTransport implements CommandTransport {
  final GameClientState state;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;
  final bool accepted;
  final String? rejectionReason;

  late String saveId;
  late DomainCommand command;
  late GameCommandContext context;

  _FakeCommandTransport({
    required this.state,
    this.uiEffects = const [],
    this.events = const [],
    this.accepted = true,
    this.rejectionReason,
  });

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  }) async {
    this.saveId = saveId;
    this.command = command;
    this.context = context;

    return CommandTransportResult(
      state: state,
      uiEffects: uiEffects,
      events: events,
      snapshot: GameSnapshotFactory.create(save: _save()),
      offset: 1,
      accepted: accepted,
      rejectionReason: rejectionReason,
    );
  }
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
}
