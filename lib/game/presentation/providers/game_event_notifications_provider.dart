import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/services/game_activity_event_projector.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _maxGameEventNotifications = 10;

final gameEventNotificationsProvider =
    NotifierProvider<
      GameEventNotificationsNotifier,
      List<GameEventNotification>
    >(GameEventNotificationsNotifier.new);

final gameActivityLogPanelRequestProvider =
    NotifierProvider<GameActivityLogPanelRequestNotifier, int>(
      GameActivityLogPanelRequestNotifier.new,
    );

const int _maxActivityLogNotifications = 40;

final gameActivityLogProvider =
    NotifierProvider<GameActivityLogNotifier, List<GameEventNotification>>(
      GameActivityLogNotifier.new,
    );

class GameEventNotification {
  final int id;
  final GameEvent event;
  final GameState state;
  final GameState? previousState;
  final String playerId;
  final int? turn;
  final GameActivityContext context;

  const GameEventNotification({
    required this.id,
    required this.event,
    required this.state,
    required this.playerId,
    this.turn,
    this.context = GameActivityContext.empty,
    this.previousState,
  });

  bool isVisibleTo(String activePlayerId) =>
      activePlayerId.isNotEmpty && playerId == activePlayerId;
}

class GameEventNotificationsNotifier
    extends Notifier<List<GameEventNotification>> {
  int _nextId = 0;

  @override
  List<GameEventNotification> build() => const [];

  void addAll(
    List<GameEvent> events,
    GameState gameState, {
    GameState? previousState,
    String? visiblePlayerId,
    int? turn,
  }) {
    final playerId = visiblePlayerId ?? gameState.activePlayerId;
    if (playerId.isEmpty) return;
    final projected = GameActivityEventProjector.project(
      events: events,
      state: gameState,
      previousState: previousState,
      visiblePlayerId: playerId,
    );
    if (projected.isEmpty) return;

    final added = [
      for (final entry in projected)
        GameEventNotification(
          id: _nextId++,
          event: entry.event,
          state: gameState,
          previousState: previousState,
          playerId: entry.playerId,
          turn: turn,
          context: entry.context,
        ),
    ];
    if (added.isEmpty) return;

    final next = [...state, ...added];
    state = next.length <= _maxGameEventNotifications
        ? List.unmodifiable(next)
        : List.unmodifiable(
            next.skip(next.length - _maxGameEventNotifications),
          );
    ref.read(gameActivityLogProvider.notifier).addAll(added);
  }

  void dismiss(int id) {
    state = [
      for (final notification in state)
        if (notification.id != id) notification,
    ];
  }

  void clear() {
    state = const [];
    _nextId = 0;
    ref.read(gameActivityLogProvider.notifier).clear();
  }
}

class GameActivityLogNotifier extends Notifier<List<GameEventNotification>> {
  @override
  List<GameEventNotification> build() => const [];

  void addAll(Iterable<GameEventNotification> notifications) {
    final added = notifications.toList(growable: false);
    if (added.isEmpty) return;

    final next = [...state, ...added];
    state = next.length <= _maxActivityLogNotifications
        ? List.unmodifiable(next)
        : List.unmodifiable(
            next.skip(next.length - _maxActivityLogNotifications),
          );
  }

  void clear() {
    state = const [];
  }
}

class GameActivityLogPanelRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() {
    state += 1;
  }
}
