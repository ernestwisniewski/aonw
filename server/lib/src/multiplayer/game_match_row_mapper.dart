import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/generated/protocol.dart';

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
    endedAt: match.endedAt,
    outcomeCondition: match.outcomeCondition,
    winnerPlayerId: match.winnerPlayerId,
    autoStartAt: match.autoStartAt,
    inviteCode: match.inviteCode,
    startedAt: match.state == 'running'
        ? row.startedAt ?? nowUtc
        : row.startedAt,
  );
}

WireMatch wireMatchFromRow(GameMatch row, List<GamePlayer> players) {
  return WireMatch(
    id: row.publicId,
    ownerUserId: row.ownerUserIdentifier,
    name: row.name,
    mapName: row.mapName,
    players: [for (final player in players) wirePlayerFromRow(player)],
    maxPlayers: row.maxPlayers,
    minPlayers: row.minPlayers,
    quickplay: row.quickplay,
    turn: row.turn,
    state: row.state,
    createdAt: row.createdAt,
    endedAt: row.endedAt,
    outcomeCondition: row.outcomeCondition,
    winnerPlayerId: row.winnerPlayerId,
    autoStartAt: row.autoStartAt,
    inviteCode: row.inviteCode,
  );
}

WirePlayer wirePlayerFromRow(GamePlayer row) {
  return WirePlayer(
    id: row.publicPlayerId,
    userId: row.userIdentifier,
    name: row.displayName,
    colorValue: row.colorValue,
    country: PlayerCountry.values.byName(row.countryId),
    kind: WirePlayerKind.values.byName(row.kind),
    connectionState: WirePlayerConnectionState.values.byName(
      row.connectionState,
    ),
    ready: row.ready,
  );
}

GamePlayer gamePlayerRow(int matchRowId, WirePlayer player, int seatOrder) {
  return GamePlayer(
    matchId: matchRowId,
    publicPlayerId: player.id,
    userIdentifier: player.userId,
    displayName: player.name,
    colorValue: player.colorValue,
    countryId: player.country.name,
    kind: player.kind.name,
    connectionState: player.connectionState.name,
    ready: player.ready,
    seatOrder: seatOrder,
  );
}
