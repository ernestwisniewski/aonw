final class AiTurnRunScheduler {
  final Set<String> _completedTurnKeys;
  String? _scheduledTurnKey;
  bool _running;

  AiTurnRunScheduler({
    Set<String>? completedTurnKeys,
    String? scheduledTurnKey,
    bool running = false,
  }) : _completedTurnKeys = completedTurnKeys ?? <String>{},
       _scheduledTurnKey = scheduledTurnKey,
       _running = running;

  bool get running => _running;

  AiTurnRunRequest? schedule({
    required String saveId,
    required int turn,
    required String playerId,
  }) {
    if (_running) return null;

    final key = turnKey(saveId: saveId, turn: turn, playerId: playerId);
    if (_scheduledTurnKey == key || _completedTurnKeys.contains(key)) {
      return null;
    }

    _scheduledTurnKey = key;
    return AiTurnRunRequest(
      saveId: saveId,
      turn: turn,
      playerId: playerId,
      turnKey: key,
    );
  }

  bool canStart(AiTurnRunRequest request) {
    return !_running && !_completedTurnKeys.contains(request.turnKey);
  }

  void markStarted(AiTurnRunRequest request) {
    _running = true;
    _scheduledTurnKey = request.turnKey;
  }

  void markCompleted(AiTurnRunRequest request) {
    _completedTurnKeys.add(request.turnKey);
  }

  void markFinished(AiTurnRunRequest request) {
    _running = false;
    if (_scheduledTurnKey == request.turnKey) {
      _scheduledTurnKey = null;
    }
  }

  void resetForSave() {
    _completedTurnKeys.clear();
    _scheduledTurnKey = null;
  }

  void resetForTurn() {
    _scheduledTurnKey = null;
  }

  static String turnKey({
    required String saveId,
    required int turn,
    required String playerId,
  }) {
    return '$saveId:$turn:$playerId';
  }
}

final class AiTurnRunRequest {
  final String saveId;
  final int turn;
  final String playerId;
  final String turnKey;

  const AiTurnRunRequest({
    required this.saveId,
    required this.turn,
    required this.playerId,
    required this.turnKey,
  });
}
