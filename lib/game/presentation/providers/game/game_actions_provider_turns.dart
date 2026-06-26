part of 'game_actions_provider.dart';

GameState? _currentGameStateFor(Ref ref) {
  if (!ref.mounted) return null;
  final session = ref.read(activeGameSessionProvider);
  if (session == null || session.saveId.isEmpty) return null;
  return ref.read(gameStateProvider(session.saveId)).value;
}

int? _currentSaveTurnFor(Ref ref) {
  if (!ref.mounted) return null;
  final session = ref.read(activeGameSessionProvider);
  if (session == null || session.saveId.isEmpty) return null;
  return ref.read(gameSaveProvider(session.saveId)).value?.turn;
}

extension GameCommandControllerTurnContext on GameCommandController {
  int? _turnFor(DispatchCommandResult result) =>
      result.snapshot?.save.turn ?? _currentSaveTurn();

  int? _eventTurnFor(DispatchCommandResult result) {
    for (final event in result.events) {
      if (event is AllPlayersSubmittedEvent) return event.turn;
    }
    return _turnFor(result);
  }
}
