import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/generated/protocol.dart' hide GameEvent;
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_connection_registry.dart';
import 'package:aonw_server/src/multiplayer/match_mutation_outcome.dart';
import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_movement_audience.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';

part 'match_command_service_event.dart';
part 'match_command_service_handling.dart';
part 'match_command_service_timeout.dart';

const _runningMatchSnapshotCodec = RunningMatchSnapshotCodec();

final class MatchCommandService {
  MatchCommandService({
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
  RunningMatchCursor? _nextTimeoutSweepCursor;

  DecodedRunningMatchSnapshot _decodeRunningSnapshot(StoredMatchState state) {
    return _runningMatchSnapshotCodec.decode(
      match: state.match,
      snapshot: state.snapshot,
    );
  }

  WireSnapshot _encodeReductionSnapshot({
    required DecodedRunningMatchSnapshot decoded,
    required ServerCommandReduction reduction,
    required int offset,
  }) {
    return _runningMatchSnapshotCodec
        .encodeCanonical(decoded, reduction.nextSnapshot!)
        .copyWith(offset: offset);
  }

  StoredMatchState _stateAfterAcceptedReduction({
    required StoredMatchState state,
    required ServerCommandReduction reduction,
    required WireSnapshot snapshot,
    required DateTime now,
  }) {
    final outcome = reduction.outcome!;
    final turn = reduction.nextSnapshot!.domain.turn;
    if (!outcome.finished) {
      return state.copyWith(
        match: state.match.copyWith(turn: turn),
        snapshot: snapshot,
      );
    }
    if (outcome.condition != GameOutcomeCondition.draw &&
        outcome.winnerPlayerId == null) {
      throw StateError(
        'A finished ${outcome.condition.name} outcome requires a winner.',
      );
    }
    return state.copyWith(
      match: state.match.copyWith(
        turn: turn,
        state: 'finished',
        endedAt: now.toUtc(),
        outcomeCondition: outcome.condition.name,
        winnerPlayerId: outcome.winnerPlayerId,
        autoStartAt: null,
      ),
      snapshot: snapshot.copyWith(
        state: {...snapshot.state, 'phase': 'finished'},
      ),
    );
  }

  Future<void> handleClientMessage({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required MultiplayerClientMessage message,
    required MatchMessageTarget caller,
  }) async {
    if (message.requestSnapshot) {
      final state = await _stateAccess.requireMatch(store, matchId);
      _stateAccess.requireParticipant(state, userIdentifier);
      _broadcaster.sendTo(
        caller,
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

    final outcome = await store.transaction((txStore) {
      return _handleCommand(
        store: txStore,
        matchId: matchId,
        userIdentifier: userIdentifier,
        message: message,
        command: command,
        caller: caller,
      );
    });
    outcome.notifications.deliver(_broadcaster);
  }
}

List<Map<String, dynamic>> _eventAudienceForStorage({
  required List<GameEvent> events,
  required Iterable<String> participantPlayerIds,
  required DomainState previous,
  required DomainState next,
  required Iterable<CombatAnimationFact> combatAnimations,
}) {
  if (events.isEmpty) return const [];
  return PlayerMatchEventAudience.annotateForStorage(
    events: events,
    combatAnimations: combatAnimations,
    participantPlayerIds: participantPlayerIds,
    previous: GameEventOwnershipIndex.from(previous.units, previous.cities),
    next: GameEventOwnershipIndex.from(next.units, next.cities),
    previousFog: previous.fogOfWar,
    nextFog: next.fogOfWar,
  );
}
