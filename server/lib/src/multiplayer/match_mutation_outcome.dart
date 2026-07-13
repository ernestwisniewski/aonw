import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_connection_registry.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';

final class MatchMutationOutcome<T> {
  const MatchMutationOutcome(
    this.value, {
    this.notifications = const MatchNotificationPlan.empty(),
  });

  final T value;
  final MatchNotificationPlan notifications;

  MatchMutationOutcome<R> withValue<R>(R value) {
    return MatchMutationOutcome(value, notifications: notifications);
  }
}

final class MatchNotificationPlan {
  const MatchNotificationPlan.empty() : _notifications = const [];

  const MatchNotificationPlan._(this._notifications);

  factory MatchNotificationPlan.broadcastMessage(
    MultiplayerServerMessage message, {
    MatchMessageTarget? except,
  }) {
    return MatchNotificationPlan._([
      _BroadcastMessageNotification(message, except: except),
    ]);
  }

  factory MatchNotificationPlan.broadcastState(StoredMatchState state) {
    return MatchNotificationPlan._([_BroadcastStateNotification(state)]);
  }

  factory MatchNotificationPlan.directMessage(
    MultiplayerServerMessage message, {
    required MatchMessageTarget recipient,
  }) {
    return MatchNotificationPlan._([
      _DirectMessageNotification(message, recipient),
    ]);
  }

  final List<_MatchNotification> _notifications;

  MatchNotificationPlan followedBy(MatchNotificationPlan other) {
    if (_notifications.isEmpty) return other;
    if (other._notifications.isEmpty) return this;
    return MatchNotificationPlan._([
      ..._notifications,
      ...other._notifications,
    ]);
  }

  void deliver(MatchBroadcaster broadcaster) {
    for (final notification in _notifications) {
      notification.deliver(broadcaster);
    }
  }
}

sealed class _MatchNotification {
  const _MatchNotification();

  void deliver(MatchBroadcaster broadcaster);
}

final class _BroadcastMessageNotification extends _MatchNotification {
  const _BroadcastMessageNotification(this.message, {this.except});

  final MultiplayerServerMessage message;
  final MatchMessageTarget? except;

  @override
  void deliver(MatchBroadcaster broadcaster) {
    broadcaster.broadcast(message, except: except);
  }
}

final class _BroadcastStateNotification extends _MatchNotification {
  const _BroadcastStateNotification(this.state);

  final StoredMatchState state;

  @override
  void deliver(MatchBroadcaster broadcaster) {
    broadcaster.broadcastState(state);
  }
}

final class _DirectMessageNotification extends _MatchNotification {
  const _DirectMessageNotification(this.message, this.recipient);

  final MultiplayerServerMessage message;
  final MatchMessageTarget recipient;

  @override
  void deliver(MatchBroadcaster broadcaster) {
    broadcaster.sendTo(recipient, message);
  }
}
