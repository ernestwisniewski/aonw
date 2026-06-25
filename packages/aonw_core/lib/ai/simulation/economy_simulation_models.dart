import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_player.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/mcts/mcts_config.dart';
import 'package:aonw_core/ai/mcts/mcts_strategy.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/telemetry.dart';
import 'package:aonw_core/map/domain/map_data.dart';

enum EconomySimulationMctsProfileMode {
  simulation,
  standard,
  interactive,
  batterySaver,
  adaptiveLocalSinglePlayer,
}

class EconomySimulationConfig {
  const EconomySimulationConfig({
    this.turns = 36,
    this.player = const Player(
      id: 'player_1',
      name: 'AI MCTS',
      colorValue: 0xFFDC2626,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: AiStrategyId.mcts,
        difficulty: AiDifficulty.veryHard,
        seed: 1001,
      ),
    ),
    this.opponents = const [],
    this.matchRules = MatchRules.standard,
    this.ruleset = GameRuleset.defaults,
    this.telemetryTargets = BalanceTelemetryTuningTargets.standard,
    this.mctsConfig,
    this.mctsProfileMode = EconomySimulationMctsProfileMode.simulation,
    this.mapData,
  });

  factory EconomySimulationConfig.forGameLength({
    required GameLengthConfig gameLength,
    int? turns,
    Player player = const Player(
      id: 'player_1',
      name: 'AI MCTS',
      colorValue: 0xFFDC2626,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: AiStrategyId.mcts,
        difficulty: AiDifficulty.veryHard,
        seed: 1001,
      ),
    ),
    List<Player> opponents = const [],
    GameRuleset ruleset = GameRuleset.defaults,
    MctsConfig? mctsConfig,
    EconomySimulationMctsProfileMode mctsProfileMode =
        EconomySimulationMctsProfileMode.simulation,
    MapData? mapData,
  }) {
    final matchRules = MatchRules.forGameLength(gameLength);
    return EconomySimulationConfig(
      turns: turns ?? gameLength.turnLimit ?? 36,
      player: player,
      opponents: opponents,
      matchRules: matchRules,
      ruleset: ruleset.copyWith(paceBalance: matchRules.paceBalance),
      telemetryTargets: BalanceTelemetryTuningTargets.forPaceProfile(
        gameLength.paceProfile,
      ),
      mctsConfig: mctsConfig,
      mctsProfileMode: mctsProfileMode,
      mapData: mapData,
    );
  }

  final int turns;
  final Player player;
  final List<Player> opponents;
  final MatchRules matchRules;
  final GameRuleset ruleset;
  final BalanceTelemetryTuningTargets telemetryTargets;
  final MctsConfig? mctsConfig;
  final EconomySimulationMctsProfileMode mctsProfileMode;
  final MapData? mapData;
}

class EconomySimulationResult {
  const EconomySimulationResult({
    required this.state,
    required this.rows,
    required this.rowsByPlayerId,
    required this.appliedCommands,
    required this.appliedCommandRecords,
    required this.rejectedCommands,
    required this.rejectedCommandRecords,
    required this.aiTurnRuntimes,
    required this.telemetry,
  });

  final PersistentGameState state;
  final List<EconomySimulationTurnRow> rows;
  final Map<String, List<EconomySimulationTurnRow>> rowsByPlayerId;
  final List<GameCommand> appliedCommands;
  final List<EconomySimulationAppliedCommand> appliedCommandRecords;
  final List<GameCommand> rejectedCommands;
  final List<EconomySimulationRejectedCommand> rejectedCommandRecords;
  final List<EconomySimulationAiTurnRuntime> aiTurnRuntimes;
  final BalanceTelemetryReport telemetry;

  String toCsv() {
    return [
      EconomySimulationTurnRow.csvHeader.join(','),
      for (final row in rows) row.toCsvFields().map(_csv).join(','),
    ].join('\n');
  }

  static String _csv(Object? value) {
    final text = switch (value) {
      null => '',
      final String text => text,
      final Object value => value.toString(),
    };
    if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }
}

class EconomySimulationAppliedCommand {
  const EconomySimulationAppliedCommand({
    required this.turn,
    required this.tick,
    required this.playerId,
    required this.command,
  });

  final int turn;
  final int tick;
  final String playerId;
  final GameCommand command;
}

class EconomySimulationRejectedCommand {
  const EconomySimulationRejectedCommand({
    required this.turn,
    required this.tick,
    required this.playerId,
    required this.command,
    this.reason,
  });

  final int turn;
  final int tick;
  final String playerId;
  final GameCommand command;
  final String? reason;
}

class EconomySimulationAiTurnRuntime {
  const EconomySimulationAiTurnRuntime({
    required this.turn,
    required this.playerId,
    required this.strategyId,
    required this.profileMode,
    required this.runtimeProfile,
    required this.adaptiveLateGame,
    required this.planningDuration,
    required this.plannedCommands,
    required this.totalUnitCount,
    required this.totalCityCount,
    required this.debugNotes,
    required this.debugMetrics,
  });

  final int turn;
  final String playerId;
  final AiStrategyId strategyId;
  final EconomySimulationMctsProfileMode profileMode;
  final MctsRuntimeProfile? runtimeProfile;
  final bool adaptiveLateGame;
  final Duration planningDuration;
  final int plannedCommands;
  final int totalUnitCount;
  final int totalCityCount;
  final List<String> debugNotes;
  final Map<String, Object?> debugMetrics;
}

class EconomySimulationTurnRow {
  const EconomySimulationTurnRow({
    required this.turn,
    required this.cityCount,
    required this.unitCount,
    required this.unitSupplyCapacity,
    required this.unitSupplyUsed,
    required this.unitSupplyAvailable,
    required this.militaryCount,
    required this.settlerCount,
    required this.workerCount,
    required this.warriorCount,
    required this.archerCount,
    required this.gold,
    required this.cityGoldIncome,
    required this.wealthProjectGold,
    required this.unitUpkeep,
    required this.netGoldPerTurn,
    required this.sciencePerTurn,
    required this.researchProjectScience,
    required this.completedTechCount,
    required this.activeTechnology,
    required this.unlockedTechnologies,
    required this.buildingQueues,
    required this.unitQueues,
    required this.projectQueues,
    required this.wealthProjectQueues,
    required this.researchProjectQueues,
    required this.foundCityCommands,
    required this.startUnitCommands,
    required this.startBuildingCommands,
    required this.startProjectCommands,
    required this.workerJobCommands,
    required this.moveCommands,
    required this.attackCommands,
    required this.rejectedCommands,
    required this.objectiveActionAdvice,
    required this.objectiveActionTarget,
    required this.dominationControlPercent,
    required this.dominationHoldTurns,
    required this.dominationRequiredControlPercent,
    required this.dominationRequiredHoldTurns,
  });

  static const csvHeader = [
    'turn',
    'cities',
    'units',
    'unit_supply_capacity',
    'unit_supply_used',
    'unit_supply_available',
    'military_units',
    'settlers',
    'workers',
    'warriors',
    'archers',
    'gold',
    'city_gold_income',
    'wealth_project_gold',
    'unit_upkeep',
    'net_gold_per_turn',
    'science_per_turn',
    'research_project_science',
    'completed_techs',
    'active_technology',
    'unlocked_technologies',
    'building_queues',
    'unit_queues',
    'project_queues',
    'wealth_project_queues',
    'research_project_queues',
    'found_city_commands',
    'start_unit_commands',
    'start_building_commands',
    'start_project_commands',
    'worker_job_commands',
    'move_commands',
    'attack_commands',
    'rejected_commands',
    'objective_action_advice',
    'objective_action_target',
    'domination_control_percent',
    'domination_hold_turns',
    'domination_required_control_percent',
    'domination_required_hold_turns',
  ];

  final int turn;
  final int cityCount;
  final int unitCount;
  final int unitSupplyCapacity;
  final int unitSupplyUsed;
  final int unitSupplyAvailable;
  final int militaryCount;
  final int settlerCount;
  final int workerCount;
  final int warriorCount;
  final int archerCount;
  final int gold;
  final int cityGoldIncome;
  final int wealthProjectGold;
  final int unitUpkeep;
  final int netGoldPerTurn;
  final int sciencePerTurn;
  final int researchProjectScience;
  final int completedTechCount;
  final String activeTechnology;
  final String unlockedTechnologies;
  final int buildingQueues;
  final int unitQueues;
  final int projectQueues;
  final int wealthProjectQueues;
  final int researchProjectQueues;
  final int foundCityCommands;
  final int startUnitCommands;
  final int startBuildingCommands;
  final int startProjectCommands;
  final int workerJobCommands;
  final int moveCommands;
  final int attackCommands;
  final int rejectedCommands;
  final String objectiveActionAdvice;
  final String objectiveActionTarget;
  final double dominationControlPercent;
  final int dominationHoldTurns;
  final double dominationRequiredControlPercent;
  final int dominationRequiredHoldTurns;

  List<Object> toCsvFields() {
    return [
      turn,
      cityCount,
      unitCount,
      unitSupplyCapacity,
      unitSupplyUsed,
      unitSupplyAvailable,
      militaryCount,
      settlerCount,
      workerCount,
      warriorCount,
      archerCount,
      gold,
      cityGoldIncome,
      wealthProjectGold,
      unitUpkeep,
      netGoldPerTurn,
      sciencePerTurn,
      researchProjectScience,
      completedTechCount,
      activeTechnology,
      unlockedTechnologies,
      buildingQueues,
      unitQueues,
      projectQueues,
      wealthProjectQueues,
      researchProjectQueues,
      foundCityCommands,
      startUnitCommands,
      startBuildingCommands,
      startProjectCommands,
      workerJobCommands,
      moveCommands,
      attackCommands,
      rejectedCommands,
      objectiveActionAdvice,
      objectiveActionTarget,
      dominationControlPercent.toStringAsFixed(2),
      dominationHoldTurns,
      dominationRequiredControlPercent.toStringAsFixed(2),
      dominationRequiredHoldTurns,
    ];
  }

  BalanceTelemetryEndPaceSample toEndPaceSample() {
    return BalanceTelemetryEndPaceSample(
      completedTechnologyCount: completedTechCount,
      sciencePerTurn: sciencePerTurn,
      cityCount: cityCount,
      unitCount: unitCount,
      gold: gold,
      netGoldPerTurn: netGoldPerTurn,
    );
  }
}
