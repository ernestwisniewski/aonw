import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_connection.dart';

/// Authenticated multiplayer identity independent from the wire transport.
class NetworkSession {
  final String userId;
  final String? playerId;
  final AuthToken token;
  final String? refreshToken;
  final String? matchId;
  final NetworkConnectionState connectionState;

  const NetworkSession({
    required this.userId,
    this.playerId,
    required this.token,
    this.refreshToken,
    this.matchId,
    this.connectionState = NetworkConnectionState.offline,
  });

  bool get isConnected => connectionState.isConnected;

  NetworkSession copyWith({
    String? userId,
    Object? playerId = _undefined,
    AuthToken? token,
    Object? refreshToken = _undefined,
    Object? matchId = _undefined,
    NetworkConnectionState? connectionState,
  }) {
    return NetworkSession(
      userId: userId ?? this.userId,
      playerId: identical(playerId, _undefined)
          ? this.playerId
          : playerId as String?,
      token: token ?? this.token,
      refreshToken: identical(refreshToken, _undefined)
          ? this.refreshToken
          : refreshToken as String?,
      matchId: identical(matchId, _undefined)
          ? this.matchId
          : matchId as String?,
      connectionState: connectionState ?? this.connectionState,
    );
  }
}

bool canUseNetworkMatchTransport({
  required NetworkSession? session,
  required String saveId,
}) {
  return saveId.isNotEmpty &&
      session != null &&
      session.isConnected &&
      session.matchId == saveId &&
      session.playerId?.trim().isNotEmpty == true;
}

const Object _undefined = Object();
