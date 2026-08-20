import 'package:aonw/game/domain/game_state.dart';

/// Defines whether a command actor may mutate the viewer-owned interaction.
abstract final class ClientInteractionOwnership {
  static bool actorMayProject({
    required GameClientState state,
    required String actorPlayerId,
  }) =>
      actorPlayerId.isEmpty ||
      state.activePlayerId.isEmpty ||
      actorPlayerId == state.activePlayerId;
}
