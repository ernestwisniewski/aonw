part of 'live_event_subscription.dart';

class _LocalCommandEchoGuard {
  static const _ttl = Duration(seconds: 10);
  static const _maxKeys = 128;

  final Queue<_LocalCommandEchoKey> _keys = Queue();

  void remember(WireCommand wire) {
    _prune();
    _keys.addLast(
      _LocalCommandEchoKey(
        matchId: wire.matchId,
        actorPlayerId: wire.actorPlayerId,
        tick: wire.tick,
        rememberedAt: DateTime.now(),
      ),
    );
    while (_keys.length > _maxKeys) {
      _keys.removeFirst();
    }
  }

  bool isLocalEcho(WireEvent event) {
    _prune();
    for (final key in _keys) {
      if (key.matches(event)) return true;
    }
    return false;
  }

  void clear() => _keys.clear();

  void _prune() {
    final cutoff = DateTime.now().subtract(_ttl);
    while (_keys.isNotEmpty && _keys.first.rememberedAt.isBefore(cutoff)) {
      _keys.removeFirst();
    }
  }
}

class _LocalCommandEchoKey {
  const _LocalCommandEchoKey({
    required this.matchId,
    required this.actorPlayerId,
    required this.tick,
    required this.rememberedAt,
  });

  final String matchId;
  final String actorPlayerId;
  final int tick;
  final DateTime rememberedAt;

  bool matches(WireEvent event) {
    return event.matchId == matchId &&
        event.actorPlayerId == actorPlayerId &&
        event.tick == tick;
  }
}
