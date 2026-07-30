part of 'save_snapshot.dart';

CanonicalGameSnapshot _projectionAfterUpdate(
  CanonicalGameSnapshot previous, {
  required GameSave save,
  required PersistentGameState state,
  required int eventLogOffset,
}) {
  final runtime = state.runtimeState;
  final participants = _projectionParticipants(previous, save, state);
  final turnStartedAt = runtime.turnStartedAt != null
      ? runtime.turnStartedAt!.toUtc()
      : previous.domain.turn == save.turn &&
            previous.session.gameMode == save.gameMode
      ? previous.session.turnStartedAt
      : save.gameMode == GameMode.multiplayer
      ? save.savedAt.toUtc()
      : null;
  return previous.copyWith(
    domain: _projectPersistentDomain(previous, save, state, participants),
    session: previous.session.copyWith(
      gameMode: save.gameMode,
      turnStatesByPlayerId: save.playerStates,
      submittedPlayerIds: runtime.submittedPlayerIds,
      timeoutStreaksByPlayerId: runtime.timeoutStreaksByPlayerId,
      afkPlayerIds: runtime.afkPlayerIds,
      kickedPlayerIds: runtime.kickedPlayerIds,
      turnStartedAt: turnStartedAt,
    ),
    metadata: _projectPersistentMetadata(save),
    interaction: PersistedInteractionState(
      cityFoundingDraft: runtime.cityFoundingDraft,
      pendingAction: runtime.pendingAction,
    ),
    eventLogOffset: eventLogOffset,
  );
}

DomainState _projectPersistentDomain(
  CanonicalGameSnapshot previous,
  GameSave save,
  PersistentGameState state,
  List<Player> participants,
) {
  final runtime = state.runtimeState;
  return previous.domain.copyWith(
    turn: save.turn,
    matchRules: save.matchRules,
    participants: participants,
    playerGold: state.playerGold,
    playerWarWeariness: state.playerWarWeariness,
    playerStabilityNet: state.playerStabilityNet,
    units: state.units,
    cities: state.cities,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    fogOfWar: state.fogOfWar,
    research: state.research,
    wonderRegistry: state.wonderRegistry,
    intendedAttacks: runtime.intendedAttacks,
    diplomacy: runtime.diplomacy,
    resourceTradeAgreements: runtime.resourceTradeAgreements,
    dominationHoldTurnsByPlayerId: runtime.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        runtime.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        runtime.mapObjectiveHoldStatesByObjectiveId,
  );
}

GameSnapshotMetadata _projectPersistentMetadata(GameSave save) {
  return GameSnapshotMetadata(
    id: save.id,
    schemaVersion: save.schemaVersion,
    name: save.name,
    world: WorldReference(name: save.mapName, source: save.mapSource),
    savedAtUtc: save.savedAt,
    camera: GameSnapshotCamera(
      x: save.camera.x,
      y: save.camera.y,
      zoom: save.camera.zoom,
    ),
  );
}

List<Player> _projectionParticipants(
  CanonicalGameSnapshot previous,
  GameSave save,
  PersistentGameState state,
) {
  final runtime = state.runtimeState;
  final participants = <Player>[
    for (final player
        in save.players.isEmpty ? previous.domain.participants : save.players)
      player.copyWith(
        colorValue: state.playerColors[player.id] ?? player.colorValue,
        country: state.playerCountries[player.id] ?? player.country,
      ),
  ];
  final includedPlayerIds = participants.map((player) => player.id).toSet();
  final missingPlayerIds =
      <String>{
          ...save.playerStates.keys,
          ...state.knownPlayerIds,
          ...state.research.players.keys,
          ...runtime.timeoutStreaksByPlayerId.keys,
          ...runtime.afkPlayerIds,
          ...runtime.kickedPlayerIds,
        }.where((playerId) => playerId.isNotEmpty).toList()
        ..removeWhere(includedPlayerIds.contains)
        ..sort();
  for (final playerId in missingPlayerIds) {
    participants.add(
      Player(
        id: playerId,
        name: playerId,
        colorValue:
            state.playerColors[playerId] ??
            Player.palette[participants.length % Player.palette.length],
        country: state.playerCountries[playerId] ?? PlayerCountry.poland,
      ),
    );
  }
  return participants;
}
