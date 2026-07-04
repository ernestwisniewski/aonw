import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';

abstract final class ArtifactReducer {
  static GameStateTransition startExcavation(
    GameState state,
    StartArtifactExcavationCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = _actorPlayerId(state, context);
    final result = const PersistentArtifactCommandResolver().startExcavation(
      state: state.toPersistentState(),
      command: command,
      actorPlayerId: actorPlayerId,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static GameStateTransition storeInCity(
    GameState state,
    StoreArtifactInCityCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = _actorPlayerId(state, context);
    final result = const PersistentArtifactCommandResolver().storeInCity(
      state: state.toPersistentState(),
      command: command,
      actorPlayerId: actorPlayerId,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static GameStateTransition tradeArtifact(
    GameState state,
    TradeArtifactCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final actorPlayerId = _actorPlayerId(state, context);
    final result = const PersistentArtifactCommandResolver().tradeArtifact(
      state: state.toPersistentState(),
      command: command,
      actorPlayerId: actorPlayerId,
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(state: _fromPersistent(state, result.state));
  }

  static String _actorPlayerId(GameState state, GameCommandContext context) {
    return context.actorPlayerId ?? state.activePlayerId;
  }

  static GameState _fromPersistent(
    GameState state,
    PersistentGameState persistent,
  ) {
    return state.copyWith(
      playerColors: persistent.playerColors,
      playerCountries: persistent.playerCountries,
      playerGold: persistent.playerGold,
      playerWarWeariness: persistent.playerWarWeariness,
      playerStabilityNet: persistent.playerStabilityNet,
      units: persistent.units,
      cities: persistent.cities,
      artifacts: persistent.artifacts,
      fieldImprovements: persistent.fieldImprovements,
      fogOfWar: persistent.fogOfWar,
      research: persistent.research,
      diplomacy: persistent.runtimeState.diplomacy,
      submittedPlayerIds: persistent.runtimeState.submittedPlayerIds,
      intendedAttacks: persistent.runtimeState.intendedAttacks,
      resourceTradeAgreements: persistent.runtimeState.resourceTradeAgreements,
      dominationHoldTurnsByPlayerId:
          persistent.runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          persistent.runtimeState.culturalVictoryHoldTurnsByPlayerId,
      interaction: GameInteractionState(
        cityFoundingDraft: persistent.runtimeState.cityFoundingDraft,
        pendingAction: persistent.runtimeState.pendingAction,
      ),
    );
  }
}
