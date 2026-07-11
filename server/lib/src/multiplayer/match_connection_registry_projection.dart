part of 'match_connection_registry.dart';

extension MatchConnectionRegistryProjection on MatchConnectionRegistry {
  void broadcast(
    MultiplayerServerMessage update, {
    MatchMessageTarget? except,
  }) {
    final subscribers = [
      for (final subscriber in List.of(
        _subscribers[update.matchId] ?? const <MatchMessageTarget>[],
      ))
        if (!identical(subscriber, except)) subscriber,
    ];
    if (subscribers.isEmpty) return;
    late final PreparedPlayerMatchMessage prepared;
    try {
      prepared = _viewProjector.prepareMessage(update);
    } catch (error, stackTrace) {
      for (final subscriber in subscribers) {
        _projectionFailed(subscriber, update, error, stackTrace);
      }
      return;
    }
    for (final subscriber in subscribers) {
      _sendPreparedTo(subscriber, prepared);
    }
  }

  void sendTo(MatchMessageTarget target, MultiplayerServerMessage message) {
    try {
      _sendPreparedTo(target, _viewProjector.prepareMessage(message));
    } catch (error, stackTrace) {
      _projectionFailed(target, message, error, stackTrace);
    }
  }

  void _sendPreparedTo(
    MatchMessageTarget target,
    PreparedPlayerMatchMessage prepared,
  ) {
    try {
      final projected = _viewProjector.projectMessage(
        prepared,
        target.recipient,
      );
      target._sink(projected.wire);
    } catch (error, stackTrace) {
      _projectionFailed(target, prepared.canonical, error, stackTrace);
    }
  }

  void _projectionFailed(
    MatchMessageTarget target,
    MultiplayerServerMessage message,
    Object error,
    StackTrace stackTrace,
  ) {
    target._operationalEvents.projectionFailed(
      matchId: message.matchId,
      surface: MultiplayerProjectionSurface.stream,
      error: error,
      stackTrace: stackTrace,
    );
    target._errorSink(
      multiplayerException(
        'snapshot_projection_failed',
        'Unable to project multiplayer state.',
      ),
      stackTrace,
    );
  }
}
