import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

class HandoffPresentation {
  final DomainCommand command;
  final GameState state;
  final GameState? previousState;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;
  final List<CombatAnimationFact> combatAnimations;
  final List<MovementCommandExecution> movementExecutions;
  final int offset;
  final String interactionId;

  const HandoffPresentation({
    required this.command,
    required this.state,
    required this.uiEffects,
    required this.events,
    this.combatAnimations = const [],
    this.movementExecutions = const [],
    this.offset = 0,
    this.interactionId = '',
    this.previousState,
  });

  bool get hasNotifications => events.isNotEmpty;

  bool get hasRendererEffects =>
      uiEffects.rendererEffects.isNotEmpty ||
      events.isNotEmpty ||
      movementExecutions.isNotEmpty;
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
