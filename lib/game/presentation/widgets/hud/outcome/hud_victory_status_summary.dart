import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_value_formatters.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/save.dart';

part 'hud_victory_status_cultural.dart';
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
    required GameClientState? gameState,
    required AppLocalizations l10n,
    WorldMap? mapData,
    String? activePlayerId,
    EmpireScoreCalculator scoreCalculator = const EmpireScoreCalculator(),
  }) {
    final victory = gameSave.matchRules.victory;
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
        state: gameState!,
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

  static HudVictoryStatusSummary? _scoreStatus({
    required GameSave gameSave,
    required GameClientState? gameState,
    required AppLocalizations l10n,
    required WorldMap? mapData,
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
    final scores = _victoryScores(
      gameSave,
      gameState,
      mapData,
      scoreCalculator,
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
    required GameClientState gameState,
    required WorldMap mapData,
    required AppLocalizations l10n,
    required String? activePlayerId,
    required HudVictoryStatusSummary? scoreStatus,
  }) {
    final progress = const DominationProgressCalculator().snapshotForCities(
      playerIds: gameSave.players.map((player) => player.id),
      cities: gameState.cities,
      mapData: mapData,
      victoryRules: gameSave.matchRules.victory,
      holdTurnsByPlayerId: gameState.dominationHoldTurnsByPlayerId,
    );
    if (progress.validTileCount == 0) return null;
    final leader = progress.leader;
    if (leader == null) return null;

    final leaderName = GameText.uppercase(
      _playerName(gameSave, leader.playerId),
    );
    final requiredControl = leader.requiredControlPercent;
    final leaderPercent = percent(leader.controlPercent, false, false);
    final requiredPercent = percent(requiredControl, false, false);
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

  static String _playerName(GameSave save, String playerId) {
    return save.playerById(playerId)?.name ?? playerId;
  }
}
