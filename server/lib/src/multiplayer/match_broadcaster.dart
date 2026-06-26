import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'match_connection_registry.dart';
import 'multiplayer_match_store.dart';

final class MatchBroadcaster {
  MatchBroadcaster(this._connectionRegistry);

  final MatchConnectionRegistry _connectionRegistry;

  MultiplayerServerMessage message({
    required String matchId,
    required int offset,
    WireMatch? match,
    WireSnapshot? snapshot,
    WireEvent? event,
    WireCommandAck? ack,
  }) {
    return MultiplayerServerMessage(
      serverMessageId: const Uuid().v4(),
      matchId: matchId,
      offset: offset,
      match: match,
      snapshot: snapshot,
      event: event,
      ack: ack,
    );
  }

  void broadcast(
    MultiplayerServerMessage update, {
    MatchServerMessageSink? except,
  }) {
    _connectionRegistry.broadcast(update, except: except);
  }

  void broadcastState(StoredMatchState state) {
    broadcast(
      message(
        matchId: state.match.id,
        offset: state.offset,
        match: state.match,
        snapshot: state.snapshot,
      ),
    );
  }
}
