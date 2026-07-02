import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/civilization/civilization_profile_registry.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_action.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_state.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/ai/strategies/basic_strategy.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/turn.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract interface class MctsSimulator {
  SimulatedState applyAction(SimulatedState state, MctsAction action);

  SimulatedState advanceTurn(SimulatedState state);
}

class TracingMctsSimulator implements MctsSimulator {
  final AiStrategy opponentStrategy;
  final bool simulateOpponentPlans;
  final bool simulateTurnEconomy;

  const TracingMctsSimulator({
    this.opponentStrategy = const BasicStrategy(),
    this.simulateOpponentPlans = true,
    this.simulateTurnEconomy = true,
  });

  @override
  SimulatedState applyAction(SimulatedState state, MctsAction action) {
    return state.apply(action);
  }

  @override
  SimulatedState advanceTurn(SimulatedState state) {
    if (!simulateTurnEconomy) {
      return SimulatedState(
        view: state.view,
        ownUnits: state.ownUnits,
        visibleEnemyUnits: state.visibleEnemyUnits,
        ownCities: state.ownCities,
        rememberedEnemyCities: state.rememberedEnemyCities,
        ownResearch: state.ownResearch,
        plannedActions: state.plannedActions,
        usedCommands: state.usedCommands,
        maxPlanningDepth: state.maxPlanningDepth,
        planningEnded: true,
      );
    }

    final view = state.view;
    final mapDefinition = MctsSimulationProjection.mapDefinitionFrom(
      view.mapData,
    );
    final persistent = MctsSimulationProjection.persistentStateFromView(
      view,
      units: view.movementBlockingUnits,
      cities: [...state.ownCities, ...state.rememberedEnemyCities],
      research: state.researchState,
    );
    final afterOpponentPlans = simulateOpponentPlans
        ? _applyOpponentPlans(
            state: persistent,
            forPlayerId: view.forPlayerId,
            turn: view.turn,
            mapData: view.mapData,
            mapDefinition: mapDefinition,
            ruleset: view.ruleset,
          )
        : persistent;
    final advanced = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: afterOpponentPlans,
      playerIds: _knownPlayerIds(afterOpponentPlans, view.forPlayerId),
      mapData: view.mapData,
      ruleset: view.ruleset,
      mapObjectives: view.mapData.objectives,
    );
    final nextView = GameView.fromPersistentState(
      advanced.state,
      forPlayerId: view.forPlayerId,
      turn: view.turn + 1,
      mapData: view.mapData,
      ruleset: view.ruleset,
      activeHostilePlayerIds: view.activeHostilePlayerIds,
      recentHostilePlayerIds: view.recentHostilePlayerIds,
      pressureTargetPlayerIds: view.pressureTargetPlayerIds,
      defaultNeutralPlayerIds: view.defaultNeutralPlayerIds,
      pendingCityAttackThreats: view.pendingCityAttackThreats,
      ignoreFogOfWar: !view.visibility.isEnabled,
    );
    return SimulatedState(
      view: nextView,
      plannedActions: state.plannedActions,
      usedCommands: state.usedCommands,
      maxPlanningDepth: state.maxPlanningDepth,
      planningEnded: true,
    );
  }

  PersistentGameState _applyOpponentPlans({
    required PersistentGameState state,
    required String forPlayerId,
    required int turn,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    var current = state;
    for (final opponentId in _opponentPlayerIds(current, forPlayerId)) {
      final opponentView = _viewForOpponent(
        state: current,
        opponentId: opponentId,
        turn: turn,
        mapData: mapData,
        ruleset: ruleset,
      );
      if (opponentView.ownUnits.isEmpty && opponentView.ownCities.isEmpty) {
        continue;
      }
      const civRegistry = CivilizationProfileRegistry();
      final civProfile = civRegistry.profileFor(
        current.countryForPlayer(opponentId),
      );
      final plan = opponentStrategy.plan(
        opponentView,
        AiContext(
          ruleset: ruleset,
          mapData: mapData,
          turn: turn,
          rng: AiRng.fromTurn(turn: turn, playerId: opponentId, baseSeed: 0),
          civProfile: civProfile,
          persona: civProfile.defaultPersona,
        ),
      );
      var tick = 1;
      for (final command in plan.commands) {
        if (_isTerminal(command)) continue;
        current = _applyOpponentCommand(
          state: current,
          command: command,
          actorPlayerId: opponentId,
          turn: turn,
          tick: tick,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
        tick += 1;
      }
    }
    return current;
  }

  PersistentGameState _applyOpponentCommand({
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required int turn,
    required int tick,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    return switch (command) {
      MoveUnitCommand() =>
        const PersistentMoveUnitResolver()
            .resolve(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
            )
            .state,
      AttackHexCommand() => _applyOpponentAttack(
        state: state,
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        tick: tick,
        mapDefinition: mapDefinition,
        ruleset: ruleset,
      ),
      SkipUnitTurnCommand() =>
        const PersistentUnitActionResolver()
            .skipUnitTurn(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            )
            .state,
      CancelUnitActionCommand() =>
        const PersistentUnitActionResolver()
            .cancelUnitAction(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            )
            .state,
      FortifyUnitCommand() =>
        const PersistentUnitActionResolver()
            .fortifyUnit(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            )
            .state,
      AutoExploreUnitCommand() =>
        const PersistentUnitActionResolver()
            .autoExploreUnit(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
            )
            .state,
      FoundCityCommand() =>
        const PersistentCityFoundingResolver()
            .foundCity(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
            )
            .state,
      SelectTechnologyCommand() =>
        const PersistentResearchCommandResolver()
            .selectTechnology(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              ruleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      StartBuildingCommand() =>
        const PersistentCityProductionResolver()
            .startBuilding(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      StartUnitProductionCommand() =>
        const PersistentCityProductionResolver()
            .startUnitProduction(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      StartCityProjectCommand() =>
        const PersistentCityProductionResolver()
            .startCityProject(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              cityRuleset: ruleset.city,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      SetCitySpecializationCommand() =>
        const PersistentCityProductionResolver()
            .setCitySpecialization(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            )
            .state,
      SelectWorkerImprovementCommand() =>
        const PersistentWorkerCommandResolver()
            .selectWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      ConfirmWorkerImprovementCommand() =>
        const PersistentWorkerCommandResolver()
            .confirmWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            )
            .state,
      AssignWorkerToHexCommand() =>
        const PersistentWorkerCommandResolver()
            .assignWorkerToHex(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
            )
            .state,
      _ => state,
    };
  }

  PersistentGameState _applyOpponentAttack({
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required int turn,
    required int tick,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    final withIntent = state.copyWith(
      runtimeState: state.runtimeState.copyWith(
        intendedAttacks: [
          IntendedAttack(
            attackerUnitId: command.attackerUnitId,
            defenderCol: command.defenderCol,
            defenderRow: command.defenderRow,
            declaredAtTick: tick,
            declaringPlayerId: actorPlayerId,
            cityConquestAction: command.cityConquestAction,
          ),
        ],
      ),
    );
    final result = PersistentTurnCombatResolver.resolve(
      turn: turn,
      state: withIntent,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    return result.state.copyWith(
      runtimeState: result.state.runtimeState.copyWith(
        intendedAttacks: const [],
      ),
    );
  }

  GameView _viewForOpponent({
    required PersistentGameState state,
    required String opponentId,
    required int turn,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    final ownCities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == opponentId) city,
    ];
    final ownCityIds = {for (final city in ownCities) city.id};
    return GameView(
      forPlayerId: opponentId,
      turn: turn,
      ownUnits: [
        for (final unit in state.units)
          if (unit.ownerPlayerId == opponentId) unit,
      ],
      ownCities: ownCities,
      ownGold: state.playerGold[opponentId] ?? 0,
      ownWarWeariness: state.playerWarWeariness[opponentId] ?? 0,
      ownStabilityNet: state.playerStabilityNet[opponentId] ?? 0,
      ownResearch: state.research.forPlayer(opponentId),
      ownImprovements: [
        for (final improvement in state.fieldImprovements)
          if (_isOwnImprovement(improvement, ownCities, ownCityIds))
            improvement,
      ],
      diplomacy: state.runtimeState.diplomacy,
      visibleEnemyUnits: [
        for (final unit in state.units)
          if (unit.ownerPlayerId != opponentId) unit,
      ],
      rememberedEnemyCities: [
        for (final city in state.cities)
          if (city.ownerPlayerId != opponentId) city,
      ],
      visibility: const FogVisibilityQuery(
        playerId: '',
        state: FogOfWarState.empty,
      ),
      mapData: mapData,
      ruleset: ruleset,
    );
  }

  List<String> _knownPlayerIds(PersistentGameState state, String forPlayerId) {
    final ids = <String>{
      forPlayerId,
      ..._opponentPlayerIds(state, forPlayerId),
    };
    return ids.toList()..sort();
  }

  List<String> _opponentPlayerIds(
    PersistentGameState state,
    String forPlayerId,
  ) {
    final ids = <String>{
      for (final unit in state.units)
        if (unit.ownerPlayerId != forPlayerId) unit.ownerPlayerId,
      for (final city in state.cities)
        if (city.ownerPlayerId != forPlayerId) city.ownerPlayerId,
    };
    return ids.toList()..sort();
  }

  bool _isTerminal(GameCommand command) {
    return command is EndTurnCommand || command is SubmitTurnCommand;
  }

  bool _isOwnImprovement(
    FieldImprovement improvement,
    List<GameCity> ownCities,
    Set<String> ownCityIds,
  ) {
    final builtByCityId = improvement.builtByCityId;
    if (builtByCityId != null) return ownCityIds.contains(builtByCityId);
    return ownCities.any((city) => city.controlsHex(improvement.hex));
  }
}
