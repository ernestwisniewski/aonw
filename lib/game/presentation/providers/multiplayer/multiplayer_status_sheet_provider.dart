import 'package:aonw/game/domain/game_save.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final multiplayerStatusSheetRequestProvider =
    NotifierProvider<
      MultiplayerStatusSheetRequestController,
      MultiplayerStatusSheetRequest?
    >(MultiplayerStatusSheetRequestController.new);

class MultiplayerStatusSheetRequest {
  const MultiplayerStatusSheetRequest({
    required this.id,
    required this.save,
    required this.activePlayerId,
    required this.key,
  });

  final int id;
  final GameSave save;
  final String activePlayerId;
  final MultiplayerStatusSheetRequestKey key;
}

class MultiplayerStatusSheetRequestKey {
  const MultiplayerStatusSheetRequestKey({
    required this.saveId,
    required this.turn,
    required this.activePlayerId,
  });

  final String saveId;
  final int turn;
  final String activePlayerId;

  factory MultiplayerStatusSheetRequestKey.from({
    required GameSave save,
    required String activePlayerId,
  }) {
    return MultiplayerStatusSheetRequestKey(
      saveId: save.id,
      turn: save.turn,
      activePlayerId: activePlayerId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MultiplayerStatusSheetRequestKey &&
        other.saveId == saveId &&
        other.turn == turn &&
        other.activePlayerId == activePlayerId;
  }

  @override
  int get hashCode => Object.hash(saveId, turn, activePlayerId);
}

class MultiplayerStatusSheetRequestController
    extends Notifier<MultiplayerStatusSheetRequest?> {
  int _nextId = 0;
  MultiplayerStatusSheetRequestKey? _lastRequestKey;

  @override
  MultiplayerStatusSheetRequest? build() => null;

  void request({required GameSave save, required String activePlayerId}) {
    final key = MultiplayerStatusSheetRequestKey.from(
      save: save,
      activePlayerId: activePlayerId,
    );
    if (state?.key == key || _lastRequestKey == key) return;

    _lastRequestKey = key;
    state = MultiplayerStatusSheetRequest(
      id: _nextId++,
      save: save,
      activePlayerId: activePlayerId,
      key: key,
    );
  }

  void consume(int id) {
    if (state?.id == id) state = null;
  }
}
