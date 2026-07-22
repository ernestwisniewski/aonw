import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_resolver.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/diplomacy/persistent_diplomacy_result.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Persistence adapter for the state-neutral diplomacy command resolver.
class PersistentDiplomacyResolver {
  const PersistentDiplomacyResolver();

  static PersistentDiplomacyResult resolve({
    required PersistentGameState state,
    required DiplomaticCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    return _apply(
      state,
      DiplomacyCommandResolver.resolve(
        state: _commandState(state),
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
    );
  }

  PersistentDiplomacyResult sendProposal({
    required PersistentGameState state,
    required SendDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) => PersistentDiplomacyResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );

  PersistentDiplomacyResult respondProposal({
    required PersistentGameState state,
    required RespondDiplomaticProposalCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) => PersistentDiplomacyResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );

  PersistentDiplomacyResult declareWar({
    required PersistentGameState state,
    required DeclareWarCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) => PersistentDiplomacyResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );

  PersistentDiplomacyResult sendGoldGift({
    required PersistentGameState state,
    required SendGoldGiftCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) => PersistentDiplomacyResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );

  PersistentDiplomacyResult sendMessage({
    required PersistentGameState state,
    required SendDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) => PersistentDiplomacyResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );

  PersistentDiplomacyResult respondMessage({
    required PersistentGameState state,
    required RespondDiplomaticMessageCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) => PersistentDiplomacyResolver.resolve(
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    turn: turn,
    canAct: canAct,
  );

  static DiplomacyCommandState _commandState(PersistentGameState state) {
    return DiplomacyCommandState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.runtimeState.diplomacy,
      intendedAttacks: state.runtimeState.intendedAttacks,
      resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
    );
  }

  static PersistentDiplomacyResult _apply(
    PersistentGameState state,
    DiplomacyCommandResult result,
  ) {
    if (!result.accepted) {
      return PersistentDiplomacyResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return PersistentDiplomacyResult(
      accepted: true,
      state: _applyAccepted(state, result),
      events: result.events,
    );
  }

  static PersistentGameState _applyAccepted(
    PersistentGameState state,
    DiplomacyCommandResult result,
  ) {
    final runtimeState = _applyRuntime(state, result);
    final goldChanged = !identical(result.playerGold, state.playerGold);
    if (!goldChanged && identical(runtimeState, state.runtimeState)) {
      return state;
    }
    return state.copyWith(
      playerGold: goldChanged ? result.playerGold : null,
      runtimeState: identical(runtimeState, state.runtimeState)
          ? null
          : runtimeState,
    );
  }

  static GameRuntimeState _applyRuntime(
    PersistentGameState state,
    DiplomacyCommandResult result,
  ) {
    final runtime = state.runtimeState;
    final diplomacyChanged = !identical(result.diplomacy, runtime.diplomacy);
    final attacksChanged = !identical(
      result.intendedAttacks,
      runtime.intendedAttacks,
    );
    final tradesChanged = !identical(
      result.resourceTradeAgreements,
      runtime.resourceTradeAgreements,
    );
    if (!diplomacyChanged && !attacksChanged && !tradesChanged) return runtime;
    return runtime.copyWith(
      diplomacy: diplomacyChanged ? result.diplomacy : null,
      intendedAttacks: attacksChanged ? result.intendedAttacks : null,
      resourceTradeAgreements: tradesChanged
          ? result.resourceTradeAgreements
          : null,
    );
  }
}
