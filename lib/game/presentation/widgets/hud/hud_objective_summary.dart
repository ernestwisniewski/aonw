import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/outcome.dart';

enum HudObjectiveScoreBreakdownMode { catchUp, protectLead }

class HudObjectiveScoreBreakdown {
  final HudObjectiveScoreBreakdownMode mode;
  final int playerScore;
  final int comparisonScore;
  final List<HudObjectiveScoreBreakdownRow> rows;

  const HudObjectiveScoreBreakdown({
    required this.mode,
    required this.playerScore,
    required this.comparisonScore,
    required this.rows,
  });

  int get delta => (playerScore - comparisonScore).abs();
}

class HudObjectiveScoreBreakdownRow {
  final GameObjectiveAdvice advice;
  final int playerValue;
  final int comparisonValue;
  final int delta;

  const HudObjectiveScoreBreakdownRow({
    required this.advice,
    required this.playerValue,
    required this.comparisonValue,
    required this.delta,
  });
}

class HudObjectiveSummary {
  final List<GameObjectiveProgress> activeObjectives;
  final HudObjectiveScoreBreakdown? scoreBreakdown;
  final bool showOverlay;

  const HudObjectiveSummary({
    required this.activeObjectives,
    this.scoreBreakdown,
    required this.showOverlay,
  });

  factory HudObjectiveSummary.fromGameState({
    required GameState? state,
    MapData? mapData,
    required String activePlayerId,
    required HudPanelModes modes,
    required bool cityProductionOpen,
    required bool resourceBreakdownOpen,
    PaceBalance paceBalance = PaceBalance.unlimited,
    int dominationRequiredHoldTurns = 0,
    Map<String, int> scoreByPlayerId = const {},
    Map<String, GameObjectiveAdvice> scoreAdviceByPlayerId = const {},
    Map<String, EmpireScoreBreakdown> scoreBreakdownByPlayerId = const {},
    int? scoreRemainingTurns,
    int scorePressureWindow = 5,
  }) {
    final activeObjectives = state == null || activePlayerId.isEmpty
        ? const <GameObjectiveProgress>[]
        : GameObjectiveTracker.activeObjectivesForPlayer(
            playerId: activePlayerId,
            cities: state.cities,
            units: state.units,
            fieldImprovements: state.fieldImprovements,
            fogOfWar: state.fogOfWar,
            research: state.research,
            paceBalance: paceBalance,
            dominationHoldTurnsByPlayerId: state.dominationHoldTurnsByPlayerId,
            dominationRequiredHoldTurns: dominationRequiredHoldTurns,
            scoreByPlayerId: scoreByPlayerId,
            scoreAdviceByPlayerId: scoreAdviceByPlayerId,
            scoreRemainingTurns: scoreRemainingTurns,
            scorePressureWindow: scorePressureWindow,
            mapObjectiveProgress: _mapObjectiveProgress(
              state: state,
              mapData: mapData,
            ),
          );

    return HudObjectiveSummary(
      activeObjectives: activeObjectives,
      scoreBreakdown: _scoreBreakdownForObjectives(
        activeObjectives: activeObjectives,
        activePlayerId: activePlayerId,
        scoreBreakdownByPlayerId: scoreBreakdownByPlayerId,
      ),
      showOverlay:
          activeObjectives.isNotEmpty &&
          modes.objectives &&
          !modes.technology &&
          !cityProductionOpen &&
          !modes.empire &&
          !modes.activityLog &&
          !resourceBreakdownOpen,
    );
  }

  static List<MapObjectiveProgress> _mapObjectiveProgress({
    required GameState? state,
    required MapData? mapData,
  }) {
    if (state == null || mapData == null || mapData.objectives.isEmpty) {
      return const [];
    }
    return MapObjectiveRules.snapshot(
      objectives: mapData.objectives,
      cities: state.cities,
      units: state.units,
      holdStatesByObjectiveId: state.mapObjectiveHoldStatesByObjectiveId,
    ).entries;
  }

  static HudObjectiveScoreBreakdown? _scoreBreakdownForObjectives({
    required List<GameObjectiveProgress> activeObjectives,
    required String activePlayerId,
    required Map<String, EmpireScoreBreakdown> scoreBreakdownByPlayerId,
  }) {
    final scoreObjective = _scorePressureObjective(activeObjectives);
    if (scoreObjective == null || activePlayerId.isEmpty) return null;

    final activeBreakdown = scoreBreakdownByPlayerId[activePlayerId];
    if (activeBreakdown == null) return null;

    final mode = scoreObjective.definition.id == GameObjectiveId.holdScoreLead
        ? HudObjectiveScoreBreakdownMode.protectLead
        : HudObjectiveScoreBreakdownMode.catchUp;
    final comparisonBreakdown = _highestScoringOpponent(
      activeBreakdown: activeBreakdown,
      scoreBreakdownByPlayerId: scoreBreakdownByPlayerId,
    );
    if (comparisonBreakdown == null) return null;

    final rows = _scoreBreakdownRows(
      activeBreakdown: activeBreakdown,
      comparisonBreakdown: comparisonBreakdown,
      mode: mode,
    );
    if (rows.isEmpty) return null;

    return HudObjectiveScoreBreakdown(
      mode: mode,
      playerScore: activeBreakdown.total,
      comparisonScore: comparisonBreakdown.total,
      rows: rows.take(3).toList(growable: false),
    );
  }

  static GameObjectiveProgress? _scorePressureObjective(
    List<GameObjectiveProgress> objectives,
  ) {
    for (final objective in objectives) {
      if (objective.definition.id == GameObjectiveId.holdScoreLead ||
          objective.definition.id == GameObjectiveId.overtakeScoreLeader) {
        return objective;
      }
    }
    return null;
  }

  static EmpireScoreBreakdown? _highestScoringOpponent({
    required EmpireScoreBreakdown activeBreakdown,
    required Map<String, EmpireScoreBreakdown> scoreBreakdownByPlayerId,
  }) {
    EmpireScoreBreakdown? selected;
    for (final breakdown in scoreBreakdownByPlayerId.values) {
      if (breakdown.playerId == activeBreakdown.playerId) continue;
      if (selected == null || breakdown.total > selected.total) {
        selected = breakdown;
      }
    }
    return selected;
  }

  static List<HudObjectiveScoreBreakdownRow> _scoreBreakdownRows({
    required EmpireScoreBreakdown activeBreakdown,
    required EmpireScoreBreakdown comparisonBreakdown,
    required HudObjectiveScoreBreakdownMode mode,
  }) {
    final candidates = [
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.trainUnit,
        playerValue: activeBreakdown.unitScore,
        comparisonValue: comparisonBreakdown.unitScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.constructBuilding,
        playerValue: activeBreakdown.buildingScore,
        comparisonValue: comparisonBreakdown.buildingScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.improveField,
        playerValue: activeBreakdown.improvementScore,
        comparisonValue: comparisonBreakdown.improvementScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.unlockTechnology,
        playerValue: activeBreakdown.technologyScore,
        comparisonValue: comparisonBreakdown.technologyScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.growPopulation,
        playerValue: activeBreakdown.populationScore,
        comparisonValue: comparisonBreakdown.populationScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.foundCity,
        playerValue: activeBreakdown.cityScore,
        comparisonValue: comparisonBreakdown.cityScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.claimTerritory,
        playerValue:
            activeBreakdown.territoryScore + activeBreakdown.mapObjectiveScore,
        comparisonValue:
            comparisonBreakdown.territoryScore +
            comparisonBreakdown.mapObjectiveScore,
      ),
      _ScoreBreakdownCandidate(
        advice: GameObjectiveAdvice.collectGold,
        playerValue: activeBreakdown.goldScore,
        comparisonValue: comparisonBreakdown.goldScore,
      ),
    ];

    final rows =
        [
          for (final candidate in candidates)
            if (_candidateDelta(candidate, mode) > 0)
              HudObjectiveScoreBreakdownRow(
                advice: candidate.advice,
                playerValue: candidate.playerValue,
                comparisonValue: candidate.comparisonValue,
                delta: _candidateDelta(candidate, mode),
              ),
        ]..sort((a, b) {
          final deltaComparison = b.delta.compareTo(a.delta);
          if (deltaComparison != 0) return deltaComparison;
          return _advicePriority(a.advice).compareTo(_advicePriority(b.advice));
        });
    return rows;
  }

  static int _candidateDelta(
    _ScoreBreakdownCandidate candidate,
    HudObjectiveScoreBreakdownMode mode,
  ) {
    return switch (mode) {
      HudObjectiveScoreBreakdownMode.catchUp =>
        candidate.comparisonValue - candidate.playerValue,
      HudObjectiveScoreBreakdownMode.protectLead =>
        candidate.playerValue - candidate.comparisonValue,
    };
  }

  static int _advicePriority(GameObjectiveAdvice advice) {
    return switch (advice) {
      GameObjectiveAdvice.trainUnit => 0,
      GameObjectiveAdvice.constructBuilding => 1,
      GameObjectiveAdvice.improveField => 2,
      GameObjectiveAdvice.unlockTechnology => 3,
      GameObjectiveAdvice.growPopulation => 4,
      GameObjectiveAdvice.foundCity => 5,
      GameObjectiveAdvice.claimTerritory => 6,
      GameObjectiveAdvice.collectGold => 7,
      GameObjectiveAdvice.protectLead => 8,
    };
  }
}

class _ScoreBreakdownCandidate {
  final GameObjectiveAdvice advice;
  final int playerValue;
  final int comparisonValue;

  const _ScoreBreakdownCandidate({
    required this.advice,
    required this.playerValue,
    required this.comparisonValue,
  });
}
