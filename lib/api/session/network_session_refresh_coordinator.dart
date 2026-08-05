import 'package:aonw/api/session/serverpod_multiplayer_failure_mapper.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_authentication.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
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
/// Rotated credentials are persisted in secure storage before publication.
/// A transient storage failure keeps them in memory until the next read;
/// tokens are never downgraded to plain preferences.
final class NetworkSessionRefreshCoordinator {
  static const tokenRefreshSkew = Duration(seconds: 30);

  final NetworkSessionReader currentSession;
  final NetworkSessionWriter setSession;
  final NetworkSessionStorePort sessionStore;
  final NetworkSessionTokenRefresher refreshToken;
  final NetworkSessionClock now;

  Future<NetworkSession>? _refreshInFlight;
  Future<void>? _terminationInFlight;
  Future<void>? _credentialPersistenceInFlight;
  _PendingSessionPersistence? _pendingPersistence;
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

  /// Publishes a newly authenticated session without making availability of
  /// the server-issued access token depend on a transient Keychain failure.
  ///
  /// Failed secure persistence remains memory-only and is retried before a
  /// subsequent token is returned to a transport.
  Future<void> activateAuthenticatedSession({
    required NetworkSession session,
    required String displayName,
  }) async {
    if (_terminating) throw const NetworkSessionUnavailableException();
    final activationGeneration = ++_generation;
    _pendingPersistence = null;
    setSession(session);

    final refreshToken = session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      // A token-only login must not inherit another account's refresh secret.
      // NetworkSessionStore.clear preserves the standalone display-name
      // preference while removing credentials and match metadata.
      await sessionStore.clear();
      if (!_activationCredentialsStillCurrent(session, activationGeneration)) {
        await _restoreCurrentCredentials();
        return;
      }
      await _persistNonSecretLoginMetadata(
        session: session,
        generation: activationGeneration,
        displayName: displayName,
        matchId: null,
      );
      return;
    }

    try {
      await sessionStore.saveCredentials(
        userId: session.userId,
        refreshToken: refreshToken,
      );
    } on NetworkSessionCredentialPersistenceException {
      // A newer activation may already have queued or persisted its own
      // credentials while this secure write was in flight. Never let the
      // stale activation clear that account.
      if (!_activationCredentialsStillCurrent(session, activationGeneration)) {
        return;
      }
      var staleCredentialsDetached = false;
      try {
        // The secure write failed before the store could associate the new
        // user id with this refresh token. Remove the old user-id/match
        // pairing before publishing metadata for the memory-only login; an
        // undeletable Keychain secret is then inert because load() has no
        // stored owner to attach it to.
        await sessionStore.clear();
        staleCredentialsDetached = true;
      } catch (_) {
        // Keep the authenticated session usable in memory, but do not write
        // metadata that could be paired with another account after restart.
      }
      if (!_activationCredentialsStillCurrent(session, activationGeneration)) {
        if (staleCredentialsDetached) await _restoreCurrentCredentials();
        return;
      }
      _pendingPersistence = _PendingSessionPersistence.credentials(
        userId: session.userId,
        refreshToken: refreshToken,
      );
      if (staleCredentialsDetached) {
        await _persistNonSecretLoginMetadata(
          session: session,
          generation: activationGeneration,
          displayName: displayName,
          matchId: session.matchId,
        );
      }
      return;
    }
    await _persistNonSecretLoginMetadata(
      session: session,
      generation: activationGeneration,
      displayName: displayName,
      matchId: session.matchId,
    );
  }

  /// Returns a usable session and optionally forces refresh-token rotation.
  Future<NetworkSession> ensureValidSession({bool forceRefresh = false}) async {
    if (_terminating) throw const NetworkSessionUnavailableException();
    await _retryPendingCredentialPersistence();
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
          final stored = await sessionStore.load();
          final credentialOwner = latest ?? initial;
          if (stored != null &&
              (credentialOwner == null ||
                  stored.userId == credentialOwner.userId)) {
            latestRefreshToken = stored.refreshToken;
          }
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
      if (_generation != refreshGeneration) {
        await _restoreCurrentCredentials();
        Error.throwWithStackTrace(
          const NetworkSessionUnavailableException(),
          stackTrace,
        );
      }
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
      if (_generation != refreshGeneration) {
        await _restoreCurrentCredentials();
        throw const NetworkSessionUnavailableException();
      }
      if (current != null || stored != null) await _endSession();
      throw const NetworkSessionUnavailableException();
    }

    try {
      final refreshed = await refreshToken(refreshToken: refreshCredential);
      final anchor = await _reanchorAfterRotation(
        refreshGeneration: refreshGeneration,
        current: current,
        storedForCurrent: storedForCurrent,
        refreshCredential: refreshCredential,
      );

      final userId = anchor?.userId ?? storedForCurrent!.userId;
      var credentialsPersisted = false;
      try {
        await sessionStore.saveCredentials(
          userId: userId,
          refreshToken: refreshed.refreshToken,
        );
        credentialsPersisted = true;
      } on NetworkSessionCredentialPersistenceException {
        // The server has already invalidated the previous refresh token. Keep
        // the replacement in memory and retry secure persistence later.
      }

      _requireNotSuperseded(refreshGeneration, anchor, refreshCredential);
      final metadataSession = currentSession() ?? anchor;
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
      _requireNotSuperseded(refreshGeneration, anchor, refreshCredential);
      setSession(nextSession);
      _pendingPersistence = credentialsPersisted
          ? null
          : _PendingSessionPersistence.credentials(
              userId: userId,
              refreshToken: refreshed.refreshToken,
            );
      return nextSession;
    } on _RefreshSupersededException catch (_, stackTrace) {
      await _restoreCurrentCredentials();
      Error.throwWithStackTrace(
        const NetworkSessionUnavailableException(),
        stackTrace,
      );
    } catch (error, stackTrace) {
      if (_generation != refreshGeneration) {
        await _restoreCurrentCredentials();
        Error.throwWithStackTrace(
          const NetworkSessionUnavailableException(),
          stackTrace,
        );
      }
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

  /// Re-anchors the refresh on the authoritative session after the rotation
  /// round-trip.
  ///
  /// A refresh that started with a live session stays anchored to it. A
  /// store-anchored refresh adopts a session that appeared for the same owner
  /// and credential, and otherwise verifies the store still holds them.
  /// Throws [_RefreshSupersededException] when a logout or another activation
  /// took over while the rotation was in flight.
  Future<NetworkSession?> _reanchorAfterRotation({
    required int refreshGeneration,
    required NetworkSession? current,
    required StoredNetworkSession? storedForCurrent,
    required String refreshCredential,
  }) async {
    if (current != null) {
      _requireNotSuperseded(refreshGeneration, current, refreshCredential);
      return current;
    }
    if (_generation != refreshGeneration) {
      throw const _RefreshSupersededException();
    }
    final appeared = currentSession();
    if (appeared != null) {
      if (appeared.userId != storedForCurrent?.userId ||
          appeared.refreshToken != refreshCredential) {
        throw const _RefreshSupersededException();
      }
      return appeared;
    }
    final latestStored = await sessionStore.load();
    if (latestStored?.userId != storedForCurrent?.userId ||
        latestStored?.refreshToken != refreshCredential) {
      throw const _RefreshSupersededException();
    }
    return null;
  }

  /// True when the session this refresh was rotated for is no longer the
  /// authoritative one: a logout or activation bumped the generation, the
  /// live session changed identity, or a session appeared for a refresh that
  /// started without one.
  bool _refreshSuperseded(
    int refreshGeneration,
    NetworkSession? anchor,
    String refreshCredential,
  ) {
    if (_generation != refreshGeneration) return true;
    if (anchor == null) return currentSession() != null;
    return !_sessionStillMatches(anchor.userId, refreshCredential);
  }

  void _requireNotSuperseded(
    int refreshGeneration,
    NetworkSession? anchor,
    String refreshCredential,
  ) {
    if (_refreshSuperseded(refreshGeneration, anchor, refreshCredential)) {
      throw const _RefreshSupersededException();
    }
  }

  Future<void> _endSession() async {
    _pendingPersistence = null;
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

  Future<void> _retryPendingCredentialPersistence() async {
    final pending = _pendingPersistence;
    if (pending == null) return;

    final active = _credentialPersistenceInFlight;
    if (active != null) {
      await active;
      final next = _pendingPersistence;
      if (next != null && !identical(next, pending)) {
        await _retryPendingCredentialPersistence();
      }
      return;
    }

    if (!_sessionStillMatches(pending.userId, pending.refreshToken)) {
      if (identical(_pendingPersistence, pending)) {
        _pendingPersistence = null;
      }
      return;
    }

    final generation = _generation;
    final started = _persistPendingCredentials(pending, generation);
    _credentialPersistenceInFlight = started;
    try {
      await started;
    } finally {
      if (identical(_credentialPersistenceInFlight, started)) {
        _credentialPersistenceInFlight = null;
      }
    }
  }

  Future<void> _persistPendingCredentials(
    _PendingSessionPersistence pending,
    int generation,
  ) async {
    try {
      await sessionStore.saveCredentials(
        userId: pending.userId,
        refreshToken: pending.refreshToken,
      );
    } catch (_) {
      // The active in-memory session remains authoritative. A later token read
      // retries secure persistence without exposing the secret elsewhere.
      return;
    }

    if (_generation == generation &&
        _sessionStillMatches(pending.userId, pending.refreshToken)) {
      if (identical(_pendingPersistence, pending)) {
        _pendingPersistence = null;
      }
      return;
    }
    await _restoreCurrentCredentials();
  }

  bool _sessionStillMatches(String userId, String refreshToken) {
    final current = currentSession();
    return current != null &&
        current.userId == userId &&
        current.refreshToken == refreshToken;
  }

  bool _activationCredentialsStillCurrent(
    NetworkSession session,
    int generation,
  ) {
    if (_generation != generation) return false;
    final current = currentSession();
    return current != null &&
        current.userId == session.userId &&
        current.token.value == session.token.value &&
        current.refreshToken == session.refreshToken;
  }

  bool _activationMetadataStillCurrent(NetworkSession session, int generation) {
    final current = currentSession();
    return _activationCredentialsStillCurrent(session, generation) &&
        current?.matchId == session.matchId;
  }

  Future<void> _persistNonSecretLoginMetadata({
    required NetworkSession session,
    required int generation,
    required String displayName,
    required String? matchId,
  }) async {
    if (!_activationMetadataStillCurrent(session, generation)) return;
    await sessionStore.saveDisplayName(displayName);
    if (!_activationMetadataStillCurrent(session, generation)) return;
    await sessionStore.saveMatchId(matchId);
  }

  static bool isRejectedRefreshError(Object error) {
    // The gateway normalizes generated Serverpod refresh errors before they
    // reach this coordinator, while direct adapters may still pass their raw
    // exceptions. Keep both representations on the same classification path.
    return isRejectedServerpodRefreshError(error);
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

final class _RefreshSupersededException implements Exception {
  const _RefreshSupersededException();
}

final class _PendingSessionPersistence {
  const _PendingSessionPersistence._({
    required this.userId,
    required this.refreshToken,
  });

  factory _PendingSessionPersistence.credentials({
    required String userId,
    required String refreshToken,
  }) {
    return _PendingSessionPersistence._(
      userId: userId,
      refreshToken: refreshToken,
    );
  }

  final String userId;
  final String refreshToken;
}
