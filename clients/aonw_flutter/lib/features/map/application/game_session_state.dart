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
  const GameSessionReady({required this.scene, required this.interaction});

  final MapScene scene;
  final MapInteractionState interaction;

  PlayerMapView get recipient => scene.player;

  GameSessionReady withInteraction(MapInteractionState value) =>
      GameSessionReady(scene: scene, interaction: value);

  GameSessionReady withRecipient(PlayerMapView value) => GameSessionReady(
    scene: scene.withPlayer(value),
    interaction: interaction,
  );
}

final class GameSessionFailure extends GameSessionState {
  const GameSessionFailure({required this.code, required this.message});

  final String code;
  final String message;
}
