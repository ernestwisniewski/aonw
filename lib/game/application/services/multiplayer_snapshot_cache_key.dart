import 'dart:convert';

String multiplayerSnapshotCacheKey({
  required String userId,
  required String matchId,
}) {
  if (userId.trim().isEmpty) {
    throw ArgumentError.value(
      userId,
      'userId',
      'Expected a non-empty multiplayer account id',
    );
  }
  if (matchId.trim().isEmpty) {
    throw ArgumentError.value(
      matchId,
      'matchId',
      'Expected a non-empty multiplayer match id',
    );
  }
  return 'multiplayer-v3.${_cacheKeySegment(userId)}.'
      '${_cacheKeySegment(matchId)}';
}

String _cacheKeySegment(String value) {
  return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}
