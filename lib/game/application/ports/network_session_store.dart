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

abstract interface class NetworkSessionStorePort {
  Future<StoredNetworkSession?> load();

  Future<String> loadDisplayName();

  Future<void> save(StoredNetworkSession session);

  Future<void> saveCredentials({
    required String userId,
    required String refreshToken,
  });

  Future<void> saveDisplayName(String displayName);

  Future<void> saveMatchId(String? matchId);

  Future<void> clear();
}

final class NetworkSessionCredentialPersistenceException implements Exception {
  const NetworkSessionCredentialPersistenceException();

  @override
  String toString() => 'NetworkSessionCredentialPersistenceException';
}
