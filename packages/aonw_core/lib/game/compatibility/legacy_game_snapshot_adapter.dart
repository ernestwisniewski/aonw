import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';

/// The only compatibility boundary between the split canonical snapshot and
/// the legacy save plus persistent-state representation.
final class LegacyGameSnapshotAdapter {
  const LegacyGameSnapshotAdapter();

  CanonicalGameSnapshot toCanonical({
    required GameSave save,
    required PersistentGameState state,
    int eventLogOffset = 0,
  }) {
    final persistent = state.immutableSnapshot();
    return CanonicalGameSnapshot.snapshot(
      domain: _canonicalDomain(save, persistent),
      session: _canonicalSession(save, persistent.runtimeState),
      metadata: _canonicalMetadata(save),
      interaction: PersistedInteractionState(
        cityFoundingDraft: persistent.runtimeState.cityFoundingDraft,
        pendingAction: persistent.runtimeState.pendingAction,
      ),
      eventLogOffset: eventLogOffset,
    );
  }

  LegacyGameSnapshotParts toLegacy(CanonicalGameSnapshot snapshot) {
    return LegacyGameSnapshotParts(
      save: _legacySave(snapshot),
      state: _legacyPersistentState(snapshot),
      eventLogOffset: snapshot.eventLogOffset,
    );
  }
}

/// Legacy snapshot pieces reconstructed without changing their wire schema.
final class LegacyGameSnapshotParts {
  const LegacyGameSnapshotParts({
    required this.save,
    required this.state,
    required this.eventLogOffset,
  });

  final GameSave save;
  final PersistentGameState state;
  final int eventLogOffset;
}

DomainState _canonicalDomain(GameSave save, PersistentGameState state) {
  final runtime = state.runtimeState;
  return DomainState.snapshot(
    turn: save.turn,
    matchRules: save.matchRules,
    participants: _canonicalParticipants(save, state),
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

List<Player> _canonicalParticipants(GameSave save, PersistentGameState state) {
  final participants = [
    for (final player in save.players)
      player.copyWith(
        colorValue: state.playerColors[player.id] ?? player.colorValue,
        country: state.playerCountries[player.id] ?? player.country,
      ),
  ];
  final includedIds = participants.map((player) => player.id).toSet();
  final missingIds = _knownLegacyPlayerIds(
    save,
    state,
  ).where((playerId) => !includedIds.contains(playerId)).toList()..sort();
  for (final playerId in missingIds) {
    participants.add(_fallbackPlayer(playerId, participants.length, state));
  }
  return participants;
}

Set<String> _knownLegacyPlayerIds(GameSave save, PersistentGameState state) {
  final runtime = state.runtimeState;
  return <String>{
    ...save.playerStates.keys,
    ...state.knownPlayerIds,
    ...state.research.players.keys,
    ...runtime.timeoutStreaksByPlayerId.keys,
    ...runtime.afkPlayerIds,
    ...runtime.kickedPlayerIds,
    for (final attack in runtime.intendedAttacks) attack.declaringPlayerId,
    for (final hold in runtime.mapObjectiveHoldStatesByObjectiveId.values)
      hold.playerId,
    for (final trade in runtime.resourceTradeAgreements) ...[
      trade.exporterPlayerId,
      trade.importerPlayerId,
    ],
    ?runtime.cityFoundingDraft?.ownerPlayerId,
    ?runtime.pendingAction?.ownerPlayerId,
  }..removeWhere((playerId) => playerId.isEmpty);
}

Player _fallbackPlayer(
  String playerId,
  int participantIndex,
  PersistentGameState state,
) {
  return Player(
    id: playerId,
    name: playerId,
    colorValue:
        state.playerColors[playerId] ??
        Player.palette[participantIndex % Player.palette.length],
    country: state.playerCountries[playerId] ?? PlayerCountry.poland,
  );
}

MatchSessionState _canonicalSession(GameSave save, GameRuntimeState runtime) {
  return MatchSessionState.snapshot(
    gameMode: save.gameMode,
    turnStatesByPlayerId: save.playerStates,
    submittedPlayerIds: runtime.submittedPlayerIds,
    timeoutStreaksByPlayerId: runtime.timeoutStreaksByPlayerId,
    afkPlayerIds: runtime.afkPlayerIds,
    kickedPlayerIds: runtime.kickedPlayerIds,
    turnStartedAt: _canonicalTurnStartedAt(save, runtime),
  );
}

DateTime? _canonicalTurnStartedAt(GameSave save, GameRuntimeState runtime) {
  final startedAt = runtime.turnStartedAt;
  if (startedAt != null) return startedAt.toUtc();
  return save.gameMode == GameMode.multiplayer ? save.savedAt.toUtc() : null;
}

GameSnapshotMetadata _canonicalMetadata(GameSave save) {
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

GameSave _legacySave(CanonicalGameSnapshot snapshot) {
  final domain = snapshot.domain;
  final session = snapshot.session;
  final metadata = snapshot.metadata;
  return GameSave(
    id: metadata.id,
    schemaVersion: metadata.schemaVersion,
    name: metadata.name,
    mapName: metadata.world.name,
    mapSource: metadata.world.source,
    turn: domain.turn,
    playerStates: session.turnStatesByPlayerId,
    savedAt: metadata.savedAtUtc,
    camera: CameraState(
      x: metadata.camera.x,
      y: metadata.camera.y,
      zoom: metadata.camera.zoom,
    ),
    matchRules: domain.matchRules,
    players: domain.participants,
    gameMode: session.gameMode,
  );
}

PersistentGameState _legacyPersistentState(CanonicalGameSnapshot snapshot) {
  final domain = snapshot.domain;
  return PersistentGameState.snapshot(
    playerColors: domain.playerColors,
    playerCountries: domain.playerCountries,
    playerGold: domain.playerGold,
    playerWarWeariness: domain.playerWarWeariness,
    playerStabilityNet: domain.playerStabilityNet,
    units: domain.units,
    cities: domain.cities,
    artifacts: domain.artifacts,
    fieldImprovements: domain.fieldImprovements,
    fogOfWar: domain.fogOfWar,
    research: domain.research,
    runtimeState: _legacyRuntimeState(snapshot),
    wonderRegistry: domain.wonderRegistry,
  );
}

GameRuntimeState _legacyRuntimeState(CanonicalGameSnapshot snapshot) {
  final domain = snapshot.domain;
  final session = snapshot.session;
  final interaction = snapshot.interaction;
  return GameRuntimeState.snapshot(
    cityFoundingDraft: interaction.cityFoundingDraft,
    pendingAction: interaction.pendingAction,
    submittedPlayerIds: session.submittedPlayerIds,
    timeoutStreaksByPlayerId: session.timeoutStreaksByPlayerId,
    afkPlayerIds: session.afkPlayerIds,
    kickedPlayerIds: session.kickedPlayerIds,
    intendedAttacks: domain.intendedAttacks,
    diplomacy: domain.diplomacy,
    dominationHoldTurnsByPlayerId: domain.dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId:
        domain.culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId:
        domain.mapObjectiveHoldStatesByObjectiveId,
    resourceTradeAgreements: domain.resourceTradeAgreements,
    turnStartedAt: session.turnStartedAt,
  );
}
