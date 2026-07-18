import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';

abstract final class ArtifactReducer {
  static GameStateTransition startExcavation(
    GameState state,
    StartArtifactExcavationCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final result = ArtifactCommandResolver.startExcavation(
      units: state.units,
      artifacts: state.artifacts,
      command: command,
      actorPlayerId: _actorPlayerId(state, context),
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: _afterAcceptedArtifactCommand(
        state.copyWith(units: result.units, artifacts: result.artifacts),
      ),
    );
  }

  static GameStateTransition storeInCity(
    GameState state,
    StoreArtifactInCityCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final result = ArtifactCommandResolver.storeInCity(
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      command: command,
      actorPlayerId: _actorPlayerId(state, context),
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: _afterAcceptedArtifactCommand(
        state.copyWith(units: result.units, artifacts: result.artifacts),
      ),
    );
  }

  static GameStateTransition tradeArtifact(
    GameState state,
    TradeArtifactCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final result = ArtifactCommandResolver.tradeArtifact(
      cities: state.cities,
      artifacts: state.artifacts,
      playerGold: state.playerGold,
      diplomacy: state.diplomacy,
      command: command,
      actorPlayerId: _actorPlayerId(state, context),
    );
    if (!result.accepted) return GameStateTransition(state: state);
    return GameStateTransition(
      state: _afterAcceptedArtifactCommand(
        state.copyWith(
          artifacts: result.artifacts,
          playerGold: result.playerGold,
        ),
      ),
    );
  }

  static String _actorPlayerId(GameState state, GameCommandContext context) {
    return context.actorPlayerId ?? state.activePlayerId;
  }

  static GameState _afterAcceptedArtifactCommand(GameState state) {
    return state.copyWithInteraction(
      selection: null,
      movePreview: null,
      moveCommandActive: false,
    );
  }
}
