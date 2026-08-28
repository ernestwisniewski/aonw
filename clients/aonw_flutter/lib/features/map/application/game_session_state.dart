import '../../research/application/research_state.dart';
import '../../turns/application/turn_action_state.dart';
import '../../turns/application/turn_presentation_queue.dart';
import '../read_model/map_scene.dart';
import '../read_model/player_map_view.dart';
import 'map_interaction_state.dart';

sealed class GameSessionState {
  const GameSessionState();
}

final class GameSessionLoading extends GameSessionState {
  const GameSessionLoading();
}

final class GameSessionReady extends GameSessionState {
  const GameSessionReady({
    required this.scene,
    required this.interaction,
    required this.turnPresentations,
    required this.turnAction,
    required this.research,
  });

  factory GameSessionReady.initial(MapScene scene) => GameSessionReady(
    scene: scene,
    interaction: const MapInteractionState(),
    turnPresentations: TurnPresentationQueue.start(scene.player.turn),
    turnAction: const TurnActionState(),
    research: ResearchState.loading(scene.player.stamp.revision),
  );

  final MapScene scene;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;
  final TurnActionState turnAction;
  final ResearchState research;

  PlayerMapView get recipient => scene.player;

  GameSessionReady withInteraction(MapInteractionState value) =>
      GameSessionReady(
        scene: scene,
        interaction: value,
        turnPresentations: turnPresentations,
        turnAction: turnAction,
        research: research,
      );

  GameSessionReady withRecipient(PlayerMapView value) {
    final identityChanged =
        value.stamp.revision != recipient.stamp.revision ||
        value.stamp.stateDigest != recipient.stamp.stateDigest;
    return GameSessionReady(
      scene: scene.withPlayer(value),
      interaction: interaction,
      turnPresentations: turnPresentations.observe(value.turn),
      turnAction: turnAction,
      research: identityChanged
          ? ResearchState.loading(value.stamp.revision)
          : research,
    );
  }

  GameSessionReady withTurnPresentations(TurnPresentationQueue value) =>
      GameSessionReady(
        scene: scene,
        interaction: interaction,
        turnPresentations: value,
        turnAction: turnAction,
        research: research,
      );

  GameSessionReady withTurnAction(TurnActionState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: value,
    research: research,
  );

  GameSessionReady withResearch(ResearchState value) => GameSessionReady(
    scene: scene,
    interaction: interaction,
    turnPresentations: turnPresentations,
    turnAction: turnAction,
    research: value,
  );

  GameSessionReady completeTurnPresentation() =>
      withTurnPresentations(turnPresentations.completeActive());
}

enum MapLoadFailureViewCode {
  adapterUnavailable,
  incompatibleClient,
  loadSuperseded,
  mapUnavailable,
}

final class GameSessionFailure extends GameSessionState {
  const GameSessionFailure({required this.code});

  final MapLoadFailureViewCode code;
}
