import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/protocol.dart';

class NetworkAuthResult {
  final String userId;
  final AuthToken token;
  final String? refreshToken;
  final String displayName;

  const NetworkAuthResult({
    required this.userId,
    required this.token,
    required this.displayName,
    this.refreshToken,
  });

  NetworkSession toSession({DateTime? changedAt}) {
    return NetworkSession(
      userId: userId,
      token: token,
      refreshToken: refreshToken,
      connectionState: NetworkConnectionState(
        status: NetworkConnectionStatus.connected,
        changedAt: changedAt,
      ),
    );
  }

  StoredNetworkSession? toStoredSession({required String displayName}) {
    final refresh = refreshToken;
    if (refresh == null || refresh.isEmpty) return null;
    return StoredNetworkSession(
      userId: userId,
      refreshToken: refresh,
      displayName: displayName,
    );
  }
}

class NetworkSessionRefreshResult {
  final AuthToken token;
  final String refreshToken;

  const NetworkSessionRefreshResult({
    required this.token,
    required this.refreshToken,
  });
}

class CreateMatchRequest {
  final String name;
  final String mapName;
  final int maxPlayers;
  final int minPlayers;
  final PlayerCountry? country;

  const CreateMatchRequest({
    required this.name,
    required this.mapName,
    required this.maxPlayers,
    this.minPlayers = MapPlayerCapacityRules.minPlayers,
    this.country,
  });
}

class QuickplayMatchRequest {
  final PlayerCountry? country;

  const QuickplayMatchRequest({this.country});
}

class CreatePrivateMatchRequest {
  final String mapName;
  final PlayerCountry? country;

  const CreatePrivateMatchRequest({required this.mapName, this.country});
}

class JoinPrivateMatchRequest {
  final String inviteCode;
  final PlayerCountry? country;

  const JoinPrivateMatchRequest({required this.inviteCode, this.country});
}

/// Application boundary for authentication and multiplayer lobby operations.
abstract interface class MultiplayerSessionGateway {
  bool get isClosed;

  Future<NetworkAuthResult> login({
    required String email,
    required String password,
  });

  Future<NetworkAuthResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  });

  Future<String> displayName({required AuthToken token});

  Future<String> updateDisplayName({
    required AuthToken token,
    required String displayName,
  });

  Future<NetworkSessionRefreshResult> refresh({required String refreshToken});

  Future<void> signOutCurrentSession({AuthToken? token, String? refreshToken});

  Future<NetworkAuthResult> loginWithSteam();

  Future<NetworkAuthResult> completeNativeSocialAuth({
    required Object authSuccess,
  });

  Future<NetworkAuthResult> loginWithExternalProvider({
    required String provider,
  });

  Future<String> versionStatus({
    required String platform,
    required int buildNumber,
    required int multiplayerVersion,
  });

  Future<List<WireMatch>> listMatches({required AuthToken token});

  Future<WireMatch> createMatch({
    required AuthToken token,
    required CreateMatchRequest request,
  });

  Future<WireMatch> quickplay({
    required AuthToken token,
    required QuickplayMatchRequest request,
  });

  Future<WireMatch> createPrivateMatch({
    required AuthToken token,
    required CreatePrivateMatchRequest request,
  });

  Future<WireMatch> joinPrivateMatch({
    required AuthToken token,
    required JoinPrivateMatchRequest request,
  });

  Future<WireMatch> joinMatch({
    required AuthToken token,
    required String matchId,
    PlayerCountry? country,
  });

  Future<void> leaveMatch({required AuthToken token, required String matchId});

  Future<WireMatch> startMatch({
    required AuthToken token,
    required String matchId,
  });

  Future<WireMatch> markMapLoaded({
    required AuthToken token,
    required String matchId,
  });

  Future<WireMatch> resignMatch({
    required AuthToken token,
    required String matchId,
  });

  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  });

  void close();
}
