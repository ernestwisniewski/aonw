import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_value_formatters.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/protocol.dart';

part 'hud_game_outcome_summary_helpers.dart';

enum HudGameOutcomeTone { victory, defeat, draw, complete }

class HudGameOutcomeMetric {
  final String label;
  final String value;

  const HudGameOutcomeMetric({required this.label, required this.value});
}

class HudGameOutcomeSummary {
  final GameOutcome outcome;
  final HudGameOutcomeTone tone;
  final String title;
  final String conditionLabel;
  final String subtitle;
  final String? winnerLabel;
  final List<HudGameOutcomeMetric> metrics;

  const HudGameOutcomeSummary({
    required this.outcome,
    required this.tone,
    required this.title,
    required this.conditionLabel,
    required this.subtitle,
    required this.winnerLabel,
    required this.metrics,
  });

  static HudGameOutcomeSummary? from({
    required AppLocalizations l10n,
    required GameSave gameSave,
    required GameClientState? gameState,
    required WorldMap mapData,
    required String? activePlayerId,
    WireMatch? multiplayerMatch,
    bool networkBackedMultiplayer = false,
    GameOutcomeDetector detector = const GameOutcomeDetector(),
  }) {
    if (networkBackedMultiplayer) {
      final outcome = _authoritativeMultiplayerOutcome(
        gameSave: gameSave,
        match: multiplayerMatch,
      );
      if (outcome == null) return null;
      return HudGameOutcomeSummary._fromOutcome(
        l10n: l10n,
        gameSave: gameSave,
        state: null,
        mapData: mapData,
        activePlayerId: activePlayerId,
        outcome: outcome,
      );
    }
    if (gameState == null) return null;

    final outcome = detector.evaluateCollections(
      playerIds: gameSave.players.map((player) => player.id),
      units: gameState.units,
      cities: gameState.cities,
      artifacts: gameState.artifacts,
      fieldImprovements: gameState.fieldImprovements,
      research: gameState.research,
      playerGold: gameState.playerGold,
      dominationHoldTurnsByPlayerId: gameState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          gameState.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          gameState.mapObjectiveHoldStatesByObjectiveId,
      matchRules: gameSave.matchRules,
      mapData: mapData,
      turn: gameSave.turn,
    );
    if (!outcome.finished) return null;

    return HudGameOutcomeSummary._fromOutcome(
      l10n: l10n,
      gameSave: gameSave,
      state: gameState,
      mapData: mapData,
      activePlayerId: activePlayerId,
      outcome: outcome,
    );
  }

  factory HudGameOutcomeSummary._fromOutcome({
    required AppLocalizations l10n,
    required GameSave gameSave,
    required GameClientState? state,
    required WorldMap mapData,
    required String? activePlayerId,
    required GameOutcome outcome,
  }) {
    final winnerId = outcome.winnerPlayerId;
    final winnerLabel = winnerId == null
        ? null
        : _playerName(gameSave, winnerId);
    final tone = _tone(
      activePlayerId: activePlayerId,
      winnerPlayerId: winnerId,
    );
    final title = switch (tone) {
      HudGameOutcomeTone.victory => l10n.gameOutcomeVictoryTitle,
      HudGameOutcomeTone.defeat => l10n.gameOutcomeDefeatTitle,
      HudGameOutcomeTone.draw => l10n.gameOutcomeDrawTitle,
      HudGameOutcomeTone.complete => l10n.gameOutcomeCompleteTitle,
    };
    final titleLabel = GameText.screenTitle(title);

    return switch (outcome.condition) {
      GameOutcomeCondition.conquest => HudGameOutcomeSummary(
        outcome: outcome,
        tone: tone,
        title: titleLabel,
        conditionLabel: GameText.sectionLabel(
          l10n.gameOutcomeConditionConquest,
        ),
        subtitle: winnerLabel == null
            ? l10n.gameOutcomeConquestNoWinner
            : l10n.gameOutcomeConquestWinner(winnerLabel),
        winnerLabel: winnerLabel,
        metrics: [
          if (winnerLabel != null)
            HudGameOutcomeMetric(
              label: l10n.gameOutcomeWinnerMetric,
              value: winnerLabel,
            ),
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeConditionMetric,
            value: l10n.gameOutcomeEliminationMetric,
          ),
        ],
      ),
      GameOutcomeCondition.domination => _dominationSummary(
        l10n: l10n,
        gameSave: gameSave,
        state: state,
        mapData: mapData,
        outcome: outcome,
        tone: tone,
        title: titleLabel,
        winnerLabel: winnerLabel,
      ),
      GameOutcomeCondition.cultural => _culturalSummary(
        l10n: l10n,
        gameSave: gameSave,
        state: state,
        outcome: outcome,
        tone: tone,
        title: titleLabel,
        winnerLabel: winnerLabel,
      ),
      GameOutcomeCondition.score => HudGameOutcomeSummary(
        outcome: outcome,
        tone: tone,
        title: titleLabel,
        conditionLabel: GameText.sectionLabel(l10n.gameOutcomeConditionScore),
        subtitle: winnerLabel == null
            ? l10n.gameOutcomeScoreNoWinner
            : l10n.gameOutcomeScoreWinner(winnerLabel),
        winnerLabel: winnerLabel,
        metrics: _scoreMetrics(gameSave, outcome.scoreByPlayerId),
      ),
      GameOutcomeCondition.resignation => HudGameOutcomeSummary(
        outcome: outcome,
        tone: tone,
        title: titleLabel,
        conditionLabel: GameText.sectionLabel(
          l10n.gameOutcomeConditionResignation,
        ),
        subtitle: winnerLabel == null
            ? l10n.gameOutcomeResignationNoWinner
            : l10n.gameOutcomeResignationWinner(winnerLabel),
        winnerLabel: winnerLabel,
        metrics: [
          if (winnerLabel != null)
            HudGameOutcomeMetric(
              label: l10n.gameOutcomeWinnerMetric,
              value: winnerLabel,
            ),
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeConditionMetric,
            value: l10n.gameOutcomeConditionResignation,
          ),
        ],
      ),
      GameOutcomeCondition.draw => HudGameOutcomeSummary(
        outcome: outcome,
        tone: HudGameOutcomeTone.draw,
        title: GameText.screenTitle(l10n.gameOutcomeDrawTitle),
        conditionLabel: GameText.sectionLabel(
          l10n.gameOutcomeConditionScoreDraw,
        ),
        subtitle: l10n.gameOutcomeScoreDrawSubtitle,
        winnerLabel: null,
        metrics: _scoreMetrics(gameSave, outcome.scoreByPlayerId),
      ),
      GameOutcomeCondition.ongoing => throw StateError(
        'Cannot build finished outcome summary for ongoing game.',
      ),
    };
  }

  static HudGameOutcomeSummary _dominationSummary({
    required AppLocalizations l10n,
    required GameSave gameSave,
    required GameClientState? state,
    required WorldMap mapData,
    required GameOutcome outcome,
    required HudGameOutcomeTone tone,
    required String title,
    required String? winnerLabel,
  }) {
    final progress = state == null
        ? null
        : const DominationProgressCalculator().snapshotForCities(
            playerIds: gameSave.players.map((player) => player.id),
            cities: state.cities,
            mapData: mapData,
            victoryRules: gameSave.matchRules.victory,
            holdTurnsByPlayerId: state.dominationHoldTurnsByPlayerId,
          );
    final winnerEntry = outcome.winnerPlayerId == null || progress == null
        ? null
        : progress.entryFor(outcome.winnerPlayerId!);
    return HudGameOutcomeSummary(
      outcome: outcome,
      tone: tone,
      title: title,
      conditionLabel: GameText.sectionLabel(
        l10n.gameOutcomeConditionDomination,
      ),
      subtitle: winnerLabel == null
          ? l10n.gameOutcomeDominationNoWinner
          : l10n.gameOutcomeDominationWinner(winnerLabel),
      winnerLabel: winnerLabel,
      metrics: [
        if (winnerLabel != null)
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeWinnerMetric,
            value: winnerLabel,
          ),
        if (winnerEntry != null)
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeMapControlMetric,
            value: percent(winnerEntry.controlPercent, false),
          ),
        if (winnerEntry != null)
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeHoldMetric,
            value: l10n.gameOutcomeTurnsValue(
              winnerEntry.holdTurns,
              winnerEntry.requiredHoldTurns,
            ),
          ),
        if (winnerEntry != null)
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeThresholdMetric,
            value: percent(winnerEntry.requiredControlPercent, false),
          ),
      ],
    );
  }

  static HudGameOutcomeSummary _culturalSummary({
    required AppLocalizations l10n,
    required GameSave gameSave,
    required GameClientState? state,
    required GameOutcome outcome,
    required HudGameOutcomeTone tone,
    required String title,
    required String? winnerLabel,
  }) {
    final winnerId = outcome.winnerPlayerId;
    final victory = gameSave.matchRules.victory;
    final progress = winnerId == null || state == null
        ? null
        : CulturalVictoryProgressCalculator.progressForPlayerFromCollections(
            playerId: winnerId,
            artifacts: state.artifacts,
            cities: state.cities,
            holdTurnsByPlayerId: state.culturalVictoryHoldTurnsByPlayerId,
            requiredArtifactCount: victory.culturalRequiredArtifacts,
            requiredHoldTurns: victory.culturalHoldTurns,
          );
    return HudGameOutcomeSummary(
      outcome: outcome,
      tone: tone,
      title: title,
      conditionLabel: GameText.sectionLabel('Cultural victory'),
      subtitle: winnerLabel == null
          ? 'The Great Heritage Exhibition has concluded.'
          : '$winnerLabel completed the Great Heritage Exhibition.',
      winnerLabel: winnerLabel,
      metrics: [
        if (winnerLabel != null)
          HudGameOutcomeMetric(
            label: l10n.gameOutcomeWinnerMetric,
            value: winnerLabel,
          ),
        HudGameOutcomeMetric(
          label: l10n.gameOutcomeConditionMetric,
          value: 'Great Heritage Exhibition',
        ),
        if (progress != null)
          HudGameOutcomeMetric(
            label: 'Artifacts',
            value:
                '${progress.storedArtifactCount}/${victory.culturalRequiredArtifacts}',
          ),
        if (progress != null)
          HudGameOutcomeMetric(
            label: 'Held',
            value: '${progress.holdTurns}/${victory.culturalHoldTurns} turns',
          ),
      ],
    );
  }

  static List<HudGameOutcomeMetric> _scoreMetrics(
    GameSave gameSave,
    Map<String, int> scoreByPlayerId,
  ) {
    final entries = scoreByPlayerId.entries.toList()
      ..sort((left, right) {
        final scoreCompare = right.value.compareTo(left.value);
        if (scoreCompare != 0) return scoreCompare;
        return left.key.compareTo(right.key);
      });
    return [
      for (final entry in entries.take(4))
        HudGameOutcomeMetric(
          label: _playerName(gameSave, entry.key),
          value: entry.value.toString(),
        ),
    ];
  }
}
