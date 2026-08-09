import 'package:aonw/game/application/ports/game_logger.dart';

/// Binds background session persistence failures to the game log.
void Function(Object, StackTrace) lobbySessionEffectErrorReporter(
  GameLogger logger,
) {
  return (error, stackTrace) => logger.warn(
    'LobbyNetworkSessionCoordinator',
    'Could not persist the active multiplayer match',
    error,
    stackTrace,
  );
}
