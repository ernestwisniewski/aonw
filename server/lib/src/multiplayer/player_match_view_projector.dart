import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import '../generated/protocol.dart';

final class MatchRecipient {
  const MatchRecipient({required this.userIdentifier, required this.playerId});

  final String userIdentifier;
  final String playerId;
}

/// Builds a fail-closed, recipient-specific view of canonical match state.
///
/// Canonical snapshots and events remain in the store. Every network boundary
/// must call this projector before returning or publishing them to a client.
final class PlayerMatchViewProjector {
  const PlayerMatchViewProjector();

  WireMatch matchFor(WireMatch canonical, {required String userIdentifier}) {
    final isOwner = canonical.ownerUserId == userIdentifier;
    final owner = canonical.players.where(
      (player) => player.userId == canonical.ownerUserId,
    );
    final publicOwnerId = owner.isEmpty ? canonical.id : owner.first.id;
    return canonical.copyWith(
      ownerUserId: isOwner ? userIdentifier : publicOwnerId,
      players: [
        for (final player in canonical.players)
          player.copyWith(
            userId: player.userId == userIdentifier
                ? userIdentifier
                : player.id,
          ),
      ],
      inviteCode: isOwner ? canonical.inviteCode : null,
    );
  }

  WireSnapshot snapshotFor(WireSnapshot canonical, MatchRecipient recipient) {
    if (canonical.save.isEmpty) {
      return canonical.copyWith(state: _lifecycleState(canonical.state));
    }

    final save = GameSave.fromJson(canonical.save);
    final state = PersistentGameState.fromJson(canonical.state);
    final projectedState = _stateFor(state, recipient.playerId);
    return WireSnapshot(
      v: canonical.v,
      matchId: canonical.matchId,
      offset: canonical.offset,
      save: save
          .copyWith(
            camera: CameraState.zero,
            players: [for (final player in save.players) _publicPlayer(player)],
          )
          .toJson(),
      state: {...projectedState.toJson(), ..._lifecycleState(canonical.state)},
    );
  }

  WireEvent eventFor(WireEvent canonical, MatchRecipient recipient) {
    final isActor = canonical.actorPlayerId == recipient.playerId;
    return WireEvent(
      v: canonical.v,
      matchId: canonical.matchId,
      offset: canonical.offset,
      timestamp: canonical.timestamp,
      actorPlayerId: isActor ? canonical.actorPlayerId : null,
      tick: isActor ? canonical.tick : null,
      command: isActor ? canonical.command : null,
      events: const [],
    );
  }

  WireCommandAck ackFor(WireCommandAck canonical, MatchRecipient recipient) {
    return WireCommandAck(
      v: canonical.v,
      matchId: canonical.matchId,
      accepted: canonical.accepted,
      offset: canonical.offset,
      snapshot: snapshotFor(canonical.snapshot, recipient),
      events: const [],
      reason: canonical.reason,
    );
  }

  MultiplayerServerMessage messageFor(
    MultiplayerServerMessage canonical,
    MatchRecipient recipient,
  ) {
    return MultiplayerServerMessage(
      serverMessageId: canonical.serverMessageId,
      matchId: canonical.matchId,
      offset: canonical.offset,
      match: canonical.match == null
          ? null
          : matchFor(
              canonical.match!,
              userIdentifier: recipient.userIdentifier,
            ),
      snapshot: canonical.snapshot == null
          ? null
          : snapshotFor(canonical.snapshot!, recipient),
      event: canonical.event == null
          ? null
          : eventFor(canonical.event!, recipient),
      ack: canonical.ack == null ? null : ackFor(canonical.ack!, recipient),
    );
  }

  PersistentGameState _stateFor(
    PersistentGameState canonical,
    String playerId,
  ) {
    final visibility = FogVisibilityQuery(
      playerId: playerId,
      state: canonical.fogOfWar,
    );
    final ownCities = {
      for (final city in canonical.cities)
        if (city.ownerPlayerId == playerId) city.id,
    };
    final ownUnitIds = {
      for (final unit in canonical.units)
        if (unit.ownerPlayerId == playerId) unit.id,
    };
    final knownPlayerIds = {
      playerId,
      ...canonical.playerColors.keys,
      ...canonical.playerCountries.keys,
    };
    final units = [
      for (final unit in canonical.units)
        if (unit.ownerPlayerId == playerId)
          unit
        else if (visibility.canSeeDynamicAt(unit.col, unit.row))
          _visibleOpponentUnit(unit),
    ];
    final cities = [
      for (final city in canonical.cities)
        if (city.ownerPlayerId == playerId)
          city
        else if (visibility.canSeeDynamicAt(city.center.col, city.center.row))
          _visibleOpponentCity(city, visibility),
    ];
    return PersistentGameState(
      playerColors: Map<String, int>.from(canonical.playerColors),
      playerCountries: Map<String, PlayerCountry>.from(
        canonical.playerCountries,
      ),
      playerGold: _ownEntry(canonical.playerGold, playerId),
      playerWarWeariness: _ownEntry(canonical.playerWarWeariness, playerId),
      playerStabilityNet: _ownEntry(canonical.playerStabilityNet, playerId),
      units: units,
      cities: cities,
      artifacts: [
        for (final artifact in canonical.artifacts)
          if (_artifactVisible(
            artifact,
            visibility: visibility,
            ownCities: ownCities,
            ownUnitIds: ownUnitIds,
          ))
            artifact,
      ],
      fieldImprovements: [
        for (final improvement in canonical.fieldImprovements)
          if (ownCities.contains(improvement.builtByCityId))
            improvement
          else if (visibility.canSeeDynamicAt(
            improvement.hex.col,
            improvement.hex.row,
          ))
            FieldImprovement(hex: improvement.hex, type: improvement.type),
      ],
      fogOfWar: FogOfWarState(
        players: {playerId: canonical.fogOfWar.fogForPlayer(playerId)},
      ),
      research: ResearchState(
        players: {playerId: canonical.research.forPlayer(playerId)},
      ),
      runtimeState: _runtimeFor(
        canonical.runtimeState,
        playerId,
        knownPlayerIds,
      ),
      wonderRegistry: canonical.wonderRegistry,
    );
  }

  GameRuntimeState _runtimeFor(
    GameRuntimeState canonical,
    String playerId,
    Set<String> knownPlayerIds,
  ) {
    return GameRuntimeState(
      cityFoundingDraft: canonical.cityFoundingDraft?.ownerPlayerId == playerId
          ? canonical.cityFoundingDraft
          : null,
      pendingAction: canonical.pendingAction?.ownerPlayerId == playerId
          ? canonical.pendingAction
          : null,
      submittedPlayerIds: Set<String>.from(canonical.submittedPlayerIds),
      timeoutStreaksByPlayerId: _ownEntry(
        canonical.timeoutStreaksByPlayerId,
        playerId,
      ),
      afkPlayerIds: Set<String>.from(canonical.afkPlayerIds),
      kickedPlayerIds: Set<String>.from(canonical.kickedPlayerIds),
      intendedAttacks: [
        for (final attack in canonical.intendedAttacks)
          if (attack.declaringPlayerId == playerId) attack,
      ],
      diplomacy: _diplomacyFor(canonical.diplomacy, playerId, knownPlayerIds),
      dominationHoldTurnsByPlayerId: _ownEntry(
        canonical.dominationHoldTurnsByPlayerId,
        playerId,
      ),
      culturalVictoryHoldTurnsByPlayerId: _ownEntry(
        canonical.culturalVictoryHoldTurnsByPlayerId,
        playerId,
      ),
      mapObjectiveHoldStatesByObjectiveId: {
        for (final entry
            in canonical.mapObjectiveHoldStatesByObjectiveId.entries)
          if (entry.value.playerId == playerId) entry.key: entry.value,
      },
      resourceTradeAgreements: [
        for (final agreement in canonical.resourceTradeAgreements)
          if (agreement.exporterPlayerId == playerId ||
              agreement.importerPlayerId == playerId)
            agreement,
      ],
      turnStartedAt: canonical.turnStartedAt,
    );
  }

  DiplomacyState _diplomacyFor(
    DiplomacyState canonical,
    String playerId,
    Set<String> knownPlayerIds,
  ) {
    final contactKeys = {
      for (final relation in canonical.relations.values)
        if (relation.other(playerId) != null) relation.key,
      for (final otherPlayerId in knownPlayerIds)
        if (canonical.hasContact(playerId, otherPlayerId))
          DiplomacyState.relationKey(playerId, otherPlayerId),
    };
    return DiplomacyState(
      contactKeys: contactKeys,
      relations: {
        for (final entry in canonical.relations.entries)
          if (entry.value.other(playerId) != null) entry.key: entry.value,
      },
      pendingProposals: {
        for (final entry in canonical.pendingProposals.entries)
          if (entry.value.involves(playerId)) entry.key: entry.value,
      },
      messages: {
        for (final entry in canonical.messages.entries)
          if (entry.value.involves(playerId)) entry.key: entry.value,
      },
      scoreHistory: _scoreHistoryFor(canonical.scoreHistory, playerId),
    );
  }

  Map<String, List<DiplomaticScoreEntry>> _scoreHistoryFor(
    Map<String, List<DiplomaticScoreEntry>> canonical,
    String playerId,
  ) {
    final projected = <String, List<DiplomaticScoreEntry>>{};
    for (final scores in canonical.values) {
      for (final score in scores) {
        if (score.playerAId != playerId && score.playerBId != playerId) {
          continue;
        }
        projected.putIfAbsent(score.key, () => []).add(score);
      }
    }
    return {
      for (final entry in projected.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  Player _publicPlayer(Player player) {
    final ai = player.ai;
    return ai == null
        ? player
        : player.copyWith(
            ai: AiPlayer(
              strategyId: ai.strategyId,
              difficulty: ai.difficulty,
              persona: ai.persona,
              seed: 0,
            ),
          );
  }

  GameUnit _visibleOpponentUnit(GameUnit unit) {
    return GameUnit(
      id: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      type: unit.type,
      name: unit.name,
      col: unit.col,
      row: unit.row,
      movementPoints: 0,
      workerBuildCharges: 0,
      hitPoints: unit.hitPoints,
    );
  }

  GameCity _visibleOpponentCity(GameCity city, FogVisibilityQuery visibility) {
    return GameCity(
      id: city.id,
      ownerPlayerId: city.ownerPlayerId,
      name: city.name,
      center: city.center,
      controlledHexes: [
        for (final hex in city.controlledHexes)
          if (visibility.canSeeDynamicAt(hex.col, hex.row)) hex,
      ],
      hitPoints: city.hitPoints,
    );
  }

  bool _artifactVisible(
    WorldArtifact artifact, {
    required FogVisibilityQuery visibility,
    required Set<String> ownCities,
    required Set<String> ownUnitIds,
  }) {
    final location = artifact.location;
    return switch (location.kind) {
      WorldArtifactLocationKind.map =>
        location.col != null &&
            location.row != null &&
            visibility.canSeeDynamicAt(location.col!, location.row!),
      WorldArtifactLocationKind.excavation =>
        location.unitId != null && ownUnitIds.contains(location.unitId),
      WorldArtifactLocationKind.carried =>
        location.unitId != null && ownUnitIds.contains(location.unitId),
      WorldArtifactLocationKind.stored =>
        location.cityId != null && ownCities.contains(location.cityId),
    };
  }

  Map<String, int> _ownEntry(Map<String, int> values, String playerId) {
    final value = values[playerId];
    return value == null ? const {} : {playerId: value};
  }

  Map<String, dynamic> _lifecycleState(Map<String, dynamic> state) {
    const allowed = {'phase', 'reason', 'mapName'};
    return {
      for (final entry in state.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
  }
}
