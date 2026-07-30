part of 'network_command_transport.dart';

extension _NetworkCommandTransportClientInteraction on NetworkCommandTransport {
  Future<CommandTransportResult> _dispatchClientOnly({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    required GameCommandContext context,
  }) async {
    final resolution = resolveClientIntent(
      localReducer,
      currentState,
      command,
      context,
    );
    final offset = _lastKnownOffsetBySaveId[saveId] ?? -1;
    return CommandTransportResult(
      state: resolution.state,
      uiEffects: resolution.uiEffects,
      events: const [],
      snapshot: null,
      offset: offset,
    );
  }
}
