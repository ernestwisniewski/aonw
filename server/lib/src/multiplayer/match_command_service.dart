import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import '../generated/protocol.dart';
import 'match_broadcaster.dart';
import 'match_connection_registry.dart';
import 'match_mutation_outcome.dart';
import 'match_state_access.dart';
import 'multiplayer_match_store.dart';
import 'server_command_reducer.dart';

part 'match_command_service_handling.dart';
part 'match_command_service_timeout.dart';

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
