import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;
import 'package:url_launcher/url_launcher.dart';

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

class CreateMatchRequest {
  final String name;
  final String mapName;
  final int maxPlayers;
  final String? displayName;
  final PlayerCountry? country;
  final MatchRules matchRules;
  final List<CreateMatchAiPlayer> aiPlayers;

  const CreateMatchRequest({
    required this.name,
    required this.mapName,
    required this.maxPlayers,
    this.displayName,
    this.country,
    this.matchRules = MatchRules.standard,
    this.aiPlayers = const [],
  });
}

class CreateMatchAiPlayer {
  final String? name;
  final PlayerCountry? country;
  final AiStrategyId strategyId;
  final AiDifficulty difficulty;
  final AiPersona persona;

  const CreateMatchAiPlayer({
    this.name,
    this.country,
    this.strategyId = AiStrategyId.random,
    this.difficulty = AiDifficulty.normal,
    this.persona = AiPersona.balanced,
  });
}

class QuickplayMatchRequest {
  final String mapName;
  final String? displayName;
  final PlayerCountry? country;
  final MatchRules matchRules;

  const QuickplayMatchRequest({
    required this.mapName,
    this.displayName,
    this.country,
    this.matchRules = MatchRules.standard,
  });
}

class CreatePrivateMatchRequest {
  final String mapName;
  final String? displayName;
  final PlayerCountry? country;
  final MatchRules matchRules;

  const CreatePrivateMatchRequest({
    required this.mapName,
    this.displayName,
    this.country,
    this.matchRules = MatchRules.standard,
  });
}

class JoinPrivateMatchRequest {
  final String inviteCode;
  final String? displayName;
  final PlayerCountry? country;

  const JoinPrivateMatchRequest({
    required this.inviteCode,
    this.displayName,
    this.country,
  });
}

class NetworkSessionClient {
  final String serverpodHost;

  NetworkSessionClient({required this.serverpodHost});

  Future<String> versionStatus({
    required String platform,
    required int buildNumber,
  }) {
    return _client(
      connectionTimeout: const Duration(seconds: 3),
    ).appStatus.versionStatus(platform: platform, buildNumber: buildNumber);
  }

  Future<NetworkAuthResult> login({
    required String email,
    required String password,
  }) async {
    final auth = await _client().emailIdp.login(
      email: email,
      password: password,
    );
    return _authResult(auth);
  }

  Future<NetworkAuthResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    final auth = await _client().emailIdp.createAccount(
      email: email,
      password: password,
      displayName: normalizedDisplayName,
    );
    return _authResult(auth, displayName: normalizedDisplayName);
  }

  Future<String> displayName({required AuthToken token}) {
    return _withToken(token, (client) => client.emailIdp.displayName());
  }

  Future<String> updateDisplayName({
    required AuthToken token,
    required String displayName,
  }) {
    return _withToken(
      token,
      (client) => client.emailIdp.updateDisplayName(displayName: displayName),
    );
  }

  Future<AuthToken> refresh({required String refreshToken}) async {
    final auth = await _client().jwtRefresh.refreshAccessToken(
      refreshToken: refreshToken,
    );
    return AuthToken(auth.token, expiresAt: auth.tokenExpiresAt);
  }

  Future<NetworkAuthResult> completeSocialAuth({
    required sp_auth.AuthSuccess auth,
  }) async {
    final token = AuthToken(auth.token, expiresAt: auth.tokenExpiresAt);
    final displayName = await _withToken(
      token,
      (client) => client.accountProfile.ensureAccount(),
    );
    return _authResult(auth, displayName: displayName);
  }

  Future<NetworkAuthResult> loginWithSteam() async {
    final client = _client();
    final start = await client.steamAuth.start();
    final opened = await launchUrl(
      Uri.parse(start.authUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw StateError('Could not open Steam sign-in.');
    }

    while (DateTime.now().toUtc().isBefore(start.expiresAt.toUtc())) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final poll = await client.steamAuth.poll(requestId: start.requestId);
      final auth = poll.auth;
      if (auth != null) {
        return completeSocialAuth(auth: auth);
      }
      if (poll.status != 'pending') {
        throw StateError('Steam sign-in failed: ${poll.error ?? poll.status}');
      }
    }

    throw StateError('Steam sign-in expired.');
  }

  Future<List<WireMatch>> listMatches({
    required AuthToken token,
    String? status,
  }) {
    return _withToken(token, (client) => client.multiplayer.listMatches());
  }

  Future<WireMatch> createMatch({
    required AuthToken token,
    required CreateMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.createMatch(
        sp.CreateMatchRequest(
          name: request.name,
          mapName: request.mapName,
          maxPlayers: request.maxPlayers,
          minPlayers: request.maxPlayers,
          private: false,
          countryId: request.country?.name,
        ),
      ),
    );
  }

  Future<WireMatch> quickplay({
    required AuthToken token,
    required QuickplayMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.quickplay(
        sp.CreateMatchRequest(
          name: 'Quickplay',
          mapName: request.mapName,
          maxPlayers: 4,
          minPlayers: 2,
          private: false,
          countryId: request.country?.name,
        ),
      ),
    );
  }

  Future<WireMatch> createPrivateMatch({
    required AuthToken token,
    required CreatePrivateMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.createMatch(
        sp.CreateMatchRequest(
          name: 'Private match',
          mapName: request.mapName,
          maxPlayers: MapPlayerCapacityRules.maxPlayersForMapName(
            request.mapName,
          ),
          minPlayers: 2,
          private: true,
          countryId: request.country?.name,
        ),
      ),
    );
  }

  Future<WireMatch> joinPrivateMatch({
    required AuthToken token,
    required JoinPrivateMatchRequest request,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.joinPrivateMatch(
        request.inviteCode,
        request.country?.name,
      ),
    );
  }

  Future<WireMatch> joinMatch({
    required AuthToken token,
    required String matchId,
    String? displayName,
    PlayerCountry? country,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.joinMatch(matchId, country?.name),
    );
  }

  Future<void> leaveMatch({required AuthToken token, required String matchId}) {
    return _withToken(
      token,
      (client) => client.multiplayer.leaveMatch(matchId),
    );
  }

  Future<WireMatch> startMatch({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.startMatch(matchId),
    );
  }

  Future<WireMatch> markMapLoaded({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.markMapLoaded(matchId),
    );
  }

  Future<WireMatch> resignMatch({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.resignMatch(matchId),
    );
  }

  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(token, (client) => client.multiplayer.loadMatch(matchId));
  }

  sp.Client _client({AuthToken? token, Duration? connectionTimeout}) {
    return createServerpodClient(
      serverpodHost,
      token: token,
      connectionTimeout: connectionTimeout,
    );
  }

  Future<T> _withToken<T>(
    AuthToken token,
    Future<T> Function(sp.Client client) run,
  ) {
    return run(_client(token: token));
  }

  Future<NetworkAuthResult> _authResult(
    sp_auth.AuthSuccess auth, {
    String? displayName,
  }) async {
    final token = AuthToken(auth.token, expiresAt: auth.tokenExpiresAt);
    final resolvedDisplayName =
        displayName ?? await this.displayName(token: token);
    return NetworkAuthResult(
      userId: auth.authUserId.toString(),
      token: token,
      displayName: resolvedDisplayName,
      refreshToken: auth.refreshToken,
    );
  }

  String _normalizeDisplayName(String displayName) {
    return displayName.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
