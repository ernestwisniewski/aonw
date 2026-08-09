import 'dart:async';

import 'package:aonw/api/session/external_auth_browser.dart';
import 'package:aonw/api/session/serverpod_auth_client.dart';
import 'package:aonw/api/session/serverpod_multiplayer_failure_mapper.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

part 'network_session_client_lobby_requests.dart';
part 'network_session_client_support.dart';
part 'network_session_client_version_status.dart';

typedef NetworkSessionServerpodClientFactory =
    sp.Client Function(
      String host, {
      AuthToken? token,
      sp.ClientAuthKeyProvider? authKeyProvider,
      Duration? connectionTimeout,
    });

/// Owns the Serverpod clients used by authentication and lobby requests.
///
/// Call [close] when the client leaves its application scope. Authenticated
/// calls share one refresh-aware client when [authKeyProviderFactory] is
/// available. Explicit one-off credentials are isolated in short-lived clients
/// that are always closed after the request settles.
class NetworkSessionClient extends _NetworkSessionLobbyRequests
    implements MultiplayerSessionGateway {
  final String serverpodHost;
  final ServerpodAuthKeyProviderFactory? authKeyProviderFactory;
  final NetworkSessionServerpodClientFactory _clientFactory;
  final ExternalAuthBrowserFactory _externalAuthBrowserFactory;
  final Duration _externalAuthPollInterval;
  sp.Client? _anonymousClient;
  sp.Client? _authenticatedClient;
  _ExternalAuthOperation? _externalAuthOperation;
  var _externalAuthGeneration = 0;
  var _closed = false;

  NetworkSessionClient({
    required this.serverpodHost,
    this.authKeyProviderFactory,
    NetworkSessionServerpodClientFactory? clientFactory,
    ExternalAuthBrowserFactory? externalAuthBrowserFactory,
    Duration externalAuthPollInterval = const Duration(seconds: 1),
  }) : _clientFactory = clientFactory ?? createServerpodClient,
       _externalAuthBrowserFactory =
           externalAuthBrowserFactory ?? prepareExternalAuthBrowser,
       _externalAuthPollInterval = externalAuthPollInterval;

  @override
  bool get isClosed => _closed;

  @override
  Future<NetworkAuthResult> login({
    required String email,
    required String password,
  }) async {
    final auth = await _withAnonymousClient(
      (client) => client.emailIdp.login(email: email, password: password),
    );
    return _authResult(auth);
  }

  @override
  Future<NetworkAuthResult> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    final auth = await _withAnonymousClient(
      (client) => client.emailIdp.createAccount(
        email: email,
        password: password,
        displayName: normalizedDisplayName,
      ),
    );
    return _authResult(auth, displayName: normalizedDisplayName);
  }

  @override
  Future<String> displayName({required AuthToken token}) {
    return _withToken(token, (client) => client.emailIdp.displayName());
  }

  @override
  Future<String> updateDisplayName({
    required AuthToken token,
    required String displayName,
  }) {
    return _withToken(
      token,
      (client) => client.emailIdp.updateDisplayName(displayName: displayName),
    );
  }

  @override
  Future<NetworkSessionRefreshResult> refresh({
    required String refreshToken,
  }) async {
    final auth = await _withAnonymousClient(
      (client) =>
          client.jwtRefresh.refreshAccessToken(refreshToken: refreshToken),
    );
    final rotatedRefreshToken = auth.refreshToken;
    if (rotatedRefreshToken == null || rotatedRefreshToken.isEmpty) {
      throw StateError('Server did not return a rotated refresh token.');
    }
    return NetworkSessionRefreshResult(
      token: AuthToken(auth.token, expiresAt: auth.tokenExpiresAt),
      refreshToken: rotatedRefreshToken,
    );
  }

  /// Revokes the current server-side session when enough credentials remain.
  ///
  /// The refresh token is preferred because it still works after the
  /// short-lived access token expires. Clients without one can fall back to
  /// Serverpod Auth's current-device sign-out endpoint.
  @override
  Future<void> signOutCurrentSession({
    AuthToken? token,
    String? refreshToken,
  }) async {
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _withAnonymousClient(
        (client) =>
            client.authStatus.signOutRefreshToken(refreshToken: refreshToken),
      );
      return;
    }
    if (token == null || token.value.isEmpty) return;
    await _withExplicitToken(
      token,
      (client) => client.modules.serverpod_auth_core.status.signOutDevice(),
    );
  }

  @override
  Future<NetworkAuthResult> completeNativeSocialAuth({
    required Object authSuccess,
  }) async {
    if (authSuccess is! sp_auth.AuthSuccess) {
      throw ArgumentError.value(
        authSuccess,
        'authSuccess',
        'Expected Serverpod AuthSuccess',
      );
    }
    final auth = authSuccess;
    final token = AuthToken(auth.token, expiresAt: auth.tokenExpiresAt);
    final displayName = await _withExplicitToken(
      token,
      (client) => client.accountProfile.ensureAccount(),
    );
    return _authResult(auth, displayName: displayName);
  }

  @override
  Future<NetworkAuthResult> loginWithSteam() {
    return _loginWithExternalBrowser(
      signInName: 'Steam',
      pendingStatuses: const {'pending'},
      start: (client) async {
        final start = await client.steamAuth.start();
        return (
          requestId: start.requestId,
          authUrl: start.authUrl,
          expiresAt: start.expiresAt,
        );
      },
      poll: (client, requestId) async {
        final poll = await client.steamAuth.poll(requestId: requestId);
        return (status: poll.status, auth: poll.auth, error: poll.error);
      },
    );
  }

  @override
  Future<NetworkAuthResult> loginWithExternalProvider({
    required String provider,
  }) async {
    if (provider != 'apple' && provider != 'google') {
      throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
    }
    return _loginWithExternalBrowser(
      signInName: provider,
      pendingStatuses: const {'pending', 'processing'},
      start: (client) async {
        final start = await client.externalAuth.start(provider: provider);
        return (
          requestId: start.requestId,
          authUrl: start.authUrl,
          expiresAt: start.expiresAt,
        );
      },
      poll: (client, requestId) async {
        final poll = await client.externalAuth.poll(requestId: requestId);
        return (status: poll.status, auth: poll.auth, error: poll.error);
      },
    );
  }

  @override
  Future<String> versionStatus({
    required String platform,
    required int buildNumber,
    required int multiplayerVersion,
  }) {
    return loadNetworkSessionVersionStatus(
      this,
      platform: platform,
      buildNumber: buildNumber,
      multiplayerVersion: multiplayerVersion,
    );
  }

  @override
  Future<List<WireMatch>> listMatches({required AuthToken token}) {
    return _withToken(
      token,
      (client) => client.multiplayer.listMatches(
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  @override
  Future<void> leaveMatch({required AuthToken token, required String matchId}) {
    return _withToken(
      token,
      (client) => client.multiplayer.leaveMatch(
        matchId,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  @override
  Future<WireMatch> startMatch({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.startMatch(
        matchId,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  @override
  Future<WireMatch> markMapLoaded({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.markMapLoaded(
        matchId,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  @override
  Future<WireMatch> resignMatch({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.resignMatch(
        matchId,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  @override
  Future<WireMatch> loadMatch({
    required AuthToken token,
    required String matchId,
  }) {
    return _withToken(
      token,
      (client) => client.multiplayer.loadMatch(
        matchId,
        multiplayerVersion: kCurrentMultiplayerVersion,
      ),
    );
  }

  @override
  Future<T> _withToken<T>(
    AuthToken token,
    Future<T> Function(sp.Client client) run,
  ) async {
    try {
      if (authKeyProviderFactory != null) {
        return await run(_activeAuthenticatedClient);
      }
      return await _withOwnedClient(token: token, run: run);
    } catch (error, stackTrace) {
      throwMappedServerpodMultiplayerFailure(error, stackTrace);
    }
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _externalAuthGeneration += 1;
    _externalAuthOperation?.cancel();
    _externalAuthOperation = null;
    _anonymousClient?.close();
    _anonymousClient = null;
    _authenticatedClient?.close();
    _authenticatedClient = null;
  }

  Future<NetworkAuthResult> _authResult(
    sp_auth.AuthSuccess auth, {
    String? displayName,
  }) async {
    final token = AuthToken(auth.token, expiresAt: auth.tokenExpiresAt);
    final String resolvedDisplayName =
        displayName ??
        await _withExplicitToken<String>(
          token,
          (client) => client.emailIdp.displayName(),
        );
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
