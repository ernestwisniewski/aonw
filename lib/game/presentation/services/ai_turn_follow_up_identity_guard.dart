import 'package:aonw/game/application/services/turn_opening_lease.dart';

final class AiTurnSaveIdentity {
  final String saveId;
  final int turn;

  const AiTurnSaveIdentity({required this.saveId, required this.turn});

  @override
  bool operator ==(Object other) {
    return other is AiTurnSaveIdentity &&
        other.saveId == saveId &&
        other.turn == turn;
  }

  @override
  int get hashCode => Object.hash(saveId, turn);
}

final class AiTurnExecutionIdentityToken {
  final TurnOpeningLease openingLease;

  const AiTurnExecutionIdentityToken._(this.openingLease);

  int get generation => openingLease.generation;
  String get saveId => openingLease.saveId;
  int get turn => openingLease.sourceTurn;
  String get playerId => openingLease.executionPlayerId;
}

/// Keeps an asynchronous AI follow-up bound to the save and turn that started
/// it, while allowing that same execution to advance its save from T to T+1.
final class AiTurnFollowUpIdentityGuard {
  int _generation = 0;
  AiTurnSaveIdentity? _currentSave;
  AiTurnExecutionIdentityToken? _activeExecution;
  AiTurnSaveIdentity? _authorizedFollowUpSave;

  void initialize(AiTurnSaveIdentity? save) {
    _generation++;
    _currentSave = save;
    _activeExecution = null;
    _authorizedFollowUpSave = null;
  }

  TurnOpeningLease? handleSaveChange(AiTurnSaveIdentity? save) {
    if (_currentSave == save) return null;

    final active = _activeExecution;
    if (active != null &&
        active.generation == _generation &&
        _authorizedFollowUpSave == save) {
      _currentSave = save;
      return null;
    }

    final invalidatedLease = active?.openingLease;
    _generation++;
    _currentSave = save;
    _activeExecution = null;
    _authorizedFollowUpSave = null;
    return invalidatedLease;
  }

  AiTurnExecutionIdentityToken? beginExecution({
    required String saveId,
    required int turn,
    required String playerId,
  }) {
    final source = AiTurnSaveIdentity(saveId: saveId, turn: turn);
    if (saveId.isEmpty || playerId.isEmpty || _currentSave != source) {
      return null;
    }

    final token = AiTurnExecutionIdentityToken._(
      TurnOpeningLease(
        saveId: saveId,
        sourceTurn: turn,
        executionPlayerId: playerId,
        generation: _generation,
      ),
    );
    _activeExecution = token;
    _authorizedFollowUpSave = null;
    return token;
  }

  AiTurnExecutionIdentityToken? authorizeFollowUp({
    required String saveId,
    required int previousTurn,
    required int updatedTurn,
    required String playerId,
  }) {
    final token = _activeExecution;
    if (token == null ||
        token.generation != _generation ||
        token.saveId != saveId ||
        token.turn != previousTurn ||
        token.playerId != playerId ||
        updatedTurn < previousTurn ||
        updatedTurn > previousTurn + 1) {
      return null;
    }

    final source = AiTurnSaveIdentity(saveId: saveId, turn: previousTurn);
    final target = AiTurnSaveIdentity(saveId: saveId, turn: updatedTurn);
    if (_currentSave != source && _currentSave != target) return null;

    _authorizedFollowUpSave = target;
    return token;
  }

  AiTurnExecutionIdentityToken? authorizedFollowUpToken({
    required String saveId,
    required int previousTurn,
    required int updatedTurn,
    required String playerId,
  }) {
    final token = _activeExecution;
    final target = AiTurnSaveIdentity(saveId: saveId, turn: updatedTurn);
    if (token == null ||
        token.saveId != saveId ||
        token.turn != previousTurn ||
        token.playerId != playerId ||
        _authorizedFollowUpSave != target ||
        !isCurrent(token)) {
      return null;
    }
    return token;
  }

  bool isCurrent(AiTurnExecutionIdentityToken token) {
    if (!identical(_activeExecution, token) ||
        token.generation != _generation) {
      return false;
    }
    final current = _currentSave;
    if (current == null || current.saveId != token.saveId) return false;
    return current.turn == token.turn || current == _authorizedFollowUpSave;
  }

  void runIfCurrent(
    AiTurnExecutionIdentityToken token,
    void Function() action,
  ) {
    if (isCurrent(token)) action();
  }

  Future<void> runAsyncIfCurrent(
    AiTurnExecutionIdentityToken token,
    Future<void> Function() action,
  ) async {
    if (!isCurrent(token)) return;
    await action();
  }

  void finish(AiTurnExecutionIdentityToken token) {
    if (!identical(_activeExecution, token)) return;
    _activeExecution = null;
    _authorizedFollowUpSave = null;
  }

  TurnOpeningLease? finishExecution({
    required String saveId,
    required int turn,
    required String playerId,
  }) {
    final token = _activeExecution;
    if (token == null ||
        token.saveId != saveId ||
        token.turn != turn ||
        token.playerId != playerId) {
      return null;
    }
    final lease = token.openingLease;
    finish(token);
    return lease;
  }

  TurnOpeningLease? invalidate() {
    final invalidatedLease = _activeExecution?.openingLease;
    _generation++;
    _currentSave = null;
    _activeExecution = null;
    _authorizedFollowUpSave = null;
    return invalidatedLease;
  }
}
