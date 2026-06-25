import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

class CommandTransportResult {
  final GameState state;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;
  final SaveSnapshot snapshot;
  final int offset;
  final bool storedSnapshot;

  const CommandTransportResult({
    required this.state,
    required this.snapshot,
    required this.offset,
    this.uiEffects = const [],
    this.events = const [],
    this.storedSnapshot = false,
  });
}

abstract interface class CommandTransport {
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  });
}
