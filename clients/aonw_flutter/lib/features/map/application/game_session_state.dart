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
  });

  factory GameSessionReady.initial(MapScene scene) => GameSessionReady(
    scene: scene,
    interaction: const MapInteractionState(),
    turnPresentations: TurnPresentationQueue.start(scene.player.turn),
  );

  final MapScene scene;
  final MapInteractionState interaction;
  final TurnPresentationQueue turnPresentations;

  PlayerMapView get recipient => scene.player;

  GameSessionReady withInteraction(MapInteractionState value) =>
      GameSessionReady(
        scene: scene,
        interaction: value,
        turnPresentations: turnPresentations,
      );

  GameSessionReady withRecipient(PlayerMapView value) => GameSessionReady(
    scene: scene.withPlayer(value),
    interaction: interaction,
    turnPresentations: turnPresentations.observe(value.turn),
  );

  GameSessionReady withTurnPresentations(TurnPresentationQueue value) =>
      GameSessionReady(
        scene: scene,
        interaction: interaction,
        turnPresentations: value,
      );
}

final class GameSessionFailure extends GameSessionState {
  const GameSessionFailure({required this.code, required this.message});

  final String code;
  final String message;
}
