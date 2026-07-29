import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';

/// Applies only client-owned interaction cleanup after an authoritative ACK.
///
/// Canonical game data always comes from the server snapshot. This projector
/// prevents migrated engine commands from being replayed through the legacy
/// reducer merely to update ephemeral selection and targeting state.
GameState acceptedEngineCommandInteractionSource({
  required GameState currentState,
  required DomainCommand command,
  required GameEngineCommandFamily family,
}) {
  return switch (family) {
    GameEngineCommandFamily.unitAction => _unitAction(currentState, command),
    GameEngineCommandFamily.movement => _movement(currentState, command),
    GameEngineCommandFamily.combat => _combat(currentState, command),
    GameEngineCommandFamily.city ||
    GameEngineCommandFamily.production ||
    GameEngineCommandFamily.worker ||
    GameEngineCommandFamily.artifactTrade => _cityEconomy(
      currentState,
      command,
    ),
  };
}

extension AcceptedNetworkCommandTransition on GameStateReducer {
  GameStateTransition acceptedNetworkCommandTransition(
    GameState currentState,
    DomainCommand command,
    GameCommandContext context,
  ) {
    final family = GameEngine.commandFamily(command);
    return switch (family) {
      GameEngineCommandFamily.unitAction ||
      GameEngineCommandFamily.movement ||
      GameEngineCommandFamily.combat ||
      GameEngineCommandFamily.city ||
      GameEngineCommandFamily.production ||
      GameEngineCommandFamily.worker ||
      GameEngineCommandFamily.artifactTrade => GameStateTransition(
        state: acceptedEngineCommandInteractionSource(
          currentState: currentState,
          command: command,
          family: family!,
        ),
      ),
      null => reduce(currentState, command, context: context),
    };
  }
}

GameState _cityEconomy(GameState state, DomainCommand command) {
  return switch (command) {
    FoundCityCommand(:final founderId) => _clearOwnedInteraction(
      state,
      founderId,
      clearDraft: true,
    ),
    SelectWorkerImprovementCommand(:final unitId) ||
    ConfirmWorkerImprovementCommand(:final unitId) ||
    AssignWorkerToHexCommand(:final unitId) => _clearOwnedInteraction(
      state,
      unitId,
      clearPending: true,
      clearMoveTargetingUnconditionally: true,
    ),
    StartArtifactExcavationCommand() ||
    StoreArtifactInCityCommand() ||
    TradeArtifactCommand() => state.copyWithInteraction(
      selection: null,
      movePreview: null,
      moveCommandActive: false,
    ),
    _ => state,
  };
}

GameState _unitAction(GameState state, DomainCommand command) {
  final unitId = switch (command) {
    SkipUnitTurnCommand(:final unitId) ||
    FortifyUnitCommand(:final unitId) => unitId,
    _ => '',
  };
  return _clearOwnedInteraction(state, unitId, clearPending: true);
}

GameState _movement(GameState state, DomainCommand command) {
  return switch (command) {
    MoveUnitCommand() => state.copyWithInteraction(movePreview: null),
    CancelUnitActionCommand(:final unitId) ||
    AutoExploreUnitCommand(
      :final unitId,
    ) => _clearOwnedInteraction(state, unitId),
    AssignMerchantTradeRouteCommand(:final unitId) ||
    MoveMerchantToCityCommand(:final unitId) => _clearOwnedInteraction(
      state,
      unitId,
      clearPending: true,
      clearDraft: true,
    ),
    DetachTroopCommand(:final unitId) => _clearOwnedInteraction(
      state,
      unitId,
      clearDraft: true,
    ),
    _ => state,
  };
}

GameState _combat(GameState state, DomainCommand command) {
  if (command case AttackHexCommand(:final attackerUnitId)) {
    return _clearOwnedInteraction(
      state,
      attackerUnitId,
      clearPending: true,
      clearDraft: true,
      clearMoveTargetingUnconditionally: true,
    );
  }
  return state;
}

GameState _clearOwnedInteraction(
  GameState state,
  String unitId, {
  bool clearPending = false,
  bool clearDraft = false,
  bool clearMoveTargetingUnconditionally = false,
}) {
  final pending = state.pendingAction;
  final ownsMoveTargeting = [
    clearMoveTargetingUnconditionally,
    state.selectedUnitId == unitId,
    state.movePreview?.unitId == unitId,
  ].contains(true);
  final shouldClearPending =
      clearPending && (pending?.ownsUnit(unitId) ?? false);
  final shouldClearDraft =
      clearDraft && state.cityFoundingDraft?.unitId == unitId;
  if (![
    ownsMoveTargeting,
    shouldClearPending,
    shouldClearDraft,
  ].contains(true)) {
    return state;
  }
  return state.copyWithInteraction(
    moveCommandActive: ownsMoveTargeting ? false : state.moveCommandActive,
    movePreview: ownsMoveTargeting ? null : state.movePreview,
    pendingAction: shouldClearPending ? null : pending,
    cityFoundingDraft: shouldClearDraft ? null : state.cityFoundingDraft,
  );
}
