import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/protocol.dart';

import '../generated/protocol.dart';
import 'match_broadcaster.dart';
import 'match_connection_registry.dart';
import 'match_state_access.dart';
import 'multiplayer_match_store.dart';
import 'server_command_reducer.dart';

final class MatchCommandService {
  const MatchCommandService({
    required ServerCommandReducer commandReducer,
    required MatchStateAccess stateAccess,
    required MatchBroadcaster broadcaster,
    required DateTime Function() nowUtc,
  }) : _commandReducer = commandReducer,
       _stateAccess = stateAccess,
       _broadcaster = broadcaster,
       _nowUtc = nowUtc;

  final ServerCommandReducer _commandReducer;
  final MatchStateAccess _stateAccess;
  final MatchBroadcaster _broadcaster;
  final DateTime Function() _nowUtc;

  Future<MatchConnectionAuthorization> authorizeConnection({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId);
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    return MatchConnectionAuthorization(state: state, participant: player);
  }

  Future<void> handleClientMessage({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required MultiplayerClientMessage message,
    required MatchServerMessageSink emitToCaller,
  }) async {
    if (message.requestSnapshot) {
      final state = await _stateAccess.requireMatch(store, matchId);
      _stateAccess.requireParticipant(state, userIdentifier);
      emitToCaller(
        _broadcaster.message(
          matchId: state.match.id,
          offset: state.offset,
          match: state.match,
          snapshot: state.snapshot,
        ),
      );
    }

    final command = message.command;
    if (command == null) return;

    await store.transaction((txStore) async {
      final state = await _stateAccess.requireMatch(
        txStore,
        matchId,
        lock: true,
      );
      final player = _stateAccess.requireParticipant(state, userIdentifier);
      if (command.actorPlayerId != player.id) {
        final ack = WireCommandAck(
          matchId: state.match.id,
          accepted: false,
          offset: state.offset,
          snapshot: state.snapshot,
          reason: 'Command actor does not match the authenticated player.',
        );
        emitToCaller(
          _broadcaster.message(
            matchId: state.match.id,
            offset: state.offset,
            ack: ack,
          ),
        );
        return;
      }

      final duplicate = await txStore.findEventByClientMessageId(
        state.match.id,
        actorPlayerId: player.id,
        clientMessageId: message.clientMessageId,
      );
      if (duplicate != null) {
        emitToCaller(
          _broadcaster.message(
            matchId: state.match.id,
            offset: duplicate.offset,
            ack: WireCommandAck(
              matchId: state.match.id,
              accepted: true,
              offset: duplicate.offset,
              snapshot: state.snapshot,
              events: duplicate.events,
            ),
          ),
        );
        return;
      }

      final now = _nowUtc();
      final reduction = await _commandReducer.reduce(
        match: state.match,
        snapshot: state.snapshot,
        wireCommand: command,
        actorPlayerId: player.id,
        now: now,
      );
      if (!reduction.accepted) {
        final ack = WireCommandAck(
          matchId: state.match.id,
          accepted: false,
          offset: state.offset,
          snapshot: reduction.snapshot,
          reason: reduction.reason ?? 'Command rejected.',
        );
        emitToCaller(
          _broadcaster.message(
            matchId: state.match.id,
            offset: state.offset,
            ack: ack,
          ),
        );
        return;
      }

      final nextOffset = state.nextOffset();
      final nextSnapshot = reduction.snapshot.copyWith(offset: nextOffset);
      final nextSave = GameSave.fromJson(nextSnapshot.save);
      final event = WireEvent(
        matchId: state.match.id,
        offset: nextOffset,
        timestamp: now,
        actorPlayerId: player.id,
        tick: command.tick,
        command: command.command,
        events: reduction.events.map(GameEventSerializer.toJson).toList(),
      );
      final updated = state.copyWith(
        match: state.match.copyWith(turn: nextSave.turn),
        snapshot: nextSnapshot,
      );
      await txStore.appendEvent(
        updated,
        event,
        actorPlayerId: player.id,
        clientMessageId: message.clientMessageId,
      );

      final update = _broadcaster.message(
        matchId: state.match.id,
        offset: event.offset,
        snapshot: updated.snapshot,
        event: event,
      );
      _broadcaster.broadcast(update, except: emitToCaller);

      emitToCaller(
        _broadcaster.message(
          matchId: state.match.id,
          offset: event.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: true,
            offset: event.offset,
            snapshot: updated.snapshot,
            events: event.events,
          ),
        ),
      );
    });
  }
}
