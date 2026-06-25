import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_combat_command_applier.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_economy_command_applier.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_movement_command_applier.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class SimulatedState {
  final GameView _baseView;
  final List<GameUnit> ownUnits;
  final List<GameUnit> visibleEnemyUnits;
  final List<GameCity> ownCities;
  final List<GameCity> rememberedEnemyCities;
  final PlayerResearchState ownResearch;
  final List<MctsAction> plannedActions;
  final Set<GameCommand> usedCommands;
  final int maxPlanningDepth;
  final bool planningEnded;

  SimulatedState({
    required GameView view,
    Iterable<GameUnit>? ownUnits,
    Iterable<GameUnit>? visibleEnemyUnits,
    Iterable<GameCity>? ownCities,
    Iterable<GameCity>? rememberedEnemyCities,
    PlayerResearchState? ownResearch,
    Iterable<MctsAction> plannedActions = const [],
    Iterable<GameCommand> usedCommands = const {},
    required this.maxPlanningDepth,
    this.planningEnded = false,
  }) : _baseView = view,
       ownUnits = List.unmodifiable(ownUnits ?? view.ownUnits),
       visibleEnemyUnits = List.unmodifiable(
         visibleEnemyUnits ?? view.visibleEnemyUnits,
       ),
       ownCities = List.unmodifiable(ownCities ?? view.ownCities),
       rememberedEnemyCities = List.unmodifiable(
         rememberedEnemyCities ?? view.rememberedEnemyCities,
       ),
       ownResearch = ownResearch ?? view.ownResearch,
       plannedActions = List.unmodifiable(plannedActions),
       usedCommands = Set.unmodifiable(usedCommands);

  factory SimulatedState.fromView(
    GameView view, {
    required int maxPlanningDepth,
  }) {
    return SimulatedState(view: view, maxPlanningDepth: maxPlanningDepth);
  }

  GameView get view {
    return GameView(
      forPlayerId: _baseView.forPlayerId,
      turn: _baseView.turn,
      ownUnits: ownUnits,
      ownCities: ownCities,
      artifacts: _baseView.artifacts,
      ownGold: _baseView.ownGold,
      ownResearch: ownResearch,
      ownImprovements: _baseView.ownImprovements,
      diplomacy: _baseView.diplomacy,
      visibleEnemyUnits: visibleEnemyUnits,
      movementBlockingUnits: _currentMovementBlockingUnits(),
      rememberedEnemyCities: rememberedEnemyCities,
      activeHostilePlayerIds: _baseView.activeHostilePlayerIds,
      recentHostilePlayerIds: _baseView.recentHostilePlayerIds,
      pressureTargetPlayerIds: _baseView.pressureTargetPlayerIds,
      defaultNeutralPlayerIds: _baseView.defaultNeutralPlayerIds,
      pendingCityAttackThreats: _baseView.pendingCityAttackThreats,
      visibility: _baseView.visibility,
      mapData: _baseView.mapData,
      ruleset: _baseView.ruleset,
    );
  }

  int get depth => plannedActions.length;

  bool get isTerminal => planningEnded || depth >= maxPlanningDepth;

  List<GameCommand> get plannedCommands => List.unmodifiable(
    plannedActions.map((action) => action.toCommand()).whereType<GameCommand>(),
  );

  late final List<GameUnit> visibleTargetableEnemyUnits = List.unmodifiable([
    for (final unit in visibleEnemyUnits)
      if (_baseView.canTargetPlayer(unit.ownerPlayerId)) unit,
  ]);

  late final List<GameCity> rememberedTargetableEnemyCities =
      List.unmodifiable([
        for (final city in rememberedEnemyCities)
          if (_baseView.canTargetPlayer(city.ownerPlayerId)) city,
      ]);

  bool hasCommand(GameCommand command) => usedCommands.contains(command);

  List<GameUnit> _currentMovementBlockingUnits() {
    final currentOwnById = {for (final unit in ownUnits) unit.id: unit};
    final currentVisibleById = {
      for (final unit in visibleEnemyUnits) unit.id: unit,
    };
    final baseVisibleEnemyIds = {
      for (final unit in _baseView.visibleEnemyUnits) unit.id,
    };
    final blockers = <GameUnit>[];
    final blockerIds = <String>{};

    for (final unit in _baseView.movementBlockingUnits) {
      final currentOwn = currentOwnById[unit.id];
      if (currentOwn != null) {
        blockers.add(currentOwn);
        blockerIds.add(currentOwn.id);
        continue;
      }
      if (unit.ownerPlayerId == _baseView.forPlayerId) continue;

      final currentVisible = currentVisibleById[unit.id];
      if (currentVisible != null) {
        blockers.add(currentVisible);
        blockerIds.add(currentVisible.id);
        continue;
      }
      if (baseVisibleEnemyIds.contains(unit.id)) continue;

      blockers.add(unit);
      blockerIds.add(unit.id);
    }

    for (final unit in ownUnits) {
      if (blockerIds.add(unit.id)) blockers.add(unit);
    }
    for (final unit in visibleEnemyUnits) {
      if (blockerIds.add(unit.id)) blockers.add(unit);
    }
    return List.unmodifiable(blockers);
  }

  SimulatedState apply(MctsAction action) {
    if (isTerminal) return this;
    if (action.endsPlanning) {
      return SimulatedState(
        view: view,
        ownUnits: ownUnits,
        visibleEnemyUnits: visibleEnemyUnits,
        ownCities: ownCities,
        rememberedEnemyCities: rememberedEnemyCities,
        ownResearch: ownResearch,
        plannedActions: [...plannedActions, action],
        usedCommands: usedCommands,
        maxPlanningDepth: maxPlanningDepth,
        planningEnded: true,
      );
    }

    final command = action.toCommand();
    if (command == null || usedCommands.contains(command)) return this;
    final (
      :nextOwnUnits,
      :nextVisibleEnemyUnits,
      :nextOwnCities,
      :nextRememberedEnemyCities,
      :nextOwnResearch,
    ) = _applyCommand(
      command,
    );
    return SimulatedState(
      view: view,
      ownUnits: nextOwnUnits,
      visibleEnemyUnits: nextVisibleEnemyUnits,
      ownCities: nextOwnCities,
      rememberedEnemyCities: nextRememberedEnemyCities,
      ownResearch: nextOwnResearch,
      plannedActions: [...plannedActions, action],
      usedCommands: {...usedCommands, command},
      maxPlanningDepth: maxPlanningDepth,
      planningEnded: depth + 1 >= maxPlanningDepth,
    );
  }

  MctsSimulatedCommandApplication _applyCommand(GameCommand command) {
    return switch (command) {
      MoveUnitCommand() => (
        nextOwnUnits: _movementCommandApplier.applyMoveUnit(command),
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: ownCities,
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: ownResearch,
      ),
      AttackHexCommand() => _combatCommandApplier.applyAttackHex(command),
      FoundCityCommand() => _economyCommandApplier.applyFoundCity(command),
      SelectTechnologyCommand() => (
        nextOwnUnits: ownUnits,
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: ownCities,
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: _economyCommandApplier.applySelectTechnology(command),
      ),
      StartBuildingCommand() => (
        nextOwnUnits: ownUnits,
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: _economyCommandApplier.applyStartBuilding(command),
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: ownResearch,
      ),
      StartUnitProductionCommand() => (
        nextOwnUnits: ownUnits,
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: _economyCommandApplier.applyStartUnitProduction(command),
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: ownResearch,
      ),
      StartCityProjectCommand() => (
        nextOwnUnits: ownUnits,
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: _economyCommandApplier.applyStartCityProject(command),
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: ownResearch,
      ),
      SetCitySpecializationCommand() => (
        nextOwnUnits: ownUnits,
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: _economyCommandApplier.applySetCitySpecialization(
          command,
        ),
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: ownResearch,
      ),
      SelectWorkerImprovementCommand() =>
        _economyCommandApplier.applySelectWorkerImprovement(command),
      AssignWorkerToHexCommand() =>
        _economyCommandApplier.applyAssignWorkerToHex(command),
      CancelUnitActionCommand() => (
        nextOwnUnits: _movementCommandApplier.applyCancelUnitAction(command),
        nextVisibleEnemyUnits: visibleEnemyUnits,
        nextOwnCities: ownCities,
        nextRememberedEnemyCities: rememberedEnemyCities,
        nextOwnResearch: ownResearch,
      ),
      _ => _unchangedCommandApplication,
    };
  }

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

  ResearchState get researchState {
    return ResearchState(players: {_baseView.forPlayerId: ownResearch});
  }

  MctsSimulatedCommandApplication get _unchangedCommandApplication => (
    nextOwnUnits: ownUnits,
    nextVisibleEnemyUnits: visibleEnemyUnits,
    nextOwnCities: ownCities,
    nextRememberedEnemyCities: rememberedEnemyCities,
    nextOwnResearch: ownResearch,
  );
}
