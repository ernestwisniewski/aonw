part of 'hud_victory_status_summary.dart';

bool _shouldShowCulturalBeforeDomination({
  required GameSave gameSave,
  required GameClientState state,
  required WorldMap mapData,
}) {
  final cultural = _culturalLeader(gameSave: gameSave, state: state);
  final domination = const DominationProgressCalculator()
      .snapshotForCities(
        playerIds: gameSave.players.map((player) => player.id),
        cities: state.cities,
        mapData: mapData,
        victoryRules: gameSave.matchRules.victory,
        holdTurnsByPlayerId: state.dominationHoldTurnsByPlayerId,
      )
      .leader;
  if (cultural == null || domination == null) return cultural != null;

  if (domination.atThreshold) {
    if (!cultural.hasFullCollection) return false;
    return cultural.remainingHoldTurns < domination.remainingHoldTurns;
  }
  return cultural.storedArtifactCount > 0;
}

CulturalVictoryProgress? _culturalLeader({
  required GameSave gameSave,
  required GameClientState state,
}) {
  final victory = gameSave.matchRules.victory;
  final playerIds = [
    for (final player in gameSave.players)
      if (player.id.isNotEmpty) player.id,
  ];
  final snapshots =
      [
        for (final playerId in playerIds)
          CulturalVictoryProgressCalculator.progressForPlayerFromCollections(
            playerId: playerId,
            artifacts: state.artifacts,
            cities: state.cities,
            holdTurnsByPlayerId: state.culturalVictoryHoldTurnsByPlayerId,
            requiredArtifactCount: victory.culturalRequiredArtifacts,
            requiredHoldTurns: victory.culturalHoldTurns,
          ),
      ]..sort((left, right) {
        final hold = right.holdTurns.compareTo(left.holdTurns);
        if (hold != 0) return hold;
        final artifacts = right.storedArtifactCount.compareTo(
          left.storedArtifactCount,
        );
        if (artifacts != 0) return artifacts;
        return left.playerId.compareTo(right.playerId);
      });
  if (snapshots.isEmpty || snapshots.first.storedArtifactCount <= 0) {
    return null;
  }
  return snapshots.first;
}

HudVictoryStatusSummary? _culturalStatus({
  required GameSave gameSave,
  required GameClientState gameState,
  required AppLocalizations l10n,
  required String? activePlayerId,
  required HudVictoryStatusSummary? scoreStatus,
}) {
  final victory = gameSave.matchRules.victory;
  final leader = _culturalLeader(gameSave: gameSave, state: gameState);
  if (leader == null) return null;
  final leaderLabel = HudVictoryStatusSummary._playerName(
    gameSave,
    leader.playerId,
  );
  final activePlayerIsLeader =
      activePlayerId != null && activePlayerId == leader.playerId;
  final exhibitionActive = leader.holdTurns > 0;
  final nearVictory =
      leader.storedArtifactCount >= victory.culturalRequiredArtifacts - 1;
  final critical = exhibitionActive || (!activePlayerIsLeader && nearVictory);
  final secondary = exhibitionActive
      ? '${leader.holdTurns}/${victory.culturalHoldTurns} turns'
      : '${leader.storedArtifactCount}/${victory.culturalRequiredArtifacts} artifacts';
  return HudVictoryStatusSummary(
    primaryLabel: GameText.uppercase('Heritage'),
    compactLabel: GameText.uppercase('Culture'),
    secondaryLabel: GameText.uppercase(secondary),
    tooltip: exhibitionActive
        ? '$leaderLabel is holding the Great Heritage Exhibition.'
        : '$leaderLabel leads the world artifact collection.',
    critical: critical,
    details: [
      HudVictoryStatusDetail(
        label: 'Leader',
        value: leaderLabel,
        highlighted: critical,
      ),
      HudVictoryStatusDetail(
        label: 'Stored artifacts',
        value:
            '${leader.storedArtifactCount}/${victory.culturalRequiredArtifacts}',
        highlighted: nearVictory,
      ),
      HudVictoryStatusDetail(
        label: 'Exhibition hold',
        value: '${leader.holdTurns}/${victory.culturalHoldTurns}',
        highlighted: exhibitionActive,
      ),
      if (scoreStatus != null)
        HudVictoryStatusDetail(
          label: l10n.gameOutcomeConditionScore,
          value: scoreStatus.fullLabel,
        ),
    ],
  );
}

String? _leaderLabel({
  required GameSave gameSave,
  required AppLocalizations l10n,
  required Map<String, int> scores,
}) {
  if (scores.isEmpty) return null;

  final entries = scores.entries.toList()
    ..sort((left, right) {
      final scoreCompare = right.value.compareTo(left.value);
      if (scoreCompare != 0) return scoreCompare;
      return left.key.compareTo(right.key);
    });
  final topScore = entries.first.value;
  final topPlayers = [
    for (final entry in entries)
      if (entry.value == topScore) entry.key,
  ];
  if (topPlayers.length != 1) return l10n.victoryScoreDrawLabel(topScore);

  final playerName = HudVictoryStatusSummary._playerName(
    gameSave,
    topPlayers.single,
  );
  return '${GameText.uppercase(playerName)} $topScore';
}

String _tooltip({
  required AppLocalizations l10n,
  required int turnLimit,
  required int remainingTurns,
  required String? leaderLabel,
}) {
  final base = remainingTurns == 0
      ? l10n.victoryScoreLimitReachedTooltip(turnLimit)
      : l10n.victoryScoreFallbackTooltip(remainingTurns, turnLimit);
  if (leaderLabel == null) return base;
  return '$base ${l10n.victoryLeaderTooltip(leaderLabel)}';
}
