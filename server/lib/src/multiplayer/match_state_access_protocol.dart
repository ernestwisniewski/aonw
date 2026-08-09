part of 'match_state_access.dart';

extension MatchStateAccessProtocol on MatchStateAccess {
  int humanPlayerCount(WireMatch match) {
    return match.players
        .where((player) => player.kind == WirePlayerKind.human)
        .length;
  }

  bool supportsCurrentMatch(WireMatch match) {
    return match.v == kProtocolVersion &&
        !_hasAccountIdentifierInPlayerId(match);
  }

  bool supportsCurrentProtocol(StoredMatchState state) {
    return supportsCurrentMatch(state.match) &&
        state.snapshot.v == kSnapshotEventVersion;
  }

  void requireCurrentProtocol(StoredMatchState state) {
    if (supportsCurrentProtocol(state)) return;
    throw multiplayerException(
      'unsupported_match_protocol',
      'This match was created by an unsupported multiplayer version.',
    );
  }

  bool _hasAccountIdentifierInPlayerId(WireMatch match) {
    return match.players.any(
      (player) =>
          player.userId.isNotEmpty && player.id.endsWith('-${player.userId}'),
    );
  }
}
