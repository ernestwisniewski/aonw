import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';

final class NetworkSessionTransportState {
  final NetworkSession? session;
  final String? transportSaveId;
  final NetworkConnectionState transportConnection;
  final String? transportMessage;

  const NetworkSessionTransportState({
    this.session,
    this.transportSaveId,
    this.transportConnection = NetworkConnectionState.offline,
    this.transportMessage,
  });

  static const initial = NetworkSessionTransportState();
}

sealed class NetworkSessionAction {
  const NetworkSessionAction();
}

final class ReplaceNetworkSessionAction extends NetworkSessionAction {
  final NetworkSession? session;

  const ReplaceNetworkSessionAction(this.session);
}

final class ActivateNetworkMatchAction extends NetworkSessionAction {
  final String expectedUserId;
  final String? playerId;
  final String matchId;
  final DateTime changedAt;
  final bool persistMatchId;

  const ActivateNetworkMatchAction({
    required this.expectedUserId,
    this.playerId,
    required this.matchId,
    required this.changedAt,
    this.persistMatchId = true,
  });
}

final class ClearNetworkMatchAction extends NetworkSessionAction {
  final String expectedUserId;
  final DateTime changedAt;

  const ClearNetworkMatchAction({
    required this.expectedUserId,
    required this.changedAt,
  });
}

final class RememberNetworkMatchAction extends NetworkSessionAction {
  final String matchId;

  const RememberNetworkMatchAction(this.matchId);
}

final class ReportNetworkTransportStatusAction extends NetworkSessionAction {
  final String saveId;
  final NetworkConnectionStatus status;
  final DateTime changedAt;
  final String? message;

  const ReportNetworkTransportStatusAction({
    required this.saveId,
    required this.status,
    required this.changedAt,
    this.message,
  });
}

sealed class NetworkSessionEffect {
  const NetworkSessionEffect();
}

final class PersistNetworkMatchIdEffect extends NetworkSessionEffect {
  final String? matchId;

  const PersistNetworkMatchIdEffect(this.matchId);
}

final class PublishNetworkTransportStatusEffect extends NetworkSessionEffect {
  final String saveId;
  final NetworkConnectionStatus status;
  final DateTime changedAt;
  final String? message;

  const PublishNetworkTransportStatusEffect({
    required this.saveId,
    required this.status,
    required this.changedAt,
    this.message,
  });
}

final class ClearNetworkTransportStatusEffect extends NetworkSessionEffect {
  final String saveId;

  const ClearNetworkTransportStatusEffect(this.saveId);
}

final class NetworkSessionTransition {
  final NetworkSessionTransportState state;
  final List<NetworkSessionEffect> effects;

  const NetworkSessionTransition({
    required this.state,
    this.effects = const [],
  });
}

final class NetworkSessionReducer {
  const NetworkSessionReducer();

  NetworkSessionTransition reduce(
    NetworkSessionTransportState current,
    NetworkSessionAction action,
  ) {
    return switch (action) {
      ReplaceNetworkSessionAction() => _replace(current, action.session),
      ActivateNetworkMatchAction() => _activateMatch(current, action),
      ClearNetworkMatchAction() => _clearMatch(current, action),
      RememberNetworkMatchAction() => _rememberMatch(current, action),
      ReportNetworkTransportStatusAction() => _reportTransport(current, action),
    };
  }

  NetworkSessionTransition _replace(
    NetworkSessionTransportState current,
    NetworkSession? session,
  ) {
    final matchId = session?.matchId;
    if (matchId != null && matchId == current.transportSaveId) {
      return NetworkSessionTransition(
        state: NetworkSessionTransportState(
          session: session,
          transportSaveId: current.transportSaveId,
          transportConnection: current.transportConnection,
          transportMessage: current.transportMessage,
        ),
      );
    }
    final effects = <NetworkSessionEffect>[
      if (current.transportSaveId != null)
        ClearNetworkTransportStatusEffect(current.transportSaveId!),
    ];
    return NetworkSessionTransition(
      state: NetworkSessionTransportState(
        session: session,
        transportSaveId: matchId,
        transportConnection:
            session?.connectionState ?? NetworkConnectionState.offline,
        transportMessage: session?.connectionState.lastError,
      ),
      effects: effects,
    );
  }

  NetworkSessionTransition _activateMatch(
    NetworkSessionTransportState current,
    ActivateNetworkMatchAction action,
  ) {
    final session = current.session;
    if (session == null || session.userId != action.expectedUserId) {
      return NetworkSessionTransition(state: current);
    }
    final connection = NetworkConnectionState(
      status: NetworkConnectionStatus.connected,
      changedAt: action.changedAt,
    );
    return NetworkSessionTransition(
      state: NetworkSessionTransportState(
        session: session.copyWith(
          playerId: action.playerId,
          matchId: action.matchId,
          connectionState: connection,
        ),
        transportSaveId: action.matchId,
        transportConnection: connection,
      ),
      effects: [
        PublishNetworkTransportStatusEffect(
          saveId: action.matchId,
          status: NetworkConnectionStatus.connected,
          changedAt: action.changedAt,
        ),
        if (action.persistMatchId) PersistNetworkMatchIdEffect(action.matchId),
      ],
    );
  }

  NetworkSessionTransition _clearMatch(
    NetworkSessionTransportState current,
    ClearNetworkMatchAction action,
  ) {
    final session = current.session;
    if (session == null || session.userId != action.expectedUserId) {
      return NetworkSessionTransition(state: current);
    }
    final clearedSaveId = session.matchId ?? current.transportSaveId;
    return NetworkSessionTransition(
      state: NetworkSessionTransportState(
        session: session.copyWith(
          playerId: null,
          matchId: null,
          connectionState: session.connectionState.copyWith(
            changedAt: action.changedAt,
          ),
        ),
        transportConnection: NetworkConnectionState(
          status: NetworkConnectionStatus.offline,
          changedAt: action.changedAt,
        ),
      ),
      effects: [
        if (clearedSaveId != null)
          ClearNetworkTransportStatusEffect(clearedSaveId),
        const PersistNetworkMatchIdEffect(null),
      ],
    );
  }

  NetworkSessionTransition _reportTransport(
    NetworkSessionTransportState current,
    ReportNetworkTransportStatusAction action,
  ) {
    if (current.session?.matchId != action.saveId) {
      return NetworkSessionTransition(state: current);
    }
    if (current.transportSaveId == action.saveId &&
        current.transportConnection.status == action.status &&
        current.transportMessage == action.message) {
      return NetworkSessionTransition(state: current);
    }
    final connection = NetworkConnectionState(
      status: action.status,
      lastError: action.message,
      changedAt: action.changedAt,
    );
    return NetworkSessionTransition(
      state: NetworkSessionTransportState(
        session: current.session,
        transportSaveId: action.saveId,
        transportConnection: connection,
        transportMessage: action.message,
      ),
      effects: [
        PublishNetworkTransportStatusEffect(
          saveId: action.saveId,
          status: action.status,
          changedAt: action.changedAt,
          message: action.message,
        ),
      ],
    );
  }

  NetworkSessionTransition _rememberMatch(
    NetworkSessionTransportState current,
    RememberNetworkMatchAction action,
  ) {
    if (current.session?.matchId != action.matchId) {
      return NetworkSessionTransition(state: current);
    }
    return NetworkSessionTransition(
      state: current,
      effects: [PersistNetworkMatchIdEffect(action.matchId)],
    );
  }
}

typedef NetworkMatchIdEffectWriter = Future<void> Function(String? matchId);
typedef NetworkTransportStatusEffectPublisher =
    void Function(PublishNetworkTransportStatusEffect effect);
typedef NetworkTransportStatusEffectClearer = void Function(String saveId);
typedef NetworkSessionEffectErrorHandler =
    void Function(Object error, StackTrace stackTrace);

final class NetworkSessionEffectRunner {
  final NetworkMatchIdEffectWriter persistMatchId;
  final NetworkTransportStatusEffectPublisher publishTransportStatus;
  final NetworkTransportStatusEffectClearer clearTransportStatus;
  final NetworkSessionEffectErrorHandler onError;
  Future<void> _persistenceQueue = Future<void>.value();

  NetworkSessionEffectRunner({
    required this.persistMatchId,
    required this.publishTransportStatus,
    required this.clearTransportStatus,
    required this.onError,
  });

  Future<void> runAll(Iterable<NetworkSessionEffect> effects) async {
    for (final effect in effects) {
      try {
        switch (effect) {
          case PersistNetworkMatchIdEffect():
            await _enqueuePersistence(effect.matchId);
          case PublishNetworkTransportStatusEffect():
            publishTransportStatus(effect);
          case ClearNetworkTransportStatusEffect():
            clearTransportStatus(effect.saveId);
        }
      } catch (error, stackTrace) {
        onError(error, stackTrace);
      }
    }
  }

  Future<void> _enqueuePersistence(String? matchId) {
    final next = _persistenceQueue.then(
      (_) => persistMatchId(matchId),
      onError: (_, _) => persistMatchId(matchId),
    );
    _persistenceQueue = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }
}
