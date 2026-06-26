part of 'economy_simulation.dart';

abstract final class _EconomySimulationStrategySelector {
  static _StrategyChoice forPlayer({
    required AiPlayer player,
    required EconomySimulationConfig config,
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    return switch (player.strategyId) {
      AiStrategyId.random => const _StrategyChoice(strategy: RandomStrategy()),
      AiStrategyId.basic ||
      AiStrategyId.scripted ||
      AiStrategyId.utility => const _StrategyChoice(strategy: BasicStrategy()),
      AiStrategyId.mcts => _mctsStrategyFor(
        player: player,
        config: config,
        turn: turn,
        state: state,
        players: players,
      ),
    };
  }

  static _StrategyChoice _mctsStrategyFor({
    required AiPlayer player,
    required EconomySimulationConfig config,
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    final mctsConfig = config.mctsConfig;
    if (mctsConfig != null) {
      return _StrategyChoice(strategy: MctsStrategy(config: mctsConfig));
    }

    final runtimeChoice = _mctsRuntimeChoiceFor(
      mode: config.mctsProfileMode,
      turn: turn,
      state: state,
      players: players,
    );
    final profile = runtimeChoice.profile;
    if (profile != null) {
      return _StrategyChoice(
        strategy: MctsStrategy(runtimeProfile: profile),
        runtimeProfile: profile,
        adaptiveLateGame: runtimeChoice.adaptiveLateGame,
      );
    }

    return _StrategyChoice(
      strategy: MctsStrategy(
        config: _mctsConfigForSimulation(player.difficulty),
      ),
    );
  }

  static _MctsRuntimeChoice _mctsRuntimeChoiceFor({
    required EconomySimulationMctsProfileMode mode,
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    return switch (mode) {
      EconomySimulationMctsProfileMode.simulation => const _MctsRuntimeChoice(),
      EconomySimulationMctsProfileMode.standard => const _MctsRuntimeChoice(
        profile: MctsRuntimeProfile.standard,
      ),
      EconomySimulationMctsProfileMode.interactive => const _MctsRuntimeChoice(
        profile: MctsRuntimeProfile.interactive,
      ),
      EconomySimulationMctsProfileMode.batterySaver => const _MctsRuntimeChoice(
        profile: MctsRuntimeProfile.batterySaver,
      ),
      EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer =>
        _adaptiveLocalSinglePlayerMctsProfile(
          turn: turn,
          state: state,
          players: players,
        ),
    };
  }

  static _MctsRuntimeChoice _adaptiveLocalSinglePlayerMctsProfile({
    required int turn,
    required PersistentGameState state,
    required List<Player> players,
  }) {
    final localSinglePlayer = _isLocalSinglePlayer(players);
    final adaptiveLateGame =
        localSinglePlayer &&
        (turn >= EconomySimulation.adaptiveLateGameTurnThreshold ||
            state.units.length >=
                EconomySimulation.adaptiveLateGameUnitThreshold ||
            state.cities.length >=
                EconomySimulation.adaptiveLateGameCityThreshold);
    return _MctsRuntimeChoice(
      profile: adaptiveLateGame
          ? MctsRuntimeProfile.batterySaver
          : MctsRuntimeProfile.interactive,
      adaptiveLateGame: adaptiveLateGame,
    );
  }

  static bool _isLocalSinglePlayer(List<Player> players) {
    var humanCount = 0;
    var aiCount = 0;
    for (final player in players) {
      switch (player.kind) {
        case PlayerKind.human:
          humanCount += 1;
        case PlayerKind.ai:
          if (player.ai != null) aiCount += 1;
      }
    }
    return humanCount == 1 && aiCount > 0;
  }

  static MctsConfig _mctsConfigForSimulation(AiDifficulty difficulty) {
    return MctsConfig.fromDifficultyProfile(difficulty.profile.simulationMcts);
  }
}

class _StrategyChoice {
  const _StrategyChoice({
    required this.strategy,
    this.runtimeProfile,
    this.adaptiveLateGame = false,
  });

  final AiStrategy strategy;
  final MctsRuntimeProfile? runtimeProfile;
  final bool adaptiveLateGame;
}

class _MctsRuntimeChoice {
  const _MctsRuntimeChoice({this.profile, this.adaptiveLateGame = false});

  final MctsRuntimeProfile? profile;
  final bool adaptiveLateGame;
}
