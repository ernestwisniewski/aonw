import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/save.dart';

class HudScorePressureContext {
  final Map<String, EmpireScoreBreakdown> breakdownByPlayerId;
  final Map<String, int> scoreByPlayerId;
  final Map<String, GameObjectiveAdvice> adviceByPlayerId;
  final int? remainingTurns;

  const HudScorePressureContext({
    required this.breakdownByPlayerId,
    required this.scoreByPlayerId,
    required this.adviceByPlayerId,
    required this.remainingTurns,
  });

  static const empty = HudScorePressureContext(
    breakdownByPlayerId: {},
    scoreByPlayerId: {},
    adviceByPlayerId: {},
    remainingTurns: null,
  );

  factory HudScorePressureContext.from({
    required GameSave? gameSave,
    required GameClientState? gameState,
    WorldMap? mapData,
  }) {
    if (gameSave == null) return empty;

    final remainingTurns = _scoreRemainingTurns(gameSave);
    final breakdownByPlayerId = _scoreBreakdownByPlayerId(
      gameSave: gameSave,
      gameState: gameState,
      mapData: mapData,
    );
    return HudScorePressureContext(
      breakdownByPlayerId: breakdownByPlayerId,
      scoreByPlayerId: {
        for (final entry in breakdownByPlayerId.entries)
          entry.key: entry.value.total,
      },
      adviceByPlayerId: {
        for (final playerId in breakdownByPlayerId.keys)
          playerId: const ScorePressureAdvisor().adviceFor(
            playerId: playerId,
            breakdownByPlayerId: breakdownByPlayerId,
          ),
      },
      remainingTurns: remainingTurns,
    );
  }

  static int? _scoreRemainingTurns(GameSave gameSave) {
    final victory = gameSave.matchRules.victory;
    final turnLimit = victory.turnLimit;
    if (!victory.scoreFallbackEnabled || turnLimit == null) return null;
    return (turnLimit - gameSave.turn).clamp(0, turnLimit).toInt();
  }

  static Map<String, EmpireScoreBreakdown> _scoreBreakdownByPlayerId({
    required GameSave gameSave,
    required GameClientState? gameState,
    required WorldMap? mapData,
  }) {
    final victory = gameSave.matchRules.victory;
    if (!victory.scoreFallbackEnabled ||
        victory.turnLimit == null ||
        gameState == null) {
      return const {};
    }
    return {
      for (final player in gameSave.players)
        if (player.id.isNotEmpty)
          player.id: const EmpireScoreCalculator().scoreForCollections(
            playerId: player.id,
            cities: gameState.cities,
            units: gameState.units,
            fieldImprovements: gameState.fieldImprovements,
            research: gameState.research,
            playerGold: gameState.playerGold,
            mapObjectives: mapData?.objectives ?? const [],
            mapObjectiveHoldStatesByObjectiveId:
                gameState.mapObjectiveHoldStatesByObjectiveId,
          ),
    };
  }
}
