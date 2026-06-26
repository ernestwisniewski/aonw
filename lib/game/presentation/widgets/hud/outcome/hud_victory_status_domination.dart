part of 'hud_victory_status_summary.dart';

String _dominationTooltip({
  required GameSave gameSave,
  required AppLocalizations l10n,
  required DominationProgressEntry leader,
  required DominationProgressEntry? activeEntry,
  required String? activePlayerId,
  required DominationThreat? opponentThreat,
  required HudVictoryStatusSummary? scoreStatus,
}) {
  final leaderName = HudVictoryStatusSummary._playerName(
    gameSave,
    leader.playerId,
  );
  final leaderPercent = _percentLabel(leader.controlPercent);
  final requiredPercent = _percentLabel(leader.requiredControlPercent);
  final hold = _holdDetailLabel(l10n, leader);
  final parts = [
    l10n.victoryDominationTooltip(
      leaderName,
      leaderPercent,
      requiredPercent,
      hold,
    ),
    _dominationPerspectiveTooltip(
      gameSave: gameSave,
      l10n: l10n,
      leader: leader,
      activeEntry: activeEntry,
      activePlayerId: activePlayerId,
    ),
    if (opponentThreat != null) _threatTooltip(l10n, gameSave, opponentThreat),
    if (scoreStatus != null) scoreStatus.tooltip,
  ].where((part) => part.isNotEmpty);
  return parts.join(' ');
}

List<HudVictoryStatusDetail> _dominationDetails({
  required GameSave gameSave,
  required AppLocalizations l10n,
  required DominationProgressEntry leader,
  required DominationProgressEntry? activeEntry,
  required String? activePlayerId,
  required DominationThreat? opponentThreat,
  required HudVictoryStatusSummary? scoreStatus,
}) {
  final leaderName = HudVictoryStatusSummary._playerName(
    gameSave,
    leader.playerId,
  );
  final leaderPercent = _percentLabel(leader.controlPercent);
  final requiredPercent = _percentLabel(leader.requiredControlPercent);
  final activeIsLeader =
      activePlayerId != null && leader.playerId == activePlayerId;

  return [
    HudVictoryStatusDetail(label: l10n.victoryLeaderLabel, value: leaderName),
    HudVictoryStatusDetail(
      label: l10n.victoryControlLabel,
      value: '$leaderPercent% / $requiredPercent%',
      highlighted: leader.atThreshold,
    ),
    HudVictoryStatusDetail(
      label: l10n.victoryHoldLabel,
      value: _holdDetailLabel(l10n, leader),
      highlighted: leader.atThreshold,
    ),
    if (activeEntry != null && !activeIsLeader)
      HudVictoryStatusDetail(
        label: l10n.victoryYouLabel,
        value: _selfDominationLabel(l10n, activeEntry),
      ),
    HudVictoryStatusDetail(
      label: l10n.victoryPressureLabel,
      value: _dominationPressureLabel(
        gameSave: gameSave,
        l10n: l10n,
        leader: leader,
        activeEntry: activeEntry,
        activePlayerId: activePlayerId,
        opponentThreat: opponentThreat,
      ),
      highlighted: activeIsLeader || opponentThreat != null,
    ),
    if (scoreStatus != null)
      HudVictoryStatusDetail(
        label: l10n.victoryFallbackLabel,
        value: scoreStatus.fullLabel,
      ),
  ];
}

String _dominationPerspectiveTooltip({
  required GameSave gameSave,
  required AppLocalizations l10n,
  required DominationProgressEntry leader,
  required DominationProgressEntry? activeEntry,
  required String? activePlayerId,
}) {
  if (activePlayerId == null || activeEntry == null) return '';
  if (leader.playerId == activePlayerId) {
    if (!leader.atThreshold) {
      return l10n.victoryYourGoalGainControl(_percentGapPoints(leader));
    }
    if (leader.remainingHoldTurns == 0) return l10n.victoryYourGoalReady;
    return l10n.victoryYourGoalHold(
      l10n.victoryTurns(leader.remainingHoldTurns),
    );
  }

  final activePercent = _percentLabel(activeEntry.controlPercent);
  final activeRequired = _percentLabel(activeEntry.requiredControlPercent);
  final leaderName = HudVictoryStatusSummary._playerName(
    gameSave,
    leader.playerId,
  );
  if (leader.atThreshold) return l10n.victoryLeaderAboveThreshold(leaderName);
  return l10n.victoryYourProgress(activePercent, activeRequired);
}

String _dominationPressureLabel({
  required GameSave gameSave,
  required AppLocalizations l10n,
  required DominationProgressEntry leader,
  required DominationProgressEntry? activeEntry,
  required String? activePlayerId,
  required DominationThreat? opponentThreat,
}) {
  if (opponentThreat != null) {
    return _threatPressureLabel(l10n, gameSave, opponentThreat);
  }

  final leaderName = HudVictoryStatusSummary._playerName(
    gameSave,
    leader.playerId,
  );
  if (activePlayerId != null && leader.playerId == activePlayerId) {
    if (!leader.atThreshold) {
      return l10n.victoryPressureReachThreshold(_percentGapPoints(leader));
    }
    if (leader.remainingHoldTurns == 0) return l10n.victoryConditionReady;
    return l10n.victoryPressureHold(
      l10n.victoryTurns(leader.remainingHoldTurns),
    );
  }

  if (leader.atThreshold) {
    return l10n.victoryPressureLeaderHolding(
      leaderName,
      l10n.victoryTurns(leader.remainingHoldTurns),
    );
  }

  if (activeEntry != null) {
    return l10n.victoryPressureYourGap(_percentGapPoints(activeEntry));
  }
  return l10n.victoryPressureLeaderGap(leaderName, _percentGapPoints(leader));
}

String _threatTooltip(
  AppLocalizations l10n,
  GameSave gameSave,
  DominationThreat threat,
) {
  final entry = threat.entry;
  final playerName = HudVictoryStatusSummary._playerName(
    gameSave,
    entry.playerId,
  );
  final controlPercent = _percentLabel(entry.controlPercent);
  final requiredPercent = _percentLabel(entry.requiredControlPercent);
  return switch (threat.level) {
    DominationThreatLevel.approachingThreshold => l10n.victoryThreatApproaching(
      playerName,
      controlPercent,
      requiredPercent,
      _percentGapPoints(entry),
    ),
    DominationThreatLevel.holdingThreshold => l10n.victoryThreatHolding(
      playerName,
      _holdDetailLabel(l10n, entry),
    ),
    DominationThreatLevel.imminent => l10n.victoryThreatImminent(
      playerName,
      _holdDetailLabel(l10n, entry),
    ),
  };
}

String _threatPressureLabel(
  AppLocalizations l10n,
  GameSave gameSave,
  DominationThreat threat,
) {
  final playerName = HudVictoryStatusSummary._playerName(
    gameSave,
    threat.entry.playerId,
  );
  return switch (threat.level) {
    DominationThreatLevel.approachingThreshold =>
      l10n.victoryThreatPressureApproaching(
        playerName,
        _percentGapPoints(threat.entry),
      ),
    DominationThreatLevel.holdingThreshold => l10n.victoryThreatPressureBreak(
      playerName,
      l10n.victoryTurns(threat.entry.remainingHoldTurns),
    ),
    DominationThreatLevel.imminent => l10n.victoryThreatPressureBreak(
      playerName,
      l10n.victoryTurns(threat.entry.remainingHoldTurns),
    ),
  };
}

String _selfDominationLabel(
  AppLocalizations l10n,
  DominationProgressEntry entry,
) {
  final percent = _percentLabel(entry.controlPercent);
  final required = _percentLabel(entry.requiredControlPercent);
  if (!entry.atThreshold) return '$percent% / $required%';
  return '$percent% / $required% · ${_holdDetailLabel(l10n, entry)}';
}

String _holdProgressLabel(
  AppLocalizations l10n,
  DominationProgressEntry entry,
) {
  return l10n.victoryHoldCompact(
    entry.holdTurns.clamp(0, entry.requiredHoldTurns).toInt(),
    entry.requiredHoldTurns,
  );
}

String _holdDetailLabel(AppLocalizations l10n, DominationProgressEntry entry) {
  if (!entry.atThreshold) return l10n.victoryBelowThreshold;
  final held = entry.holdTurns.clamp(0, entry.requiredHoldTurns);
  final base = l10n.victoryHoldProgress(held.toInt(), entry.requiredHoldTurns);
  final remaining = entry.remainingHoldTurns;
  if (remaining == 0) return '$base · ${l10n.victoryReady}';
  return '$base · ${l10n.victoryRemainingTurns(remaining)}';
}

int _percentGapPoints(DominationProgressEntry entry) {
  final gap = entry.requiredControlPercent - entry.controlPercent;
  if (gap <= 0) return 0;
  return gap.ceil();
}

String _percentLabel(double value) {
  final rounded = value.round();
  return rounded.toString();
}
