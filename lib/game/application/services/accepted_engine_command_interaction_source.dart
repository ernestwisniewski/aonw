import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Applies only client-owned interaction cleanup after an authoritative ACK.
///
/// Canonical game data always comes from the server snapshot. This projector
/// prevents authoritative commands from being replayed through an interaction
/// reducer merely to update ephemeral selection and targeting state.
GameClientState acceptedEngineCommandInteractionSource({
  required GameClientState currentState,
  required DomainCommand command,
  required GameEngineCommandFamily family,
  required DomainActionState domainActions,
}) {
  final projected = currentState.domain.actions == domainActions
      ? currentState
      : currentState.copyWithInteraction(
          cityFoundingDraft: domainActions.cityFoundingDraft,
          pendingAction: domainActions.pendingAction,
        );
  return switch (family) {
    GameEngineCommandFamily.unitAction => _unitAction(projected, command),
    GameEngineCommandFamily.movement => _movement(projected, command),
    GameEngineCommandFamily.combat => _combat(projected, command),
    _ => _acceptedStrategicInteractionSource(
      currentState: projected,
      command: command,
      family: family,
    ),
  };
}

GameClientState _acceptedStrategicInteractionSource({
  required GameClientState currentState,
  required DomainCommand command,
  required GameEngineCommandFamily family,
}) {
  return switch (family) {
    GameEngineCommandFamily.city ||
    GameEngineCommandFamily.production ||
    GameEngineCommandFamily.worker ||
    GameEngineCommandFamily.artifactTrade => _cityEconomy(
      currentState,
      command,
    ),
    GameEngineCommandFamily.research || GameEngineCommandFamily.diplomacy =>
      _researchDiplomacy(currentState, command),
    _ => currentState,
  };
}

extension AcceptedNetworkCommandTransition on GameStateReducer {
  GameStateTransition acceptedNetworkCommandTransition(
    GameClientState currentState,
    DomainCommand command,
    GameCommandContext context,
  ) {
    final family = GameEngine.commandFamily(command);
    if (family == null) {
      throw StateError(
        '${command.runtimeType} has no canonical GameEngine family.',
      );
    }
    return GameStateTransition(
      state: acceptedEngineCommandInteractionSource(
        currentState: currentState,
        command: command,
        family: family,
        domainActions: currentState.domain.actions,
      ),
    );
  }
}

GameClientState _researchDiplomacy(
  GameClientState state,
  DomainCommand command,
) {
  if (command case SelectTechnologyCommand(:final playerId)) {
    final pending = state.pendingAction;
    if (pending is PendingResearchSelection &&
        pending.ownerPlayerId == playerId) {
      return state.copyWithInteraction(pendingAction: null);
    }
  }
  return state;
}

GameClientState _cityEconomy(GameClientState state, DomainCommand command) {
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

GameClientState _unitAction(GameClientState state, DomainCommand command) {
  return switch (command) {
    SkipUnitTurnCommand(:final unitId) => _clearOwnedInteraction(state, unitId),
    FortifyUnitCommand(:final unitId) => _clearOwnedInteraction(
      state,
      unitId,
      clearPending: true,
    ),
    _ => state,
  };
}

GameClientState _movement(GameClientState state, DomainCommand command) {
  return switch (command) {
    MoveUnitCommand() => state.copyWithInteraction(movePreview: null),
    CancelUnitActionCommand(:final unitId) ||
    AutomatedUnitCommand(:final unitId) => _clearOwnedInteraction(
      state,
      unitId,
      clearPending: true,
      clearDraft: true,
    ),
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

GameClientState _combat(GameClientState state, DomainCommand command) {
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

GameClientState _clearOwnedInteraction(
  GameClientState state,
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
