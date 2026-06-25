import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

class DispatchCommandResult {
  final GameState state;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;
  final SaveSnapshot? snapshot;
  final int offset;
  final bool storedSnapshot;

  const DispatchCommandResult({
    required this.state,
    this.uiEffects = const [],
    this.events = const [],
    this.snapshot,
    this.offset = 0,
    this.storedSnapshot = false,
  });
}

class DispatchCommandUseCase {
  final CommandTransport commandTransport;

  const DispatchCommandUseCase({required this.commandTransport});

  Future<DispatchCommandResult> execute({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final result = await commandTransport.dispatch(
      saveId: saveId,
      currentState: currentState,
      command: command,
      context: context,
    );
    return DispatchCommandResult(
      state: result.state,
      uiEffects: result.uiEffects,
      events: result.events,
      snapshot: result.snapshot,
      offset: result.offset,
      storedSnapshot: result.storedSnapshot,
    );
  }
}
