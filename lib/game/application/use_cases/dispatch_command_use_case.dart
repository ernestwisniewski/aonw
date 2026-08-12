import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state.dart';

class DispatchCommandResult {
  final GameClientState state;
  final List<UiEffect> uiEffects;
  final List<GameEvent> events;
  final List<CombatAnimationFact> combatAnimations;
  final List<MovementCommandExecution> movementExecutions;
  final CanonicalGameSnapshot? snapshot;
  final int offset;
  final int authoritativeTick;
  final int authoritativeStartMicrosUtc;
  final bool storedSnapshot;
  final bool accepted;
  final String? rejectionReason;

  DispatchCommandResult({
    required this.state,
    this.uiEffects = const [],
    this.events = const [],
    this.combatAnimations = const [],
    this.movementExecutions = const [],
    this.snapshot,
    this.offset = 0,
    int? authoritativeTick,
    int? authoritativeStartMicrosUtc,
    this.storedSnapshot = false,
    this.accepted = true,
    this.rejectionReason,
  }) : authoritativeTick = authoritativeTick ?? offset,
       authoritativeStartMicrosUtc =
           authoritativeStartMicrosUtc ??
           (authoritativeTick ?? offset) * Duration.microsecondsPerSecond;
}

class DispatchCommandUseCase {
  final CommandTransport commandTransport;

  const DispatchCommandUseCase({required this.commandTransport});

  Future<DispatchCommandResult> execute({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  }) async {
    final result = await commandTransport.dispatch(
      saveId: saveId,
      currentState: currentState,
      command: command,
      context: context,
      fromMovePreviewConfirmation: fromMovePreviewConfirmation,
    );
    return DispatchCommandResult(
      state: result.state,
      uiEffects: result.uiEffects,
      events: result.events,
      combatAnimations: result.combatAnimations,
      movementExecutions: result.movementExecutions,
      snapshot: result.snapshot,
      offset: result.offset,
      authoritativeTick: result.authoritativeTick,
      authoritativeStartMicrosUtc: result.authoritativeStartMicrosUtc,
      storedSnapshot: result.storedSnapshot,
      accepted: result.accepted,
      rejectionReason: result.rejectionReason,
    );
  }
}
