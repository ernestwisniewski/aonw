part of 'game_event_descriptor.dart';

GameEventDescriptor artifactGameEventDescriptor(ArtifactLifecycleEvent event) =>
    GameEventDescriptor._(
      activityWorthy: false,
      messageGroup: GameEventMessageGroup.system,
      playerIds: [event.ownerPlayerId],
    );

GameEventDescriptor _stabilityBandDescriptor(
  String playerId,
  StabilityBand newBand,
) {
  return GameEventDescriptor._(
    activityWorthy: true,
    messageGroup: GameEventMessageGroup.turn,
    criticalNotification:
        newBand == StabilityBand.strained || newBand == StabilityBand.unrest,
    playerIds: [playerId],
  );
}
