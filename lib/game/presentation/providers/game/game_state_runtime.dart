import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class GameStateBinding {
  const GameStateBinding({
    required Ref Function() readRef,
    required this.isMounted,
    required this.readState,
    required this.readStateFuture,
    required this.writeState,
  }) : _readRef = readRef;

  final Ref Function() _readRef;
  final bool Function() isMounted;
  final GameClientState? Function() readState;
  final Future<GameClientState> Function() readStateFuture;
  final void Function(GameClientState state) writeState;

  Ref get ref => _readRef();
}

final class GameStateRuntime {
  String saveId = '';
  int eventLogOffset = 0;
  DispatchCommandUseCase? dispatchCommand;
  GameStateReducer? reducer;
  LiveMultiplayerEventHandle? liveEvents;
  Future<LiveMultiplayerEventHandle?>? liveEventsStarting;
}
