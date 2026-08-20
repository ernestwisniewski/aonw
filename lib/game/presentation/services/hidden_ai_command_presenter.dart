import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

typedef HiddenAiCommandDispatch =
    Future<DispatchCommandResult> Function(
      DomainCommand command, {
      required GameCommandContext context,
    });
typedef HiddenAiPresentationGuard = bool Function();

final class HiddenAiCommandPresenter {
  final HiddenAiCommandDispatch dispatchTransition;
  final HiddenAiRendererPlayback rendererPlayback;
  final HiddenAiPresentationGuard canPresent;

  HiddenAiCommandPresenter({
    required this.dispatchTransition,
    required HiddenAiRendererStateReader rendererStateReader,
    required HiddenAiLocalizationReader localizationReader,
    required HiddenAiProjectedTransitionApplier applyProjectedTransition,
    this.canPresent = _alwaysPresent,
  }) : rendererPlayback = HiddenAiRendererPlayback(
         rendererStateReader: rendererStateReader,
         localizationReader: localizationReader,
         applyProjectedTransition: applyProjectedTransition,
       );

  const HiddenAiCommandPresenter.withPlayback({
    required this.dispatchTransition,
    required this.rendererPlayback,
    this.canPresent = _alwaysPresent,
  });

  Future<DispatchCommandResult> dispatchAndPresent({
    String sourceId = 'hidden-ai-preview',
    required GameClientState currentState,
    required DomainCommand command,
    required GameCommandContext context,
  }) async {
    final previousRendererState = canPresent()
        ? rendererPlayback.previousRendererState(currentState)
        : currentState;
    final result = await dispatchTransition(command, context: context);

    if (!canPresent()) {
      return _resultWithActionContext(result, currentState);
    } else if (!_isTerminalCommand(command)) {
      await rendererPlayback.playCommandEffects(
        previousRendererState: previousRendererState,
        commandState: result.state,
        uiEffects: result.uiEffects,
        events: result.events,
        sourceId: sourceId,
        eventOffset: result.offset,
        authoritativeTick: result.authoritativeTick,
        authoritativeStartMicrosUtc: result.authoritativeStartMicrosUtc,
        movementExecutions: result.movementExecutions,
        turn: _eventTurnFor(result),
      );
    } else {
      await rendererPlayback.playCommandEffects(
        previousRendererState: previousRendererState,
        commandState: result.state,
        uiEffects: const [],
        events: result.movementExecutions.isEmpty
            ? const []
            : result.events.whereType<UnitMovedEvent>(),
        sourceId: sourceId,
        eventOffset: result.offset,
        authoritativeTick: result.authoritativeTick,
        authoritativeStartMicrosUtc: result.authoritativeStartMicrosUtc,
        movementExecutions: result.movementExecutions,
        turn: _eventTurnFor(result),
      );
    }

    return _resultWithActionContext(result, currentState);
  }

  static DispatchCommandResult _resultWithActionContext(
    DispatchCommandResult result,
    GameClientState currentState,
  ) {
    return DispatchCommandResult(
      state: HiddenAiRendererPlayback.withActionContext(
        result.state,
        currentState,
      ),
      uiEffects: result.uiEffects,
      events: result.events,
      combatAnimations: result.combatAnimations,
      movementExecutions: result.movementExecutions,
      snapshot: result.snapshot,
      offset: result.offset,
      authoritativeTick: result.authoritativeTick,
      authoritativeStartMicrosUtc: result.authoritativeStartMicrosUtc,
      storedSnapshot: result.storedSnapshot,
    );
  }

  static bool _isTerminalCommand(DomainCommand command) => switch (command) {
    EndTurnCommand() || SubmitTurnCommand() => true,
    _ => false,
  };

  static int? _eventTurnFor(DispatchCommandResult result) {
    for (final event in result.events) {
      final completedTurn = GameEventDescriptor.forEvent(event).completedTurn;
      if (completedTurn != null) return completedTurn;
    }
    return result.snapshot?.domain.turn;
  }
}

bool _alwaysPresent() => true;
