import 'dart:async';

import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkSessionStore implements NetworkSessionStorePort {
  static const _userIdKey = 'network.session.userId';
  static const _refreshTokenKey = 'network.session.refreshToken';
  static const _displayNameKey = 'network.session.displayName';
  static const _matchIdKey = 'network.session.matchId';

  final SecureSessionTokenStore secureTokens;
  Future<void> _operationTail = Future<void>.value();

  NetworkSessionStore({
    this.secureTokens = const FlutterSecureSessionTokenStore(),
  });

  @override
  Future<StoredNetworkSession?> load() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final refreshToken = await _loadRefreshToken(prefs);
    if (userId == null || refreshToken == null) return null;
    return StoredNetworkSession(
      userId: userId,
      refreshToken: refreshToken,
      displayName: prefs.getString(_displayNameKey) ?? 'Player',
      matchId: prefs.getString(_matchIdKey),
    );
  });

  @override
  Future<String> loadDisplayName() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey) ?? 'Player';
  });

  @override
  Future<void> save(StoredNetworkSession session) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    await _detachCredentialOwner(prefs, nextUserId: session.userId);
    final savedSecurely = await _tryWriteSecureRefreshToken(
      session.refreshToken,
    );
    // A broken Keychain must never push refresh tokens into plain prefs.
    await prefs.remove(_refreshTokenKey);
    if (!savedSecurely) {
      throw const NetworkSessionCredentialPersistenceException();
    }
    await prefs.setString(_userIdKey, session.userId);
    await prefs.setString(_displayNameKey, session.displayName);
    final matchId = session.matchId;
    if (matchId == null || matchId.isEmpty) {
      await prefs.remove(_matchIdKey);
    } else {
      await prefs.setString(_matchIdKey, matchId);
    }
  });

  /// Persists rotated credentials without rewriting profile or match metadata.
  ///
  /// Refresh can race with nickname edits, leave/resign, or match navigation;
  /// those independent writes must not be reverted by an older session copy.
  @override
  Future<void> saveCredentials({
    required String userId,
    required String refreshToken,
  }) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    await _detachCredentialOwner(prefs, nextUserId: userId);
    final savedSecurely = await _tryWriteSecureRefreshToken(refreshToken);
    // Never downgrade newly rotated credentials to plain preferences.
    await prefs.remove(_refreshTokenKey);
    if (!savedSecurely) {
      throw const NetworkSessionCredentialPersistenceException();
    }
    await prefs.setString(_userIdKey, userId);
  });

  Future<void> _detachCredentialOwner(
    SharedPreferences prefs, {
    required String nextUserId,
  }) async {
    final previousUserId = prefs.getString(_userIdKey);
    // The owner is removed before the global secure-token slot changes. A
    // crash between the Keychain write and the following owner write can then
    // only produce an unowned (and therefore unloadable) secret, never a
    // user-A/token-B hybrid.
    await prefs.remove(_userIdKey);
    await prefs.remove(_refreshTokenKey);
    if (previousUserId != null && previousUserId != nextUserId) {
      await prefs.remove(_matchIdKey);
    }
  }

  @override
  Future<void> saveDisplayName(String displayName) => _serialize(() async {
    final normalized = displayName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_displayNameKey);
    } else {
      await prefs.setString(_displayNameKey, normalized);
    }
  });

  @override
  Future<void> saveMatchId(String? matchId) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    if (matchId == null || matchId.isEmpty) {
      await prefs.remove(_matchIdKey);
    } else {
      await prefs.setString(_matchIdKey, matchId);
    }
  });

  @override
  Future<void> clear() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_matchIdKey);
    await _tryDeleteSecureRefreshToken();
  });

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final previous = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;

    Future<T> run() async {
      await previous;
      try {
        return await operation();
      } finally {
        release.complete();
      }
    }

    return run();
  }

  Future<String?> _loadRefreshToken(SharedPreferences prefs) async {
    final secureToken = await _tryReadSecureRefreshToken();
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    final fallbackToken = prefs.getString(_refreshTokenKey);
    if (fallbackToken == null || fallbackToken.isEmpty) return null;

    final secured = await _tryWriteSecureRefreshToken(fallbackToken);
    if (secured) {
      await prefs.remove(_refreshTokenKey);
    }
    return fallbackToken;
  }

  Future<String?> _tryReadSecureRefreshToken() async {
    try {
      return await secureTokens.read(_refreshTokenKey);
    } on PlatformException {
      return null;
    }
  }

  Future<bool> _tryWriteSecureRefreshToken(String token) async {
    try {
      await secureTokens.write(_refreshTokenKey, token);
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _tryDeleteSecureRefreshToken() async {
    try {
      await secureTokens.delete(_refreshTokenKey);
    } on PlatformException {
      return;
    }
  }
}

abstract interface class SecureSessionTokenStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterSecureSessionTokenStore implements SecureSessionTokenStore {
  final FlutterSecureStorage storage;

  const FlutterSecureSessionTokenStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<String?> read(String key) {
    return storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) {
    return storage.delete(key: key);
  }
}
