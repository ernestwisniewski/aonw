import 'package:aonw/game/application/services/client_interaction_ownership.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';

GameClientState projectLocalCombatEngineResult({
  required GameClientState currentState,
  required GameEngineAccepted result,
  required AttackHexCommand command,
  required String actorPlayerId,
}) {
  final interactionSource =
      ClientInteractionOwnership.actorMayProject(
        state: currentState,
        actorPlayerId: actorPlayerId,
      )
      ? _clearCommandOwnedInteraction(currentState, command.attackerUnitId)
      : currentState;
  return MultiplayerInteractionReconciler.reconcile(
    authoritativeState: GameClientState.fromDomain(
      domain: result.snapshot.domain,
      activePlayerId: interactionSource.activePlayerId,
      activePlayerCanAct: interactionSource.activePlayerCanAct,
    ),
    interactionSource: interactionSource,
  );
}

GameClientState _clearCommandOwnedInteraction(
  GameClientState state,
  String attackerUnitId,
) {
  final ownsMoveTargeting =
      state.selectedUnitId == attackerUnitId ||
      state.movePreview?.unitId == attackerUnitId;
  final pending = state.pendingAction;
  final clearPending = pending?.ownsUnit(attackerUnitId) ?? false;
  final draft = state.cityFoundingDraft;
  final clearDraft = draft?.unitId == attackerUnitId;
  if (!ownsMoveTargeting && !clearPending && !clearDraft) return state;
  return state.copyWithInteraction(
    movePreview: ownsMoveTargeting ? null : state.movePreview,
    cityFoundingDraft: clearDraft ? null : draft,
    pendingAction: clearPending ? null : pending,
    moveCommandActive: ownsMoveTargeting ? false : state.moveCommandActive,
  );
}
