import 'dart:async';

import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw_core/protocol.dart';

typedef LobbyLiveMatchReader = WireMatch? Function();
typedef LobbyLiveMatchContinuation = bool Function();
typedef LobbyLiveMatchSubscriber =
    Future<LobbyLiveMatchStreamHandle> Function({
      required NetworkSession session,
      required WireMatch match,
      required void Function(WireMatch match) onMatch,
      required void Function(Object error, StackTrace stackTrace) onError,
    });
typedef LobbyLiveMatchUpdateApplier =
    void Function({required NetworkSession session, required WireMatch match});
typedef LobbyLiveMatchErrorHandler = void Function(Object error);
typedef LobbyLiveMatchErrorReporter = bool Function(Object error);
typedef LobbyLiveMatchDeferrer = void Function(void Function() action);

abstract interface class LobbyLiveMatchStreamHandle {
  Future<void> close();
}

final class LiveEventLobbyMatchStreamHandle
    implements LobbyLiveMatchStreamHandle {
  final LiveEventSubscriptionHandle _handle;

  const LiveEventLobbyMatchStreamHandle(this._handle);

  @override
  Future<void> close() => _handle.close();
}

final class LobbyLiveMatchCoordinator {
  final LobbyLiveMatchReader activeMatch;
  final LobbyLiveMatchContinuation canContinue;
  final LobbyLiveMatchSubscriber subscribe;
  final LobbyLiveMatchUpdateApplier applyMatchUpdate;
  final LobbyLiveMatchErrorHandler showError;
  final LobbyLiveMatchErrorReporter reportStreamError;
  final LobbyLiveMatchDeferrer defer;

  LobbyLiveMatchStreamHandle? _events;
  String? _streamMatchId;

  LobbyLiveMatchCoordinator({
    required this.activeMatch,
    required this.canContinue,
    required this.subscribe,
    required this.applyMatchUpdate,
    required this.showError,
    LobbyLiveMatchErrorReporter? reportStreamError,
    required this.defer,
  }) : reportStreamError = reportStreamError ?? ((_) => true);

  void watch({required NetworkSession session, required WireMatch match}) {
    if (LobbyMatchStatusRules.isTerminal(match)) return;
    if (_streamMatchId == match.id) return;
    _streamMatchId = match.id;
    unawaited(_connect(session: session, match: match));
  }

  Future<void> close() async {
    _streamMatchId = null;
    await _closeCurrentHandle();
  }

  Future<void> _closeCurrentHandle() async {
    final handle = _events;
    _events = null;
    await handle?.close();
  }

  Future<void> _connect({
    required NetworkSession session,
    required WireMatch match,
  }) async {
    await _closeCurrentHandle();
    _streamMatchId = match.id;
    try {
      final handle = await subscribe(
        session: session,
        match: match,
        onMatch: (updated) => _applyMatchUpdate(
          session: session,
          expectedMatchId: match.id,
          match: updated,
        ),
        onError: (error, _) {
          if (!_isCurrent(match.id)) return;
          if (!reportStreamError(error)) return;
          showError(error);
        },
      );
      if (!_isCurrent(match.id)) {
        await handle.close();
        return;
      }
      _events = handle;
    } catch (error) {
      if (!_isCurrent(match.id)) return;
      _streamMatchId = null;
      showError(error);
    }
  }

  void _applyMatchUpdate({
    required NetworkSession session,
    required String expectedMatchId,
    required WireMatch match,
  }) {
    if (match.id != expectedMatchId) return;
    defer(() {
      if (!_isCurrent(match.id)) return;
      applyMatchUpdate(session: session, match: match);
    });
  }

  bool _isCurrent(String matchId) {
    return canContinue() && activeMatch()?.id == matchId;
  }
}
