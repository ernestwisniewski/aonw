import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

/// Fails closed when a multiplayer projection input gains an unreviewed field.
final class PlayerMatchWireSchemaGuard {
  const PlayerMatchWireSchemaGuard();

  void validateMatch(WireMatch match) {
    _requireKnownFields('match', match.toJson(), _knownMatchFields);
    for (final player in match.players) {
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
  }

  void validateSnapshotState(Map<String, dynamic> state) {
    final unknownStateFields = state.keys.toSet().difference(
      _knownSnapshotStateFields,
    );
    if (unknownStateFields.isNotEmpty) {
      final fields = unknownStateFields.toList()..sort();
      throw FormatException(
        'Unreviewed multiplayer snapshot fields: ${fields.join(', ')}.',
      );
    }

    final rawRuntime = state['lifecycle'];
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

  void validateGameSaveEnvelope(Map<String, dynamic> save) {
    _requireKnownFields('game save', save, _knownGameSaveFields);
  }

  void validateGameSavePlayers(Iterable<Player> players) {
    for (final player in players) {
      _requireKnownFields(
        'game save player',
        player.toJson(),
        _knownGameSavePlayerFields,
      );
    }
  }

  void validateCanonicalRoster({
    required GameSave save,
    required Map<String, dynamic> state,
    required CanonicalGameSnapshot canonical,
  }) {
    final rosterIds = _validatedRosterIds(save.players);
    final candidateIds = {
      for (final participant in canonical.domain.participants) participant.id,
    };
    _rejectPrivateOnlyParticipants(
      candidateIds,
      _alreadyPublicPlayerIds(save, state, canonical, rosterIds),
    );
    _validateDiplomacyParticipants(canonical.domain.diplomacy, candidateIds);
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
}

Set<String> _validatedRosterIds(List<Player> players) {
  final rosterIds = {for (final player in players) player.id};
  if (rosterIds.length != players.length ||
      rosterIds.any((playerId) => playerId.isEmpty)) {
    throw const FormatException(
      'Multiplayer game save roster must contain unique, non-empty ids.',
    );
  }
  return rosterIds;
}

Set<String> _alreadyPublicPlayerIds(
  GameSave save,
  Map<String, dynamic> state,
  CanonicalGameSnapshot canonical,
  Set<String> rosterIds,
) {
  final session = canonical.domain;
  return _withoutEmptyPlayerIds({
    ...rosterIds,
    ...save.playerStates.keys,
    ..._stringMapKeys(state['playerColors']),
    ..._stringMapKeys(state['playerCountries']),
    ...session.submittedPlayerIds,
    ...session.afkPlayerIds,
    ...session.kickedPlayerIds,
    ...canonical.domain.wonderRegistry.completedBy.values,
  });
}

Iterable<String> _stringMapKeys(Object? value) {
  return value is Map ? value.keys.whereType<String>() : const [];
}

void _rejectPrivateOnlyParticipants(
  Set<String> candidateIds,
  Set<String> publicIds,
) {
  final privateOnlyIds = candidateIds.difference(publicIds).toList()..sort();
  if (privateOnlyIds.isEmpty) return;
  throw FormatException(
    'Multiplayer snapshot promotes private-only players into its roster: '
    '${privateOnlyIds.join(', ')}.',
  );
}

void _validateDiplomacyParticipants(
  DiplomacyState diplomacy,
  Set<String> participantIds,
) {
  final unknownPlayerIds = _diplomacyPlayerIds(
    diplomacy,
  ).difference(participantIds).toList()..sort();
  if (unknownPlayerIds.isNotEmpty) {
    throw FormatException(
      'Multiplayer diplomacy references unknown players: '
      '${unknownPlayerIds.join(', ')}.',
    );
  }
  final unknownContactKeys =
      diplomacy.contactKeys
          .difference(_knownContactKeys(participantIds))
          .toList()
        ..sort();
  if (unknownContactKeys.isEmpty) return;
  throw FormatException(
    'Multiplayer diplomacy references contacts outside its participants: '
    '${unknownContactKeys.join(', ')}.',
  );
}

Set<String> _diplomacyPlayerIds(DiplomacyState diplomacy) {
  return _withoutEmptyPlayerIds({
    for (final proposal in diplomacy.pendingProposals.values) ...[
      proposal.fromPlayerId,
      proposal.toPlayerId,
    ],
    for (final message in diplomacy.messages.values) ...[
      message.fromPlayerId,
      message.toPlayerId,
    ],
    for (final scores in diplomacy.scoreHistory.values)
      for (final score in scores) ...[score.playerAId, score.playerBId],
  });
}

Set<String> _knownContactKeys(Set<String> playerIds) {
  return {
    for (final playerAId in playerIds)
      for (final playerBId in playerIds)
        if (playerAId.compareTo(playerBId) < 0)
          DiplomacyState.relationKey(playerAId, playerBId),
  };
}

Set<String> _withoutEmptyPlayerIds(Set<String> playerIds) {
  return playerIds..removeWhere((playerId) => playerId.isEmpty);
}

const _knownMatchFields = {
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

const _knownWirePlayerFields = {
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

const _knownWireAiPlayerFields = {'strategyId', 'difficulty', 'persona'};

const _knownGameSaveFields = {
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

const _knownGameSavePlayerFields = {
  'id',
  'name',
  'colorValue',
  'country',
  'kind',
  'ai',
};

const _knownSnapshotStateFields = {
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
  'lifecycle',
  'wonderRegistry',
  'phase',
  'reason',
  'mapName',
  // Stored lifecycle audit fields are deliberately omitted from output.
  'leftUserIdentifier',
  'resignedUserIdentifier',
};

const _knownRuntimeStateFields = {
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
