import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/game_mode.dart';
import 'package:aonw_core/util/collection_equality.dart';

/// Match lifecycle state that is independent from canonical game rules.
final class MatchSessionState {
  static const Object _unset = Object();

  factory MatchSessionState.snapshot({
    required GameMode gameMode,
    Map<String, PlayerTurnState> turnStatesByPlayerId = const {},
    Set<String> submittedPlayerIds = const {},
    Map<String, int> timeoutStreaksByPlayerId = const {},
    Set<String> afkPlayerIds = const {},
    Set<String> kickedPlayerIds = const {},
    DateTime? turnStartedAt,
  }) {
    return MatchSessionState._owned(
      gameMode: gameMode,
      turnStatesByPlayerId: _immutableMap(turnStatesByPlayerId),
      submittedPlayerIds: _immutableSet(submittedPlayerIds),
      timeoutStreaksByPlayerId: _immutableMap(timeoutStreaksByPlayerId),
      afkPlayerIds: _immutableSet(afkPlayerIds),
      kickedPlayerIds: _immutableSet(kickedPlayerIds),
      turnStartedAt: turnStartedAt?.toUtc(),
    );
  }

  const MatchSessionState._owned({
    required this.gameMode,
    required this.turnStatesByPlayerId,
    required this.submittedPlayerIds,
    required this.timeoutStreaksByPlayerId,
    required this.afkPlayerIds,
    required this.kickedPlayerIds,
    required this.turnStartedAt,
  });

  final GameMode gameMode;
  final Map<String, PlayerTurnState> turnStatesByPlayerId;
  final Set<String> submittedPlayerIds;
  final Map<String, int> timeoutStreaksByPlayerId;
  final Set<String> afkPlayerIds;
  final Set<String> kickedPlayerIds;
  final DateTime? turnStartedAt;

  bool hasSubmitted(String playerId) => submittedPlayerIds.contains(playerId);
  bool isAfk(String playerId) => afkPlayerIds.contains(playerId);
  bool isKicked(String playerId) => kickedPlayerIds.contains(playerId);

  MatchSessionState copyWith({
    GameMode? gameMode,
    Map<String, PlayerTurnState>? turnStatesByPlayerId,
    Set<String>? submittedPlayerIds,
    Map<String, int>? timeoutStreaksByPlayerId,
    Set<String>? afkPlayerIds,
    Set<String>? kickedPlayerIds,
    Object? turnStartedAt = _unset,
  }) {
    return MatchSessionState._owned(
      gameMode: gameMode ?? this.gameMode,
      turnStatesByPlayerId: _copyMap(
        turnStatesByPlayerId,
        this.turnStatesByPlayerId,
      ),
      submittedPlayerIds: _copySet(submittedPlayerIds, this.submittedPlayerIds),
      timeoutStreaksByPlayerId: _copyMap(
        timeoutStreaksByPlayerId,
        this.timeoutStreaksByPlayerId,
      ),
      afkPlayerIds: _copySet(afkPlayerIds, this.afkPlayerIds),
      kickedPlayerIds: _copySet(kickedPlayerIds, this.kickedPlayerIds),
      turnStartedAt: identical(turnStartedAt, _unset)
          ? this.turnStartedAt
          : (turnStartedAt as DateTime?)?.toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MatchSessionState &&
            other.gameMode == gameMode &&
            mapEquals(other.turnStatesByPlayerId, turnStatesByPlayerId) &&
            setEquals(other.submittedPlayerIds, submittedPlayerIds) &&
            mapEquals(
              other.timeoutStreaksByPlayerId,
              timeoutStreaksByPlayerId,
            ) &&
            setEquals(other.afkPlayerIds, afkPlayerIds) &&
            setEquals(other.kickedPlayerIds, kickedPlayerIds) &&
            other.turnStartedAt == turnStartedAt;
  }

  @override
  int get hashCode => Object.hash(
    gameMode,
    mapHash(turnStatesByPlayerId),
    Object.hashAllUnordered(submittedPlayerIds),
    mapHash(timeoutStreaksByPlayerId),
    Object.hashAllUnordered(afkPlayerIds),
    Object.hashAllUnordered(kickedPlayerIds),
    turnStartedAt,
  );
}

Map<K, V> _copyMap<K, V>(Map<K, V>? replacement, Map<K, V> current) {
  return replacement == null ? current : _immutableMap(replacement);
}

Set<T> _copySet<T>(Set<T>? replacement, Set<T> current) {
  return replacement == null ? current : _immutableSet(replacement);
}

Map<K, V> _immutableMap<K, V>(Map<K, V> source) {
  return source.isEmpty ? const {} : Map.unmodifiable(source);
}

Set<T> _immutableSet<T>(Set<T> source) {
  return source.isEmpty ? const {} : Set.unmodifiable(source);
}
