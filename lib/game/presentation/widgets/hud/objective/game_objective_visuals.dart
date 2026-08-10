import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter/material.dart';

GameIconData objectiveIconFor(GameObjectiveId id) {
  return _objectiveIcons[id]!;
}

const _objectiveIcons = <GameObjectiveId, GameIconData>{
  GameObjectiveId.chooseResearch: GameIcons.science,
  GameObjectiveId.foundCapital: GameIcons.foundCity,
  GameObjectiveId.exploreNearby: GameIcons.visibility,
  GameObjectiveId.queueWorker: GameIcons.production,
  GameObjectiveId.improveFirstHex: GameIcons.food,
  GameObjectiveId.foundSecondCity: GameIcons.cityFilled,
  GameObjectiveId.buildFirstBuilding: GameIcons.production,
  GameObjectiveId.improveThreeHexes: GameIcons.resources,
  GameObjectiveId.foundThirdCity: GameIcons.cityFilled,
  GameObjectiveId.exploreRegion: GameIcons.visibility,
  GameObjectiveId.buildCombatForce: GameIcons.attack,
  GameObjectiveId.raiseStability: GameIcons.defense,
  GameObjectiveId.overtakeScoreLeader: GameIcons.stats,
  GameObjectiveId.holdDomination: GameIcons.checkCircle,
  GameObjectiveId.holdScoreLead: GameIcons.checkCircle,
  GameObjectiveId.secureMapObjective: GameIcons.checkCircle,
  GameObjectiveId.breakDominationHold: GameIcons.warning,
  GameObjectiveId.breakMapObjectiveHold: GameIcons.warning,
};

Color objectiveToneColor(GameObjectiveTone tone) {
  return switch (tone) {
    GameObjectiveTone.research => GameUiTheme.scienceAccent,
    GameObjectiveTone.expansion => GameUiTheme.gold,
    GameObjectiveTone.exploration => const Color(0xFFB7D47D),
    GameObjectiveTone.economy => GameUiTheme.resourcesAccent,
    GameObjectiveTone.victory => GameUiTheme.success,
    GameObjectiveTone.warning => GameUiTheme.warning,
  };
}

bool isScorePressureObjective(GameObjectiveId id) {
  return id == GameObjectiveId.holdScoreLead ||
      id == GameObjectiveId.overtakeScoreLeader;
}
