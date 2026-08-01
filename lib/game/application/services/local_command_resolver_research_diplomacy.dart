part of 'local_command_resolver.dart';

extension LocalCommandResolverResearchDiplomacy on LocalCommandResolver {
  LocalCommandResolution _resolveResearchDiplomacy({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final resolution =
        LocalResearchDiplomacyCommandResolver(
          mapView: reducer.mapData,
          ruleset: reducer.ruleset,
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: currentState,
          command: command,
          savedAt: savedAt,
          context: context,
        );
    return LocalCommandResolution(
      snapshot: resolution.snapshot,
      state: resolution.state,
      events: resolution.events,
      uiEffects: const [],
      context: context,
    );
  }

  List<String> _activePlayerIds(CanonicalGameSnapshot snapshot) {
    final ids = snapshot.domain.participants
        .map((player) => player.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) return ids;

    return snapshot.domain.turnStatesByPlayerId.keys
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
