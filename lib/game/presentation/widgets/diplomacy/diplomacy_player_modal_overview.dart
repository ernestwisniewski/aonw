part of 'diplomacy_player_modal.dart';

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.relation,
    required this.scoreEntries,
    required this.l10n,
    required this.currentTurn,
  });

  final DiplomaticRelation relation;
  final List<DiplomaticScoreEntry> scoreEntries;
  final AppLocalizations l10n;
  final int currentTurn;

  @override
  Widget build(BuildContext context) {
    final remaining = relation.statusExpiresOnTurn == null
        ? null
        : (relation.statusExpiresOnTurn! - currentTurn).clamp(0, 999);
    final attitudeStatus = _attitudeStatus(relation.relationScore);
    final chartEntries = scoreEntries.isEmpty && relation.relationScore != 0
        ? [
            DiplomaticScoreEntry.between(
              playerAId: relation.playerAId,
              playerBId: relation.playerBId,
              turn: relation.lastChangedTurn ?? currentTurn,
              delta: 0,
              scoreAfter: relation.relationScore,
              reason: DiplomaticScoreChangeReason.manual,
            ),
          ]
        : scoreEntries;
    return _Section(
      title: l10n.diplomacyScoreLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.diplomacyTreatyLabel, style: GameUiTheme.chipLabel),
              const Spacer(),
              _RelationDot(status: relation.status),
              const SizedBox(width: 8),
              Text(
                MultiplayerRelationStatusStyle.label(l10n, relation.status),
                style: GameUiTheme.bodyStrong,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.diplomacyAttitudeLabel, style: GameUiTheme.chipLabel),
              const Spacer(),
              _RelationDot(status: attitudeStatus),
              const SizedBox(width: 8),
              Text(
                MultiplayerRelationStatusStyle.label(l10n, attitudeStatus),
                style: GameUiTheme.bodySmall,
              ),
              const SizedBox(width: 10),
              Text(
                relation.relationScore.toString(),
                style: GameUiTheme.cardTitle.copyWith(
                  color: _scoreColor(relation.relationScore),
                ),
              ),
            ],
          ),
          if (remaining != null) ...[
            const SizedBox(height: 6),
            Text(
              l10n.diplomacyTurnsRemaining(remaining),
              style: GameUiTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          _RelationScoreChart(
            entries: chartEntries,
            currentTurn: currentTurn,
            l10n: l10n,
          ),
          _RelationScoreDrivers(entries: scoreEntries, l10n: l10n),
        ],
      ),
    );
  }

  DiplomaticRelationStatus _attitudeStatus(int score) {
    if (score >= DiplomacyState.friendlyScoreThreshold) {
      return DiplomaticRelationStatus.friendly;
    }
    if (score <= DiplomacyState.hostileScoreThreshold) {
      return DiplomaticRelationStatus.hostile;
    }
    return DiplomaticRelationStatus.neutral;
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.l10n,
    required this.gameState,
    required this.activePlayerId,
    required this.targetPlayerId,
  });

  final AppLocalizations l10n;
  final GameState gameState;
  final String activePlayerId;
  final String targetPlayerId;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: l10n.diplomacyStatsTitle,
      child: Column(
        children: [
          _StatRow(
            label: l10n.diplomacyMilitaryStat,
            own: _militaryCount(activePlayerId),
            target: _militaryCount(targetPlayerId),
          ),
          _StatRow(
            label: l10n.diplomacyCitiesStat,
            own: _cityCount(activePlayerId),
            target: _cityCount(targetPlayerId),
          ),
          _StatRow(
            label: l10n.diplomacyExpansionStat,
            own: _controlledHexCount(activePlayerId),
            target: _controlledHexCount(targetPlayerId),
          ),
          _StatRow(
            label: l10n.diplomacyArtifactsStat,
            own: _storedArtifactCount(activePlayerId),
            target: _storedArtifactCount(targetPlayerId),
          ),
          _StatRow(
            label: l10n.diplomacyLastAggressionStat,
            own: _recentAggression(activePlayerId, targetPlayerId),
            target: _recentAggression(targetPlayerId, activePlayerId),
          ),
          const SizedBox(height: 8),
          _ArtifactSummaryLine(
            label: l10n.diplomacyOwnArtifactsLabel,
            names: _storedArtifactNames(activePlayerId),
          ),
          const SizedBox(height: 5),
          _ArtifactSummaryLine(
            label: l10n.diplomacyTargetArtifactsLabel,
            names: _storedArtifactNames(targetPlayerId),
          ),
        ],
      ),
    );
  }

  int _militaryCount(String playerId) {
    return gameState.units
        .where(
          (unit) =>
              unit.ownerPlayerId == playerId &&
              unit.type != GameUnitType.worker &&
              unit.type != GameUnitType.settler,
        )
        .length;
  }

  int _cityCount(String playerId) =>
      gameState.cities.where((city) => city.ownerPlayerId == playerId).length;

  int _controlledHexCount(String playerId) {
    return gameState.cities
        .where((city) => city.ownerPlayerId == playerId)
        .fold<int>(0, (total, city) => total + city.controlledHexes.length);
  }

  int _storedArtifactCount(String playerId) =>
      _storedArtifacts(playerId).length;

  List<String> _storedArtifactNames(String playerId) =>
      _storedArtifacts(playerId)
          .map((artifact) {
            return GameDisplayNames.worldArtifact(l10n, artifact.type);
          })
          .toList(growable: false);

  List<WorldArtifact> _storedArtifacts(String playerId) {
    final ownedCityIds = {
      for (final city in gameState.cities)
        if (city.ownerPlayerId == playerId) city.id,
    };
    return [
      for (final artifact in gameState.artifacts)
        if (artifact.location.isStored &&
            artifact.location.cityId != null &&
            ownedCityIds.contains(artifact.location.cityId))
          artifact,
    ];
  }

  int _recentAggression(String attackerId, String defenderId) {
    return gameState.diplomacy
        .scoreEntriesBetween(attackerId, defenderId)
        .where(
          (entry) =>
              entry.reason == DiplomaticScoreChangeReason.unitAttack ||
              entry.reason == DiplomaticScoreChangeReason.cityAttack ||
              entry.reason == DiplomaticScoreChangeReason.declarationOfWar ||
              entry.reason == DiplomaticScoreChangeReason.warmongerPenalty,
        )
        .length;
  }
}

class _ArtifactSummaryLine extends StatelessWidget {
  const _ArtifactSummaryLine({required this.label, required this.names});

  final String label;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final value = names.isEmpty
        ? AppLocalizations.of(context).commonNoneLower
        : names.take(3).join(', ');
    final overflow = names.length > 3 ? ' +${names.length - 3}' : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GameIcon(
          GameIcons.artifact,
          size: GameIconSize.tiny,
          color: GameUiTheme.gold,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value$overflow',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodySmall.copyWith(
              color: names.isEmpty
                  ? GameUiTheme.textTertiary
                  : GameUiTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
