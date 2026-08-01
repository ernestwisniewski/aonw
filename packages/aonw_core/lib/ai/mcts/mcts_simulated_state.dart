import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_combat_command_applier.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_economy_command_applier.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_movement_command_applier.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class SimulatedState {
  final GameView view;
  final List<MctsAction> plannedActions;
  final Set<DomainCommand> usedCommands;
  final int maxPlanningDepth;
  final bool planningEnded;

  SimulatedState({
    required this.view,
    Iterable<MctsAction> plannedActions = const [],
    Iterable<DomainCommand> usedCommands = const {},
    required this.maxPlanningDepth,
    this.planningEnded = false,
  }) : plannedActions = List.unmodifiable(plannedActions),
       usedCommands = Set.unmodifiable(usedCommands);

  factory SimulatedState.fromView(
    GameView view, {
    required int maxPlanningDepth,
  }) {
    return SimulatedState(view: view, maxPlanningDepth: maxPlanningDepth);
  }

  List<GameUnit> get ownUnits => view.ownUnits;

  List<GameUnit> get visibleEnemyUnits => view.visibleEnemyUnits;

  List<GameCity> get ownCities => view.ownCities;

  List<GameCity> get rememberedEnemyCities => view.rememberedEnemyCities;

  PlayerResearchState get ownResearch => view.ownResearch;

  int get depth => plannedActions.length;

  bool get isTerminal => planningEnded || depth >= maxPlanningDepth;

  List<DomainCommand> get plannedCommands => List.unmodifiable(
    plannedActions
        .map((action) => action.toCommand())
        .whereType<DomainCommand>(),
  );

  late final List<GameUnit> visibleTargetableEnemyUnits = List.unmodifiable([
    for (final unit in visibleEnemyUnits)
      if (view.canTargetPlayer(unit.ownerPlayerId)) unit,
  ]);

  late final List<GameCity> rememberedTargetableEnemyCities =
      List.unmodifiable([
        for (final city in rememberedEnemyCities)
          if (view.canTargetPlayer(city.ownerPlayerId)) city,
      ]);

  bool hasCommand(DomainCommand command) => usedCommands.contains(command);

  SimulatedState apply(MctsAction action) {
    if (isTerminal) return this;
    if (action.endsPlanning) {
      return SimulatedState(
        view: view,
        plannedActions: [...plannedActions, action],
        usedCommands: usedCommands,
        maxPlanningDepth: maxPlanningDepth,
        planningEnded: true,
      );
    }

    final command = action.toCommand();
    if (command == null || usedCommands.contains(command)) return this;
    final (:nextView) = _applyCommand(command);
    return SimulatedState(
      view: nextView,
      plannedActions: [...plannedActions, action],
      usedCommands: {...usedCommands, command},
      maxPlanningDepth: maxPlanningDepth,
      planningEnded: depth + 1 >= maxPlanningDepth,
    );
  }

  MctsSimulatedCommandApplication _applyCommand(DomainCommand command) {
    if (_movementCommandApplier.supportsUnitAction(command)) {
      return _movementCommandApplier.applyUnitAction(command);
    }
    if (_usesEconomyCommandApplier(GameEngine.commandFamily(command))) {
      return _economyCommandApplier.applyEngineCommand(command, depth + 1);
    }
    return switch (command) {
      MoveUnitCommand() => (
        nextView: _movementCommandApplier.applyMoveUnit(command).nextView,
      ),
      AttackHexCommand() => _applyEngineCombatCommand(command),
      _ => _unchangedCommandApplication,
    };
  }

  bool _usesEconomyCommandApplier(GameEngineCommandFamily? family) {
    return switch (family) {
      GameEngineCommandFamily.city ||
      GameEngineCommandFamily.production ||
      GameEngineCommandFamily.worker ||
      GameEngineCommandFamily.artifactTrade ||
      GameEngineCommandFamily.research ||
      GameEngineCommandFamily.diplomacy => true,
      _ => false,
    };
  }

  MctsSimulatedCommandApplication _applyEngineCombatCommand(
    AttackHexCommand command,
  ) => _combatCommandApplier.applyAttackHex(command, depth + 1);

  MctsSimulatedEconomyCommandApplier get _economyCommandApplier {
    return MctsSimulatedEconomyCommandApplier(
      view: view,
      ownUnits: ownUnits,
      visibleEnemyUnits: visibleEnemyUnits,
      ownCities: ownCities,
      rememberedEnemyCities: rememberedEnemyCities,
      ownResearch: ownResearch,
    );
  }

  MctsSimulatedMovementCommandApplier get _movementCommandApplier {
    return MctsSimulatedMovementCommandApplier(
      view: view,
      ownUnits: ownUnits,
      ownCities: ownCities,
      rememberedEnemyCities: rememberedEnemyCities,
    );
  }

  MctsSimulatedCombatCommandApplier get _combatCommandApplier {
    return MctsSimulatedCombatCommandApplier(
      view: view,
      ownUnits: ownUnits,
      visibleEnemyUnits: visibleEnemyUnits,
      ownCities: ownCities,
      rememberedEnemyCities: rememberedEnemyCities,
      ownResearch: ownResearch,
    );
  }

  ResearchState get researchState => view.research;

  MctsSimulatedCommandApplication get _unchangedCommandApplication =>
      (nextView: view);
}
