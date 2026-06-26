import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/state.dart';

part 'hud_victory_status_detail.dart';
part 'hud_victory_status_domination.dart';

class HudVictoryStatusSummary {
  final String primaryLabel;
  final String compactLabel;
  final String? secondaryLabel;
  final String tooltip;
  final bool critical;
  final List<HudVictoryStatusDetail> details;

  const HudVictoryStatusSummary({
    required this.primaryLabel,
    required this.compactLabel,
    required this.secondaryLabel,
    required this.tooltip,
    required this.critical,
    this.details = const [],
  });

  String get fullLabel =>
      secondaryLabel == null ? primaryLabel : '$primaryLabel · $secondaryLabel';

  factory HudVictoryStatusSummary.from({
    required GameSave gameSave,
    required GameState? gameState,
    required AppLocalizations l10n,
    MapData? mapData,
    String? activePlayerId,
    EmpireScoreCalculator scoreCalculator = const EmpireScoreCalculator(),
  }) {
    final victory = gameSave.matchRules.victory;
    final persistentState = gameState == null
        ? null
        : _persistentState(gameState);
    final scoreStatus = _scoreStatus(
      gameSave: gameSave,
      gameState: gameState,
      l10n: l10n,
      mapData: mapData,
      scoreCalculator: scoreCalculator,
    );
    if (scoreStatus != null && scoreStatus.critical) return scoreStatus;

    final culturalStatus = victory.culturalEnabled && gameState != null
        ? _culturalStatus(
            gameSave: gameSave,
            gameState: gameState,
            l10n: l10n,
            activePlayerId: activePlayerId,
            scoreStatus: scoreStatus,
          )
        : null;
    final dominationStatus =
        victory.dominationEnabled && gameState != null && mapData != null
        ? _dominationStatus(
            gameSave: gameSave,
            gameState: gameState,
            mapData: mapData,
            l10n: l10n,
            activePlayerId: activePlayerId,
            scoreStatus: scoreStatus,
          )
        : null;

    if (culturalStatus != null && dominationStatus != null) {
      if (_shouldShowCulturalBeforeDomination(
        gameSave: gameSave,
        state: persistentState!,
        mapData: mapData!,
      )) {
        return culturalStatus;
      }
      return dominationStatus;
    }

    if (victory.culturalEnabled && gameState != null) {
      if (culturalStatus != null) return culturalStatus;
    }

    if (victory.dominationEnabled && gameState != null && mapData != null) {
      if (dominationStatus != null) return dominationStatus;
    }

    if (scoreStatus != null) return scoreStatus;

    return HudVictoryStatusSummary(
      primaryLabel: GameText.uppercase(l10n.victoryConquestPrimary),
      compactLabel: GameText.uppercase(l10n.victoryGoalCompact),
      secondaryLabel: GameText.uppercase(l10n.victoryNoLimit),
      tooltip: l10n.victoryConquestTooltip,
      critical: false,
      details: [
        HudVictoryStatusDetail(
          label: l10n.gameOutcomeConditionMetric,
          value: l10n.gameOutcomeEliminationMetric,
        ),
        HudVictoryStatusDetail(
          label: l10n.victoryLimitLabel,
          value: l10n.victoryNoneValue,
        ),
      ],
    );
  }

  static bool _shouldShowCulturalBeforeDomination({
    required GameSave gameSave,
    required PersistentGameState state,
    required MapData mapData,
  }) {
    final cultural = _culturalLeader(gameSave: gameSave, state: state);
    final domination = const DominationProgressCalculator()
        .snapshot(
          playerIds: gameSave.players.map((player) => player.id),
          state: state,
          mapData: mapData,
          victoryRules: gameSave.matchRules.victory,
        )
        .leader;
    if (cultural == null || domination == null) return cultural != null;

    if (domination.atThreshold) {
      if (!cultural.hasFullCollection) return false;
      return cultural.remainingHoldTurns < domination.remainingHoldTurns;
    }
    return cultural.storedArtifactCount > 0;
  }

  static CulturalVictoryProgress? _culturalLeader({
    required GameSave gameSave,
    required PersistentGameState state,
  }) {
    final victory = gameSave.matchRules.victory;
    final playerIds = [
      for (final player in gameSave.players)
        if (player.id.isNotEmpty) player.id,
    ];
    final snapshots =
        [
          for (final playerId in playerIds)
            CulturalVictoryProgressCalculator.progressForPlayer(
              playerId: playerId,
              state: state,
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

  static HudVictoryStatusSummary? _culturalStatus({
    required GameSave gameSave,
    required GameState gameState,
    required AppLocalizations l10n,
    required String? activePlayerId,
    required HudVictoryStatusSummary? scoreStatus,
  }) {
    final victory = gameSave.matchRules.victory;
    final state = _persistentState(gameState);
    final leader = _culturalLeader(gameSave: gameSave, state: state);
    if (leader == null) return null;
    final leaderLabel = _playerName(gameSave, leader.playerId);
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

  static HudVictoryStatusSummary? _scoreStatus({
    required GameSave gameSave,
    required GameState? gameState,
    required AppLocalizations l10n,
    required MapData? mapData,
    required EmpireScoreCalculator scoreCalculator,
  }) {
    final victory = gameSave.matchRules.victory;
    final turnLimit = victory.turnLimit;
    if (!victory.scoreFallbackEnabled || turnLimit == null) {
      return null;
    }

    final remainingTurns = (turnLimit - gameSave.turn)
        .clamp(0, turnLimit)
        .toInt();
    final scores = gameState == null
        ? const <String, int>{}
        : scoreCalculator.scoresFor(
            playerIds: gameSave.players.map((player) => player.id),
            state: _persistentState(gameState),
            mapObjectives: mapData?.objectives ?? const [],
          );
    final leaderLabel = _leaderLabel(
      gameSave: gameSave,
      l10n: l10n,
      scores: scores,
    );
    final primary = remainingTurns == 0
        ? l10n.victoryScoreCapPrimary
        : l10n.victoryScoreRemainingPrimary(remainingTurns);
    final compact = remainingTurns == 0
        ? l10n.victoryScoreCapCompact
        : l10n.victoryTurnsCompact(remainingTurns);
    final tooltip = _tooltip(
      l10n: l10n,
      turnLimit: turnLimit,
      remainingTurns: remainingTurns,
      leaderLabel: leaderLabel,
    );

    return HudVictoryStatusSummary(
      primaryLabel: primary,
      compactLabel: compact,
      secondaryLabel: leaderLabel,
      tooltip: tooltip,
      critical: remainingTurns <= 5,
      details: [
        HudVictoryStatusDetail(
          label: l10n.victoryLimitLabel,
          value: l10n.victoryTurns(turnLimit),
        ),
        HudVictoryStatusDetail(
          label: l10n.victoryRemainingLabel,
          value: l10n.victoryTurns(remainingTurns),
          highlighted: remainingTurns <= 5,
        ),
        if (leaderLabel != null)
          HudVictoryStatusDetail(
            label: l10n.victoryScoreLeaderLabel,
            value: leaderLabel,
          ),
      ],
    );
  }

  static HudVictoryStatusSummary? _dominationStatus({
    required GameSave gameSave,
    required GameState gameState,
    required MapData mapData,
    required AppLocalizations l10n,
    required String? activePlayerId,
    required HudVictoryStatusSummary? scoreStatus,
  }) {
    final progress = const DominationProgressCalculator().snapshot(
      playerIds: gameSave.players.map((player) => player.id),
      state: _persistentState(gameState),
      mapData: mapData,
      victoryRules: gameSave.matchRules.victory,
    );
    if (progress.validTileCount == 0) return null;

    final leader = progress.leader;
    if (leader == null) return null;

    final leaderName = GameText.uppercase(
      _playerName(gameSave, leader.playerId),
    );
    final leaderPercent = _percentLabel(leader.controlPercent);
    final requiredPercent = _percentLabel(leader.requiredControlPercent);
    final secondary = leader.atThreshold
        ? '$leaderName ${_holdProgressLabel(l10n, leader)}'
        : '$leaderName / $requiredPercent%';
    final opponentThreat = activePlayerId == null
        ? null
        : DominationWarningPolicy.topOpponentThreat(
            progress: progress,
            activePlayerId: activePlayerId,
          );
    final activeEntry = activePlayerId == null
        ? null
        : progress.entryFor(activePlayerId);

    return HudVictoryStatusSummary(
      primaryLabel: 'DOM $leaderPercent%',
      compactLabel: '$leaderPercent%',
      secondaryLabel: secondary,
      tooltip: _dominationTooltip(
        gameSave: gameSave,
        l10n: l10n,
        leader: leader,
        activeEntry: activeEntry,
        activePlayerId: activePlayerId,
        opponentThreat: opponentThreat,
        scoreStatus: scoreStatus,
      ),
      critical: opponentThreat != null,
      details: _dominationDetails(
        gameSave: gameSave,
        l10n: l10n,
        leader: leader,
        activeEntry: activeEntry,
        activePlayerId: activePlayerId,
        opponentThreat: opponentThreat,
        scoreStatus: scoreStatus,
      ),
    );
  }

  static PersistentGameState _persistentState(GameState state) {
    return PersistentGameState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      fogOfWar: state.fogOfWar,
      research: state.research,
      runtimeState: state.runtimeState,
    );
  }

  static String? _leaderLabel({
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

    final playerName = _playerName(gameSave, topPlayers.single);
    return '${GameText.uppercase(playerName)} $topScore';
  }

  static String _playerName(GameSave save, String playerId) {
    for (final player in save.players) {
      if (player.id == playerId) return player.name;
    }
    return playerId;
  }

  static String _tooltip({
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
}
