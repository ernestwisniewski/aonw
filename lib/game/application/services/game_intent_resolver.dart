import 'package:aonw/game/application/services/authoritative_command_policy.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer_taps.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment_dispatch.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment_interaction_dispatch.dart';
import 'package:aonw/game/domain/reducer/interaction/interaction_reducer.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';

/// The presentation-only result of resolving a [GameIntent].
///
/// [interaction] is the only local state owned by the intent. A tap may also
/// confirm an already prepared authoritative command, but that command is
/// returned separately and must still pass through `GameEngine`.
final class GameIntentResolution {
  const GameIntentResolution({
    required this.interaction,
    this.domainCommand,
    this.presentationFocus = const [],
  });

  final GameInteractionState interaction;
  final DomainCommand? domainCommand;
  final List<UiEffect> presentationFocus;
}

final class ClientInteractionResolution {
  const ClientInteractionResolution({
    required this.state,
    required this.uiEffects,
  });

  final GameState state;
  final List<UiEffect> uiEffects;
}

ClientInteractionResolution resolveClientIntent(
  GameStateReducer reducer,
  GameState currentState,
  GameIntent intent,
  GameCommandContext context,
) {
  final resolver = GameIntentResolver(reducer: reducer, context: context);
  final resolution = resolver.resolve(
    currentState.interaction,
    intent,
    currentState,
  );
  return ClientInteractionResolution(
    state: resolution.interaction == currentState.interaction
        ? currentState
        : currentState.copyWith(interaction: resolution.interaction),
    uiEffects: resolution.presentationFocus,
  );
}

/// Resolves map interaction without entering persistence or player wire.
final class GameIntentResolver {
  const GameIntentResolver({
    required this.reducer,
    this.context = const GameCommandContext(),
  });

  final GameStateReducer reducer;
  final GameCommandContext context;

  GameIntentResolution resolve(
    GameInteractionState interaction,
    GameIntent intent,
    GameState view,
  ) {
    final state = view.copyWith(interaction: interaction);
    final authoritative =
        AuthoritativeCommandPolicy.authoritativeCommandForClientIntent(
          state,
          intent,
          context,
        );
    final environment = ReducerEnvironment(
      mapData: reducer.mapData,
      ruleset: reducer.ruleset,
      context: context,
    );
    final transition = _resolveInteraction(state, intent, environment);
    final nextInteraction = transition.state.interaction == interaction
        ? interaction
        : transition.state.interaction;
    return GameIntentResolution(
      interaction: nextInteraction,
      domainCommand: authoritative,
      presentationFocus: List<UiEffect>.unmodifiable(transition.uiEffects),
    );
  }

  GameIntentResolution resolveWorkerImprovementChoice(
    GameInteractionState interaction,
    ChooseWorkerImprovementIntent command,
    GameState view,
  ) {
    final state = view.copyWith(interaction: interaction);
    return GameIntentResolution(
      interaction: InteractionReducer.selectWorkerImprovement(
        state,
        command,
      ).interaction,
    );
  }

  GameStateTransition _resolveInteraction(
    GameState state,
    GameIntent intent,
    ReducerEnvironment environment,
  ) {
    return switch (intent) {
      TileTappedCommand() => GameIntentTapResolver.handleTileTapped(
        state,
        intent,
        environment,
      ),
      CityTappedCommand() => GameIntentTapResolver.handleCityTapped(
        state,
        intent,
        environment,
      ),
      StartMerchantTradeRouteSelectionCommand() =>
        environment.startMerchantTradeRouteSelection(state, intent),
      CancelMerchantTradeRouteSelectionCommand() =>
        environment.cancelMerchantTradeRouteSelection(state, intent),
      _ => _resolveModeInteraction(state, intent, environment),
    };
  }

  GameStateTransition _resolveModeInteraction(
    GameState state,
    GameIntent intent,
    ReducerEnvironment environment,
  ) {
    return switch (intent) {
      StartMerchantMoveToCitySelectionCommand() =>
        environment.startMerchantMoveToCitySelection(state, intent),
      CancelMerchantMoveToCitySelectionCommand() =>
        environment.cancelMerchantMoveToCitySelection(state, intent),
      CancelResearchSelectionCommand() => environment.cancelResearchSelection(
        state,
        intent,
      ),
      ToggleMoveTargetingCommand() => GameStateTransition(
        state: MovementReducer.toggleMoveTargetingWithEnvironment(
          state,
          environment,
        ),
      ),
      StartCityFoundingCommand() => environment.startCityFounding(state),
      CancelCityFoundingCommand() => environment.cancelCityFounding(state),
      StartCityWorkedHexSelectionCommand() =>
        environment.startCityWorkedHexSelection(state, intent),
      CancelCityWorkedHexSelectionCommand() =>
        environment.cancelCityWorkedHexSelection(state, intent),
      _ => _resolveRemainingInteraction(state, intent, environment),
    };
  }

  GameStateTransition _resolveRemainingInteraction(
    GameState state,
    GameIntent intent,
    ReducerEnvironment environment,
  ) {
    return switch (intent) {
      StartCityExpansionSelectionCommand() =>
        environment.startCityExpansionSelection(state, intent),
      CancelCityExpansionSelectionCommand() =>
        environment.cancelCityExpansionSelection(state, intent),
      StartWorkerActionSelectionCommand() ||
      CancelWorkerActionSelectionCommand() => environment.workerInteraction(
        state,
        intent,
      ),
      ChooseWorkerImprovementIntent() => _resolveWorkerImprovementChoice(
        state,
        intent,
      ),
      ConfirmWorkerImprovementIntent() => GameStateTransition(state: state),
      StartAttackTargetingCommand() => environment.startAttackTargeting(
        state,
        intent,
      ),
      CancelAttackTargetingCommand() => environment.cancelAttackTargeting(
        state,
        intent,
      ),
      StartCommanderMergeSelectionCommand() =>
        environment.startCommanderMergeSelection(state, intent),
      CancelCommanderMergeSelectionCommand() =>
        environment.cancelCommanderMergeSelection(state, intent),
      _ => _resolveSelectionInteraction(state, intent, environment),
    };
  }

  GameStateTransition _resolveWorkerImprovementChoice(
    GameState state,
    ChooseWorkerImprovementIntent intent,
  ) {
    final nextInteraction = resolveWorkerImprovementChoice(
      state.interaction,
      intent,
      state,
    ).interaction;
    return GameStateTransition(
      state: nextInteraction == state.interaction
          ? state
          : state.copyWith(interaction: nextInteraction),
    );
  }

  GameStateTransition _resolveSelectionInteraction(
    GameState state,
    GameIntent intent,
    ReducerEnvironment environment,
  ) {
    return switch (intent) {
      SelectTileCommand() => environment.selectTile(state, intent),
      SelectUnitCommand() => GameIntentTapResolver.handleUnitSelected(
        state,
        intent,
        environment,
      ),
      SelectCityCommand() => environment.selectCity(state, intent),
      FocusNextPendingActionCommand() => environment.focusNextPendingAction(
        state,
        intent,
      ),
      FocusTurnStartActionCommand() => environment.focusTurnStartAction(
        state,
        intent,
      ),
      _ => throw UnsupportedError(
        '${intent.runtimeType} has no GameIntentResolver handler',
      ),
    };
  }
}
