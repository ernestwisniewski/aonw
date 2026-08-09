part of '../realtime_match_hub_test.dart';

class _FindStateFailingMatchStore extends TestMatchStore {
  String? _failedMatchId;

  void failFindStateFor(String matchId) {
    _failedMatchId = matchId;
  }

  @override
  Future<StoredMatchState?> findState(
    String matchId, {
    bool lock = false,
  }) async {
    if (_failedMatchId == matchId) {
      _failedMatchId = null;
      throw StateError('Injected findState failure for $matchId');
    }
    return super.findState(matchId, lock: lock);
  }
}

class _CommitFailingMatchStore extends TestMatchStore {
  var _failNextCommit = false;

  void failNextCommit() {
    _failNextCommit = true;
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) async {
    final statesBefore = Map<String, StoredMatchState>.of(_states);
    final eventsBefore = {
      for (final entry in _events.entries) entry.key: [...entry.value],
    };
    final clientEventsBefore = Map<String, WireEvent>.of(
      _eventsByClientMessageId,
    );
    final presenceRowIdsBefore = Map<String, int>.of(_presenceRowIds);
    final nextPresenceRowIdBefore = _nextPresenceRowId;
    try {
      final result = await action(this);
      if (_failNextCommit) {
        _failNextCommit = false;
        throw StateError('Injected transaction commit failure');
      }
      return result;
    } catch (_) {
      _states
        ..clear()
        ..addAll(statesBefore);
      _events
        ..clear()
        ..addAll(eventsBefore);
      _eventsByClientMessageId
        ..clear()
        ..addAll(clientEventsBefore);
      _presenceRowIds
        ..clear()
        ..addAll(presenceRowIdsBefore);
      _nextPresenceRowId = nextPresenceRowIdBefore;
      rethrow;
    }
  }
}
