import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_event_audience.dart';

typedef PlayerMatchSaveDecoder = GameSave Function(Map<String, dynamic> json);
typedef PlayerMatchStateDecoder =
    PersistentGameState Function(Map<String, dynamic> json);

final class MatchRecipient {
  const MatchRecipient({required this.userIdentifier, required this.playerId});

  final String userIdentifier;
  final String playerId;
}

/// Canonical snapshot decoded once before recipient-specific projection.
final class PreparedPlayerMatchSnapshot {
  const PreparedPlayerMatchSnapshot._({
    required this.canonical,
    required this.publicSave,
    required this.state,
  });

  final WireSnapshot canonical;
  final Map<String, dynamic>? publicSave;
  final PersistentGameState? state;
}

/// Canonical server message prepared once for any number of recipients.
final class PreparedPlayerMatchMessage {
  const PreparedPlayerMatchMessage._({
    required this.canonical,
    required this.snapshot,
    required this.ackSnapshot,
  });

  final MultiplayerServerMessage canonical;
  final PreparedPlayerMatchSnapshot? snapshot;
  final PreparedPlayerMatchSnapshot? ackSnapshot;
}

/// Nominal proof that a server message passed recipient projection.
final class ProjectedPlayerMatchMessage {
  const ProjectedPlayerMatchMessage._(this.wire);

  final MultiplayerServerMessage wire;
}

/// Nominal proof that a match passed recipient projection.
///
/// Implements the canonical wire type, so projected values flow into generated
/// protocol signatures unchanged, while the private constructor forces every
/// boundary that declares this return type through the projector.
extension type const ProjectedWireMatch._(WireMatch wire)
    implements WireMatch {}

/// Nominal proof that a snapshot passed recipient projection.
extension type const ProjectedWireSnapshot._(WireSnapshot wire)
    implements WireSnapshot {}

/// Nominal proof that an event passed recipient projection.
extension type const ProjectedWireEvent._(WireEvent wire)
    implements WireEvent {}

/// Nominal proof that a command ack passed recipient projection.
extension type const ProjectedWireCommandAck._(WireCommandAck wire)
    implements WireCommandAck {}

/// Builds a fail-closed, recipient-specific view of canonical match state.
///
/// Canonical snapshots and events remain in the store. Every network boundary
/// must call this projector before returning or publishing them to a client.
final class PlayerMatchViewProjector {
  const PlayerMatchViewProjector({
    PlayerMatchSaveDecoder decodeSave = GameSave.fromJson,
    PlayerMatchStateDecoder decodeState = PersistentGameState.fromJson,
  }) : _decodeSave = decodeSave,
       _decodeState = decodeState;

  final PlayerMatchSaveDecoder _decodeSave;
  final PlayerMatchStateDecoder _decodeState;

  ProjectedWireMatch matchFor(
    WireMatch canonical, {
    required String userIdentifier,
  }) {
    _requireKnownFields('match', canonical.toJson(), _knownMatchFields);
    for (final player in canonical.players) {
      _requireKnownFields(
        'match player',
        player.toJson(),
        _knownWirePlayerFields,
      );
      final ai = player.ai;
      if (ai != null) {
        _requireKnownFields(
          'match AI player',
          ai.toJson(),
          _knownWireAiPlayerFields,
        );
      }
    }
    final isOwner = canonical.ownerUserId == userIdentifier;
    final owner = canonical.players.where(
      (player) => player.userId == canonical.ownerUserId,
    );
    final publicOwnerId = owner.isEmpty ? canonical.id : owner.first.id;
    return ProjectedWireMatch._(
      canonical.copyWith(
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
      ),
    );
  }

  PreparedPlayerMatchSnapshot prepareSnapshot(WireSnapshot canonical) {
    _requireKnownSnapshotStateFields(canonical.state);
    if (canonical.save.isEmpty) {
      return PreparedPlayerMatchSnapshot._(
        canonical: canonical,
        publicSave: null,
        state: null,
      );
    }
    _requireKnownFields('game save', canonical.save, _knownGameSaveFields);
    final save = _prepareSave(canonical.save);
    return PreparedPlayerMatchSnapshot._(
      canonical: canonical,
      publicSave: Map.unmodifiable(
        save
            .copyWith(
              camera: CameraState.zero,
              players: [
                for (final player in save.players) _publicPlayer(player),
              ],
            )
            .toJson(),
      ),
      state: _decodeState(canonical.state),
    );
  }

  GameSave _prepareSave(Map<String, dynamic> canonical) {
    final save = _decodeSave(canonical);
    for (final player in save.players) {
      _requireKnownFields(
        'game save player',
        player.toJson(),
        _knownGameSavePlayerFields,
      );
    }
    return save;
  }

  ProjectedWireSnapshot snapshotFor(
    WireSnapshot canonical,
    MatchRecipient recipient,
  ) {
    return projectSnapshot(prepareSnapshot(canonical), recipient);
  }

  ProjectedWireSnapshot projectSnapshot(
    PreparedPlayerMatchSnapshot prepared,
    MatchRecipient recipient,
  ) {
    final canonical = prepared.canonical;
    final publicSave = prepared.publicSave;
    final state = prepared.state;
    if (publicSave == null || state == null) {
      return ProjectedWireSnapshot._(
        canonical.copyWith(state: _lifecycleState(canonical.state)),
      );
    }
    final projectedState = _stateFor(state, recipient.playerId);
    return ProjectedWireSnapshot._(
      WireSnapshot(
        v: canonical.v,
        matchId: canonical.matchId,
        offset: canonical.offset,
        save: publicSave,
        state: {
          ...projectedState.toJson(),
          ..._lifecycleState(canonical.state),
        },
      ),
    );
  }

  ProjectedWireEvent eventFor(WireEvent canonical, MatchRecipient recipient) {
    final isActor = canonical.actorPlayerId == recipient.playerId;
    final events = PlayerMatchEventAudience.projectForRecipient(
      canonical.events,
      recipientPlayerId: recipient.playerId,
    );
    final actorIsVisible = isActor || events.isNotEmpty;
    return ProjectedWireEvent._(
      WireEvent(
        v: canonical.v,
        matchId: canonical.matchId,
        offset: canonical.offset,
        timestamp: canonical.timestamp,
        actorPlayerId: actorIsVisible ? canonical.actorPlayerId : null,
        tick: isActor ? canonical.tick : null,
        turn: canonical.turn,
        command: isActor ? canonical.command : null,
        events: events,
      ),
    );
  }

  ProjectedWireCommandAck ackFor(
    WireCommandAck canonical,
    MatchRecipient recipient,
  ) {
    return _ackForPrepared(
      canonical,
      prepareSnapshot(canonical.snapshot),
      recipient,
    );
  }

  ProjectedWireCommandAck _ackForPrepared(
    WireCommandAck canonical,
    PreparedPlayerMatchSnapshot snapshot,
    MatchRecipient recipient,
  ) {
    return ProjectedWireCommandAck._(
      WireCommandAck(
        v: canonical.v,
        matchId: canonical.matchId,
        accepted: canonical.accepted,
        offset: canonical.offset,
        snapshot: projectSnapshot(snapshot, recipient),
        events: PlayerMatchEventAudience.projectForRecipient(
          canonical.events,
          recipientPlayerId: recipient.playerId,
        ),
        reason: canonical.reason,
      ),
    );
  }

  PreparedPlayerMatchMessage prepareMessage(
    MultiplayerServerMessage canonical,
  ) {
    final snapshot = canonical.snapshot == null
        ? null
        : prepareSnapshot(canonical.snapshot!);
    final ackSnapshot = canonical.ack == null
        ? null
        : canonical.ack!.snapshot == canonical.snapshot
        ? snapshot
        : prepareSnapshot(canonical.ack!.snapshot);
    return PreparedPlayerMatchMessage._(
      canonical: canonical,
      snapshot: snapshot,
      ackSnapshot: ackSnapshot,
    );
  }

  MultiplayerServerMessage messageFor(
    MultiplayerServerMessage canonical,
    MatchRecipient recipient,
  ) {
    return projectMessage(prepareMessage(canonical), recipient).wire;
  }

  ProjectedPlayerMatchMessage projectMessage(
    PreparedPlayerMatchMessage prepared,
    MatchRecipient recipient,
  ) {
    final canonical = prepared.canonical;
    return ProjectedPlayerMatchMessage._(
      MultiplayerServerMessage(
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
            : projectSnapshot(prepared.snapshot!, recipient),
        event: canonical.event == null
            ? null
            : eventFor(canonical.event!, recipient),
        ack: canonical.ack == null
            ? null
            : _ackForPrepared(canonical.ack!, prepared.ackSnapshot!, recipient),
      ),
    );
  }

  void _requireKnownSnapshotStateFields(Map<String, dynamic> state) {
    final unknownStateFields = state.keys.toSet().difference(
      _knownSnapshotStateFields,
    );
    if (unknownStateFields.isNotEmpty) {
      final fields = unknownStateFields.toList()..sort();
      throw FormatException(
        'Unreviewed multiplayer snapshot fields: ${fields.join(', ')}.',
      );
    }

    final rawRuntime = state['runtimeState'];
    if (rawRuntime == null) return;
    if (rawRuntime is! Map<Object?, Object?>) {
      throw const FormatException(
        'Multiplayer runtime state must be a JSON object.',
      );
    }
    final runtimeFields = rawRuntime.keys.whereType<String>().toSet();
    if (runtimeFields.length != rawRuntime.length) {
      throw const FormatException(
        'Multiplayer runtime state field names must be strings.',
      );
    }
    final unknownRuntimeFields = runtimeFields.difference(
      _knownRuntimeStateFields,
    );
    if (unknownRuntimeFields.isNotEmpty) {
      final fields = unknownRuntimeFields.toList()..sort();
      throw FormatException(
        'Unreviewed multiplayer runtime fields: ${fields.join(', ')}.',
      );
    }
  }

  void _requireKnownFields(
    String label,
    Map<String, dynamic> value,
    Set<String> knownFields,
  ) {
    final unknownFields = value.keys.toSet().difference(knownFields);
    if (unknownFields.isEmpty) return;
    final fields = unknownFields.toList()..sort();
    throw FormatException(
      'Unreviewed multiplayer $label fields: ${fields.join(', ')}.',
    );
  }

  static const _knownMatchFields = {
    'v',
    'id',
    'ownerUserId',
    'name',
    'mapName',
    'players',
    'maxPlayers',
    'minPlayers',
    'quickplay',
    'turn',
    'state',
    'createdAt',
    'endedAt',
    'outcomeCondition',
    'winnerPlayerId',
    'autoStartAt',
    'inviteCode',
  };

  static const _knownWirePlayerFields = {
    'id',
    'userId',
    'name',
    'colorValue',
    'countryId',
    'kind',
    'connectionState',
    'ready',
    'ai',
  };

  static const _knownWireAiPlayerFields = {
    'strategyId',
    'difficulty',
    'persona',
  };

  static const _knownGameSaveFields = {
    'id',
    'schemaVersion',
    'name',
    'mapName',
    'mapSource',
    'turn',
    'playerStates',
    'savedAt',
    'camera',
    'ruleset',
    'players',
    'gameMode',
  };

  static const _knownGameSavePlayerFields = {
    'id',
    'name',
    'colorValue',
    'country',
    'kind',
    'ai',
  };

  static const _knownSnapshotStateFields = {
    'playerColors',
    'playerCountries',
    'playerGold',
    'playerWarWeariness',
    'playerStabilityNet',
    'units',
    'cities',
    'artifacts',
    'fieldImprovements',
    'fogOfWar',
    'research',
    'runtimeState',
    'wonderRegistry',
    'phase',
    'reason',
    'mapName',
    // Stored lifecycle audit fields are deliberately omitted from output.
    'leftUserIdentifier',
    'resignedUserIdentifier',
  };

  static const _knownRuntimeStateFields = {
    'cityFoundingDraft',
    'pendingAction',
    'submittedPlayerIds',
    'timeoutStreaksByPlayerId',
    'afkPlayerIds',
    'kickedPlayerIds',
    'intendedAttacks',
    'diplomacy',
    'dominationHoldTurnsByPlayerId',
    'culturalVictoryHoldTurnsByPlayerId',
    'mapObjectiveHoldStates',
    'resourceTradeAgreements',
    'turnStartedAt',
  };

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
    return PersistentGameState.snapshot(
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
    return GameRuntimeState.snapshot(
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
    return GameCity.snapshot(
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
