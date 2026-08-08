enum MultiplayerFailureKind { multiplayer, authentication, connection }

/// Stable application error emitted by multiplayer adapters.
final class MultiplayerFailure implements Exception {
  final MultiplayerFailureKind kind;
  final String? code;
  final String? message;
  final Object? cause;

  const MultiplayerFailure({
    required this.kind,
    this.cause,
    this.code,
    this.message,
  });

  const MultiplayerFailure.multiplayer({this.code, this.message, this.cause})
    : kind = MultiplayerFailureKind.multiplayer;

  const MultiplayerFailure.authentication({this.code, this.message, this.cause})
    : kind = MultiplayerFailureKind.authentication;

  const MultiplayerFailure.connection({this.message, this.cause})
    : kind = MultiplayerFailureKind.connection,
      code = null;

  bool get isMultiplayer => kind == MultiplayerFailureKind.multiplayer;

  bool get isAuthentication => kind == MultiplayerFailureKind.authentication;

  bool get terminatesLobbyMembership {
    if (!isMultiplayer) return false;
    return switch (code) {
      'not_match_player' ||
      'match_not_found' ||
      'match_abandoned' ||
      'match_not_open' ||
      'unsupported_match_protocol' => true,
      _ => false,
    };
  }

  @override
  String toString() {
    final detail = message == null || message!.isEmpty ? code : message;
    return detail == null
        ? 'MultiplayerFailure(${kind.name})'
        : 'MultiplayerFailure(${kind.name}, $detail)';
  }
}
