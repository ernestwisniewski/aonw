import 'package:aonw_core/protocol.dart';

import '../generated/protocol.dart';

GameMatch gameMatchRowForState(
  GameMatch row,
  WireMatch match,
  DateTime nowUtc,
) {
  return row.copyWith(
    ownerUserIdentifier: match.ownerUserId,
    name: match.name,
    mapName: match.mapName,
    state: match.state,
    turn: match.turn,
    maxPlayers: match.maxPlayers,
    minPlayers: match.minPlayers,
    private: match.inviteCode != null,
    quickplay: match.quickplay,
    autoStartAt: match.autoStartAt,
    inviteCode: match.inviteCode,
    startedAt: match.state == 'running'
        ? row.startedAt ?? nowUtc
        : row.startedAt,
  );
}
