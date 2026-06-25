import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredNetworkSession {
  final String userId;
  final String refreshToken;
  final String displayName;
  final String? matchId;

  const StoredNetworkSession({
    required this.userId,
    required this.refreshToken,
    required this.displayName,
    this.matchId,
  });

  StoredNetworkSession copyWith({Object? matchId = _undefined}) {
    return StoredNetworkSession(
      userId: userId,
      refreshToken: refreshToken,
      displayName: displayName,
      matchId: identical(matchId, _undefined)
          ? this.matchId
          : matchId as String?,
    );
  }
}

const Object _undefined = Object();

class NetworkSessionStore {
  static const _userIdKey = 'network.session.userId';
  static const _refreshTokenKey = 'network.session.refreshToken';
  static const _displayNameKey = 'network.session.displayName';
  static const _matchIdKey = 'network.session.matchId';

  final SecureSessionTokenStore secureTokens;

  const NetworkSessionStore({
    this.secureTokens = const FlutterSecureSessionTokenStore(),
  });

  Future<StoredNetworkSession?> load() async {
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
  }

  Future<String> loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey) ?? 'Player';
  }

  Future<void> save(StoredNetworkSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, session.userId);
    final savedSecurely = await _tryWriteSecureRefreshToken(
      session.refreshToken,
    );
    if (savedSecurely) {
      await prefs.remove(_refreshTokenKey);
    } else {
      // A broken Keychain should not push new refresh tokens into plain prefs.
      await prefs.remove(_refreshTokenKey);
    }
    await prefs.setString(_displayNameKey, session.displayName);
    final matchId = session.matchId;
    if (matchId == null || matchId.isEmpty) {
      await prefs.remove(_matchIdKey);
    } else {
      await prefs.setString(_matchIdKey, matchId);
    }
  }

  Future<void> saveDisplayName(String displayName) async {
    final normalized = displayName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_displayNameKey);
    } else {
      await prefs.setString(_displayNameKey, normalized);
    }
  }

  Future<void> saveMatchId(String? matchId) async {
    final prefs = await SharedPreferences.getInstance();
    if (matchId == null || matchId.isEmpty) {
      await prefs.remove(_matchIdKey);
    } else {
      await prefs.setString(_matchIdKey, matchId);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_matchIdKey);
    await _tryDeleteSecureRefreshToken();
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
