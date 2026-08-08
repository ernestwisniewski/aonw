import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/generated/protocol.dart' hide GameEvent;
import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/match_activity_tracker.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_connection_registry.dart';
import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/match_mutation_outcome.dart';
import 'package:aonw_server/src/multiplayer/match_state_access.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_movement_audience.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/server_command_outcome_projector.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';

part 'match_command_service_event.dart';
part 'match_command_service_handling.dart';
part 'match_command_service_timeout.dart';

const _runningMatchSnapshotCodec = RunningMatchSnapshotCodec();
const _matchLifecycleStateAdapter = MatchLifecycleStateAdapter();
const _matchLifecycleWireAdapter = MatchLifecycleWireAdapter();
const _matchActivityTracker = MatchActivityTracker();

final class MatchCommandService {
  MatchCommandService({
    required ServerCommandReducer commandReducer,
    required MatchStateAccess stateAccess,
    required MatchBroadcaster broadcaster,
    required DateTime Function() nowUtc,
    Duration matchInactivityTimeout = defaultMultiplayerMatchInactivityTimeout,
  }) : _commandReducer = commandReducer,
       _stateAccess = stateAccess,
       _broadcaster = broadcaster,
       _nowUtc = nowUtc,
       _matchInactivityTimeout = matchInactivityTimeout;

  final ServerCommandReducer _commandReducer;
  final MatchStateAccess _stateAccess;
  final MatchBroadcaster _broadcaster;
  final DateTime Function() _nowUtc;
  final Duration _matchInactivityTimeout;
  RunningMatchCursor? _nextTimeoutSweepCursor;

  DecodedRunningMatchSnapshot _decodeRunningSnapshot(StoredMatchState state) {
    final decoded = _runningMatchSnapshotCodec.decode(
      match: state.match,
      snapshot: state.snapshot,
    );
    _runningMatchSnapshotCodec.canonicalWithValidatedRoster(
      decoded,
      match: state.match,
    );
    return decoded;
  }

  WireSnapshot _encodeReductionSnapshot({
    required DecodedRunningMatchSnapshot decoded,
    required ServerCommandReduction reduction,
    required int offset,
  }) {
    final encoded = _runningMatchSnapshotCodec
        .encodeCanonical(decoded, reduction.nextSnapshot!)
        .copyWith(offset: offset);
    return _matchActivityTracker.preserveActivity(decoded.wire, encoded);
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
    final withSnapshot = state.copyWith(
      match: state.match.copyWith(turn: turn),
      snapshot: snapshot,
    );
    final transition = _matchLifecycleStateAdapter.apply(
      withSnapshot,
      FinishMatchLifecycle(
        _matchLifecycleWireAdapter.decodeFinishedReason(outcome.condition.name),
      ),
      endedAt: now,
      winnerPlayerId: outcome.winnerPlayerId,
    );
    if (transition.rejection case final rejection?) {
      throw StateError('Finish match lifecycle rejected: ${rejection.code}.');
    }
    return transition.state;
  }

  StoredMatchState _stateAfterAcceptedPlayerReduction({
    required StoredMatchState state,
    required ServerCommandReduction reduction,
    required WireSnapshot snapshot,
    required DateTime now,
  }) {
    return _stateAfterAcceptedReduction(
      state: state,
      reduction: reduction,
      snapshot: _matchActivityTracker.recordSnapshot(snapshot, now),
      now: now,
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

extension _MatchCommandStore on MultiplayerMatchStore {
  Future<void> _appendEventAndFinalizePresence(
    StoredMatchState state,
    WireEvent event, {
    required String actorPlayerId,
    required String clientMessageId,
  }) async {
    await appendEvent(
      state,
      event,
      actorPlayerId: actorPlayerId,
      clientMessageId: clientMessageId,
    );
    if (_matchLifecycleStateAdapter.lifecycleOf(state).isTerminal) {
      await deletePresenceLeases(state.match.id);
    }
  }
}

List<Map<String, dynamic>> _eventAudienceForStorage({
  required List<GameEvent> events,
  required Iterable<String> participantPlayerIds,
  required DomainState previous,
  required DomainState next,
  required Iterable<CombatAnimationFact> combatAnimations,
  required Map<String, Set<String>> exactMovementAudienceByUnit,
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
    exactMovementAudienceByUnit: exactMovementAudienceByUnit,
  );
}
