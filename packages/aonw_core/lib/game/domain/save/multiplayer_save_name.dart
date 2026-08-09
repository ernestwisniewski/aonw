/// Canonical naming rule for persisted multiplayer games.
abstract final class MultiplayerSaveName {
  static const prefix = 'multi';

  static final RegExp _existingPrefix = RegExp(
    r'^multi(?:\s+|$)',
    caseSensitive: false,
  );

  static String fromMatchName(String matchName) {
    final normalized = matchName.trim();
    final existingPrefix = _existingPrefix.firstMatch(normalized);
    if (existingPrefix == null) {
      return normalized.isEmpty ? prefix : '$prefix $normalized';
    }
    final suffix = normalized.substring(existingPrefix.end).trimLeft();
    return suffix.isEmpty ? prefix : '$prefix $suffix';
  }
}
