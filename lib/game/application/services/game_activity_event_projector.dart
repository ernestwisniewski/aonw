import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';

abstract final class GameActivityEventProjector {
  static List<LoggedActivityEntry> project({
    required List<GameEvent> events,
    required GameState state,
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    final activityEvents = [
      ...events,
      ..._civilizationMetEvents(
        state,
        previousState,
        playerIds: _civilizationMetPlayerIds(
          state,
          previousState,
          visiblePlayerId: visiblePlayerId,
        ),
      ),
    ];
    if (activityEvents.isEmpty) return const [];

    final projected = <LoggedActivityEntry>[];
    for (var i = 0; i < activityEvents.length; i++) {
      final event = activityEvents[i];
      final descriptor = GameEventDescriptor.forEvent(event);
      if (!descriptor.activityWorthy) continue;
      final playerIds = descriptor.playerIdsFor(
        state: state,
        previousState: previousState,
        visiblePlayerId: visiblePlayerId,
      );
      if (playerIds.isEmpty) continue;
      final context = GameActivityContext.capture(
        event: event,
        state: state,
        previousState: previousState,
      );
      for (final playerId in playerIds) {
        if (visiblePlayerId != null &&
            visiblePlayerId.isNotEmpty &&
            playerId != visiblePlayerId) {
          continue;
        }
        projected.add(
          LoggedActivityEntry(
            eventIndex: i,
            playerId: playerId,
            event: event,
            context: context,
          ),
        );
      }
    }
    return List.unmodifiable(projected);
  }

  static bool isActivityWorthy(GameEvent event) {
    return GameEventDescriptor.forEvent(event).activityWorthy;
  }

  static List<String> playerIdsFor(
    GameEvent event,
    GameState state, {
    GameState? previousState,
    String? visiblePlayerId,
  }) {
    return GameEventDescriptor.forEvent(event).playerIdsFor(
      state: state,
      previousState: previousState,
      visiblePlayerId: visiblePlayerId,
    );
  }

  static List<CivilizationMetEvent> _civilizationMetEvents(
    GameState state,
    GameState? previousState, {
    required List<String> playerIds,
  }) {
    if (previousState == null) return const [];
    if (playerIds.isEmpty) return const [];
    final metEvents = <CivilizationMetEvent>[];
    for (final playerId in playerIds) {
      final previouslyKnown = _contactOpponentPlayerIds(
        previousState,
        playerId,
      );
      final currentlyKnown = _contactOpponentPlayerIds(state, playerId);
      final newlyMet = currentlyKnown.difference(previouslyKnown).toList()
        ..sort();
      for (final metPlayerId in newlyMet) {
        metEvents.add(
          CivilizationMetEvent(playerId: playerId, metPlayerId: metPlayerId),
        );
      }
    }
    return List.unmodifiable(metEvents);
  }

  static List<String> _civilizationMetPlayerIds(
    GameState state,
    GameState? previousState, {
    required String? visiblePlayerId,
  }) {
    if (visiblePlayerId != null && visiblePlayerId.isNotEmpty) {
      return [visiblePlayerId];
    }
    return _playerIds([
      state.activePlayerId,
      previousState?.activePlayerId,
      ...state.playerColors.keys,
      ...state.playerCountries.keys,
      ...?previousState?.playerColors.keys,
      ...?previousState?.playerCountries.keys,
      ...state.fogOfWar.players.keys,
      ...?previousState?.fogOfWar.players.keys,
      for (final unit in state.units) unit.ownerPlayerId,
      ...?previousState?.units.map((unit) => unit.ownerPlayerId),
      for (final city in state.cities) city.ownerPlayerId,
      ...?previousState?.cities.map((city) => city.ownerPlayerId),
    ]);
  }

  static Set<String> _contactOpponentPlayerIds(
    GameState state,
    String playerId,
  ) {
    // Contact keys are durable and add-only for the lifetime of a game. Fog
    // visibility is transient, so it must not define first-contact events.
    final opponents = <String>{};
    for (final (playerAId, playerBId) in state.diplomacy.decodedContactPairs) {
      if (playerAId == playerId) {
        opponents.add(playerBId);
      } else if (playerBId == playerId) {
        opponents.add(playerAId);
      }
    }
    return opponents;
  }

  static List<String> _playerIds(Iterable<String?> playerIds) {
    final ordered = <String>[];
    final seen = <String>{};
    for (final playerId in playerIds) {
      if (playerId == null || playerId.isEmpty || !seen.add(playerId)) {
        continue;
      }
      ordered.add(playerId);
    }
    return List.unmodifiable(ordered);
  }
}
