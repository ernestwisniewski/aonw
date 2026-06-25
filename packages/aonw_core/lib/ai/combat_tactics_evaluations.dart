part of 'combat_tactics.dart';

class AiAttackEvaluation {
  const AiAttackEvaluation({
    required this.command,
    required this.attacker,
    required this.defender,
    required this.defenderDamage,
    required this.attackerDamage,
    required this.defenderHpBefore,
    required this.attackerHpBefore,
    required this.defenderHpAfter,
    required this.attackerHpAfter,
    required this.defenderKilled,
    required this.attackerKilled,
    required this.defenderRetreated,
    required this.targetIsCivilian,
    required this.capturesCity,
    required this.rangedAttack,
    required this.nearestOwnCityDistance,
    required this.heuristicScore,
  });

  final AttackHexCommand command;
  final GameUnit attacker;
  final GameUnit defender;
  final int defenderDamage;
  final int attackerDamage;
  final int defenderHpBefore;
  final int attackerHpBefore;
  final int defenderHpAfter;
  final int attackerHpAfter;
  final bool defenderKilled;
  final bool attackerKilled;
  final bool defenderRetreated;
  final bool targetIsCivilian;
  final bool capturesCity;
  final bool rangedAttack;
  final int nearestOwnCityDistance;
  final double heuristicScore;

  bool get threatensOwnCity => nearestOwnCityDistance <= 2;

  bool get isDecisive => defenderKilled || capturesCity;

  bool get isFreeRangedDamage => rangedAttack && attackerDamage == 0;

  bool get tradesAwayAttacker =>
      attackerKilled && !defenderKilled && !capturesCity;

  AiAttackEvaluation withHeuristicScore(double heuristicScore) {
    return AiAttackEvaluation(
      command: command,
      attacker: attacker,
      defender: defender,
      defenderDamage: defenderDamage,
      attackerDamage: attackerDamage,
      defenderHpBefore: defenderHpBefore,
      attackerHpBefore: attackerHpBefore,
      defenderHpAfter: defenderHpAfter,
      attackerHpAfter: attackerHpAfter,
      defenderKilled: defenderKilled,
      attackerKilled: attackerKilled,
      defenderRetreated: defenderRetreated,
      targetIsCivilian: targetIsCivilian,
      capturesCity: capturesCity,
      rangedAttack: rangedAttack,
      nearestOwnCityDistance: nearestOwnCityDistance,
      heuristicScore: heuristicScore,
    );
  }
}

class AiCityAttackEvaluation {
  const AiCityAttackEvaluation({
    required this.command,
    required this.attacker,
    required this.city,
    required this.defenderDamage,
    required this.attackerDamage,
    required this.defenderHpBefore,
    required this.attackerHpBefore,
    required this.defenderHpAfter,
    required this.attackerHpAfter,
    required this.cityDefeated,
    required this.attackerKilled,
    required this.rangedAttack,
    required this.nearestOwnCityDistance,
    required this.heuristicScore,
  });

  final AttackHexCommand command;
  final GameUnit attacker;
  final GameCity city;
  final int defenderDamage;
  final int attackerDamage;
  final int defenderHpBefore;
  final int attackerHpBefore;
  final int defenderHpAfter;
  final int attackerHpAfter;
  final bool cityDefeated;
  final bool attackerKilled;
  final bool rangedAttack;
  final int nearestOwnCityDistance;
  final double heuristicScore;

  bool get capturesCity =>
      cityDefeated && command.cityConquestAction == CityConquestAction.capture;

  bool get destroysCity =>
      cityDefeated && command.cityConquestAction == CityConquestAction.destroy;

  bool get isFreeRangedDamage => rangedAttack && attackerDamage == 0;

  bool get tradesAwayAttacker => attackerKilled && !cityDefeated;

  AiCityAttackEvaluation withHeuristicScore(double heuristicScore) {
    return AiCityAttackEvaluation(
      command: command,
      attacker: attacker,
      city: city,
      defenderDamage: defenderDamage,
      attackerDamage: attackerDamage,
      defenderHpBefore: defenderHpBefore,
      attackerHpBefore: attackerHpBefore,
      defenderHpAfter: defenderHpAfter,
      attackerHpAfter: attackerHpAfter,
      cityDefeated: cityDefeated,
      attackerKilled: attackerKilled,
      rangedAttack: rangedAttack,
      nearestOwnCityDistance: nearestOwnCityDistance,
      heuristicScore: heuristicScore,
    );
  }
}
