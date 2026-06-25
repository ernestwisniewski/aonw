import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

class HandoffPresentation {
  final GameCommand command;
  final GameState state;
  final GameState? previousState;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;

  const HandoffPresentation({
    required this.command,
    required this.state,
    required this.uiEffects,
    required this.events,
    this.previousState,
  });

  bool get hasNotifications => events.isNotEmpty;

  bool get hasRendererEffects => uiEffects.rendererEffects.isNotEmpty;
}

class HandoffData {
  final String playerId;
  final String playerName;
  final int playerColorValue;
  final int turnNumber;
  final bool freshTurn;

  const HandoffData({
    required this.playerId,
    required this.playerName,
    required this.playerColorValue,
    required this.turnNumber,
    this.freshTurn = false,
  });
}
