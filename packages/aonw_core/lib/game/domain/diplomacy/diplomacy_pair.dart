(String, String) normalizedDiplomacyPair(String playerAId, String playerBId) {
  return playerAId.compareTo(playerBId) <= 0
      ? (playerAId, playerBId)
      : (playerBId, playerAId);
}

String diplomacyRelationKey(String playerAId, String playerBId) {
  if (playerAId.isEmpty || playerBId.isEmpty || playerAId == playerBId) {
    return '';
  }
  final pair = normalizedDiplomacyPair(playerAId, playerBId);
  return '${Uri.encodeComponent(pair.$1)}|${Uri.encodeComponent(pair.$2)}';
}
