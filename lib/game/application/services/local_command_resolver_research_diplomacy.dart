part of 'local_command_resolver.dart';

extension LocalCommandResolverResearchDiplomacy on LocalCommandResolver {
  LocalCommandResolution _resolveResearchDiplomacyOrReducer({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required GameCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    required GameEngineCommandFamily? engineFamily,
  }) {
    if (engineFamily == GameEngineCommandFamily.research ||
        engineFamily == GameEngineCommandFamily.diplomacy) {
      return _resolveResearchDiplomacy(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
        savedAt: savedAt,
        context: context,
      );
    }
    return _resolveReducerCommand(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: context,
    );
  }

  LocalCommandResolution _resolveResearchDiplomacy({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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

  List<String> _activePlayerIds(SaveSnapshot snapshot) {
    final ids = snapshot.domain.participants
        .map((player) => player.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) return ids;

    return snapshot.session.turnStatesByPlayerId.keys
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
