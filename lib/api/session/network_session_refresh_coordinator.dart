import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/connection_state.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as sp_auth;

typedef NetworkSessionReader = NetworkSession? Function();
typedef NetworkSessionWriter = void Function(NetworkSession? session);
typedef NetworkSessionClock = DateTime Function();
typedef NetworkSessionTokenRefresher =
    Future<NetworkSessionRefreshResult> Function({
      required String refreshToken,
    });
typedef NetworkSessionRevoker =
    Future<void> Function({AuthToken? token, String? refreshToken});

/// Owns refresh-token rotation for every multiplayer transport.
///
/// Concurrent expiry checks and 401 recoveries share one refresh operation.
/// A rotated refresh token is persisted before the new access token becomes
/// visible to callers, so a process interruption cannot leave transports using
/// credentials that were never saved.
final class NetworkSessionRefreshCoordinator {
  static const tokenRefreshSkew = Duration(seconds: 30);

  final NetworkSessionReader currentSession;
  final NetworkSessionWriter setSession;
  final NetworkSessionStore sessionStore;
  final NetworkSessionTokenRefresher refreshToken;
  final NetworkSessionClock now;

  Future<NetworkSession>? _refreshInFlight;
  Future<void>? _terminationInFlight;
  var _generation = 0;
  var _terminating = false;

  NetworkSessionRefreshCoordinator({
    required this.currentSession,
    required this.setSession,
    required this.sessionStore,
    required this.refreshToken,
    required this.now,
  });

  /// Returns the latest usable access token, refreshing proactively near
  /// expiry.
  Future<AuthToken> currentToken() async {
    return (await ensureValidSession()).token;
  }

  /// Returns a usable session and optionally forces refresh-token rotation.
  Future<NetworkSession> ensureValidSession({bool forceRefresh = false}) async {
    if (_terminating) throw const NetworkSessionUnavailableException();
    final current = currentSession();
    if (!forceRefresh && current != null && !_needsRefresh(current.token)) {
      return current;
    }
    return _refreshSingleFlight(forceRefresh: forceRefresh);
  }

  /// Recovers a request rejected with 401.
  ///
  /// [rejectedToken] identifies the credential used by that request. If a
  /// concurrent request already replaced it, the replacement is reused rather
  /// than rotating the refresh token again.
  Future<NetworkSession> refreshAfterUnauthorized(
    AuthToken? rejectedToken,
  ) async {
    if (_terminating) throw const NetworkSessionUnavailableException();
    final current = currentSession();
    if (current != null &&
        rejectedToken != null &&
        current.token.value != rejectedToken.value &&
        !_needsRefresh(current.token)) {
      return current;
    }
    return _refreshSingleFlight(forceRefresh: true);
  }

  /// Ends the local session and fences out any refresh already in flight.
  Future<void> terminateSession() {
    return _terminateSingleFlight(_performLocalTermination);
  }

  /// Waits for an already-started rotation, revokes its newest credential,
  /// then clears the local session. New refreshes are rejected while logout is
  /// settling, so an old refresh secret cannot leave a rotated server session
  /// behind.
  Future<void> revokeAndTerminate(NetworkSessionRevoker revoke) {
    return _terminateSingleFlight(() => _performRemoteTermination(revoke));
  }

  Future<void> _terminateSingleFlight(Future<void> Function() operation) async {
    final pending = _terminationInFlight;
    if (pending != null) return pending;

    final started = operation();
    _terminationInFlight = started;
    try {
      await started;
    } finally {
      if (identical(_terminationInFlight, started)) {
        _terminationInFlight = null;
      }
    }
  }

  Future<void> _performLocalTermination() async {
    _terminating = true;
    _generation += 1;
    try {
      await _endSession();
    } finally {
      _terminating = false;
    }
  }

  Future<void> _performRemoteTermination(NetworkSessionRevoker revoke) async {
    _terminating = true;
    final initial = currentSession();
    try {
      NetworkSession? refreshed;
      final pendingRefresh = _refreshInFlight;
      if (pendingRefresh != null) {
        try {
          refreshed = await pendingRefresh;
        } catch (_) {
          // Revoke the pre-refresh credential when rotation itself failed.
        }
      }

      final latest = refreshed ?? currentSession();
      var latestRefreshToken = latest?.refreshToken;
      if (latestRefreshToken == null || latestRefreshToken.isEmpty) {
        try {
          latestRefreshToken = (await sessionStore.load())?.refreshToken;
        } catch (_) {
          // Fall back to the in-memory credential captured at logout start.
        }
      }
      if (latestRefreshToken == null || latestRefreshToken.isEmpty) {
        latestRefreshToken = initial?.refreshToken;
      }

      _generation += 1;
      await revoke(
        token: latest?.token ?? initial?.token,
        refreshToken: latestRefreshToken,
      );
    } finally {
      _generation += 1;
      await _endSession();
      _terminating = false;
    }
  }

  Future<NetworkSession> _refreshSingleFlight({
    required bool forceRefresh,
  }) async {
    if (_terminating) throw const NetworkSessionUnavailableException();
    final current = currentSession();
    if (!forceRefresh && current != null && !_needsRefresh(current.token)) {
      return current;
    }

    final pending = _refreshInFlight;
    if (pending != null) return pending;

    final started = _performRefresh();
    _refreshInFlight = started;
    try {
      return await started;
    } finally {
      if (identical(_refreshInFlight, started)) _refreshInFlight = null;
    }
  }

  Future<NetworkSession> _performRefresh() async {
    final refreshGeneration = _generation;
    final current = currentSession();
    StoredNetworkSession? stored;
    try {
      stored = await sessionStore.load();
    } catch (error, stackTrace) {
      await _endSession();
      Error.throwWithStackTrace(
        NetworkSessionRefreshFailedException(error),
        stackTrace,
      );
    }

    final storedForCurrent = current == null || stored?.userId == current.userId
        ? stored
        : null;
    final currentRefreshToken = current?.refreshToken;
    final refreshCredential =
        currentRefreshToken != null && currentRefreshToken.isNotEmpty
        ? currentRefreshToken
        : storedForCurrent?.refreshToken;
    if (refreshCredential == null || refreshCredential.isEmpty) {
      if (current != null || stored != null) await _endSession();
      throw const NetworkSessionUnavailableException();
    }

    try {
      final refreshed = await refreshToken(refreshToken: refreshCredential);
      if (_generation != refreshGeneration) {
        throw const _RefreshSupersededException();
      }
      final latestCurrent = currentSession();
      final latestStored = await sessionStore.load();
      if (current != null) {
        if (latestCurrent == null ||
            latestCurrent.userId != current.userId ||
            latestCurrent.refreshToken != refreshCredential) {
          throw const _RefreshSupersededException();
        }
      } else {
        if (latestCurrent != null &&
            (latestCurrent.userId != storedForCurrent?.userId ||
                latestCurrent.refreshToken != refreshCredential)) {
          throw const _RefreshSupersededException();
        }
        if (latestCurrent == null &&
            (latestStored?.userId != storedForCurrent?.userId ||
                latestStored?.refreshToken != refreshCredential)) {
          throw const _RefreshSupersededException();
        }
      }

      final baseSession = latestCurrent ?? current;
      final userId = baseSession?.userId ?? storedForCurrent!.userId;
      if (_generation != refreshGeneration) {
        throw const _RefreshSupersededException();
      }
      await sessionStore.saveCredentials(
        userId: userId,
        refreshToken: refreshed.refreshToken,
      );

      final publishSession = currentSession();
      if (baseSession == null) {
        if (publishSession != null) {
          throw const _RefreshSupersededException();
        }
      } else if (publishSession == null ||
          publishSession.userId != baseSession.userId ||
          publishSession.refreshToken != refreshCredential) {
        throw const _RefreshSupersededException();
      }
      final metadataSession = publishSession ?? baseSession;
      final nextSession = NetworkSession(
        userId: userId,
        playerId: metadataSession?.playerId,
        token: refreshed.token,
        refreshToken: refreshed.refreshToken,
        matchId: metadataSession?.matchId ?? storedForCurrent?.matchId,
        connectionState:
            metadataSession?.connectionState ??
            NetworkConnectionState(
              status: NetworkConnectionStatus.connected,
              changedAt: now(),
            ),
      );
      if (_generation != refreshGeneration) {
        throw const _RefreshSupersededException();
      }
      setSession(nextSession);
      return nextSession;
    } on _RefreshSupersededException catch (_, stackTrace) {
      await _restoreCurrentCredentials();
      Error.throwWithStackTrace(
        const NetworkSessionUnavailableException(),
        stackTrace,
      );
    } catch (error, stackTrace) {
      await _endSession();
      Error.throwWithStackTrace(
        NetworkSessionRefreshFailedException(
          error,
          rejected: NetworkSessionRefreshCoordinator.isRejectedRefreshError(
            error,
          ),
        ),
        stackTrace,
      );
    }
  }

  bool _needsRefresh(AuthToken token) {
    return token.isExpiredAt(now(), skew: tokenRefreshSkew);
  }

  Future<void> _endSession() async {
    setSession(null);
    try {
      await sessionStore.clear();
    } catch (_) {
      // The in-memory session must still end when secure storage is broken.
    }
  }

  Future<void> _restoreCurrentCredentials() async {
    final current = currentSession();
    final refresh = current?.refreshToken;
    if (current == null || refresh == null || refresh.isEmpty) {
      try {
        await sessionStore.clear();
      } catch (_) {
        // The superseded write must not restore a logged-out session.
      }
      return;
    }
    try {
      await sessionStore.saveCredentials(
        userId: current.userId,
        refreshToken: refresh,
      );
      final latest = currentSession();
      if (latest == null) {
        await sessionStore.clear();
      } else if (latest.userId != current.userId ||
          latest.refreshToken != refresh) {
        final latestRefresh = latest.refreshToken;
        if (latestRefresh == null || latestRefresh.isEmpty) {
          await sessionStore.clear();
        } else {
          await sessionStore.saveCredentials(
            userId: latest.userId,
            refreshToken: latestRefresh,
          );
        }
      }
    } catch (_) {
      // A newer session remains authoritative in memory.
    }
  }

  static bool isRejectedRefreshError(Object error) {
    return error is sp_auth.RefreshTokenMalformedException ||
        error is sp_auth.RefreshTokenNotFoundException ||
        error is sp_auth.RefreshTokenExpiredException ||
        error is sp_auth.RefreshTokenInvalidSecretException;
  }
}

/// Per-client Serverpod adapter backed by the shared refresh coordinator.
///
/// The last issued token is kept per client so a delayed 401 can identify the
/// credential it used even after another request already refreshed the session.
final class NetworkSessionAuthKeyProvider
    implements sp_auth.RefresherClientAuthKeyProvider {
  final NetworkSessionRefreshCoordinator coordinator;
  AuthToken? _lastIssuedToken;

  NetworkSessionAuthKeyProvider(this.coordinator);

  @override
  Future<String?> get authHeaderValue async {
    final token = await coordinator.currentToken();
    _lastIssuedToken = token;
    return sp_auth.wrapAsBearerAuthHeaderValue(token.value);
  }

  @override
  Future<sp_auth.RefreshAuthKeyResult> refreshAuthKey({
    bool force = false,
  }) async {
    try {
      final session = await coordinator.refreshAfterUnauthorized(
        _lastIssuedToken,
      );
      _lastIssuedToken = session.token;
      return sp_auth.RefreshAuthKeyResult.success;
    } catch (error) {
      if (error is NetworkSessionUnavailableException ||
          (error is NetworkSessionRefreshFailedException && error.rejected)) {
        return sp_auth.RefreshAuthKeyResult.failedUnauthorized;
      }
      return sp_auth.RefreshAuthKeyResult.failedOther;
    }
  }
}

sealed class NetworkSessionAuthenticationException implements Exception {
  const NetworkSessionAuthenticationException();
}

final class NetworkSessionUnavailableException
    extends NetworkSessionAuthenticationException {
  const NetworkSessionUnavailableException();

  @override
  String toString() => 'NetworkSessionUnavailableException';
}

final class NetworkSessionRefreshFailedException
    extends NetworkSessionAuthenticationException {
  final Object cause;
  final bool rejected;

  const NetworkSessionRefreshFailedException(
    this.cause, {
    this.rejected = false,
  });

  @override
  String toString() => 'NetworkSessionRefreshFailedException($cause)';
}

final class _RefreshSupersededException implements Exception {
  const _RefreshSupersededException();
}
