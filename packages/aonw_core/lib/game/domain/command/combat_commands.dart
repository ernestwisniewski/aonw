part of 'game_command.dart';

/// Player begins combat targeting for [attackerUnitId].
final class StartAttackTargetingCommand extends GameCommand {
  const StartAttackTargetingCommand(this.attackerUnitId);

  final String attackerUnitId;

  @override
  bool operator ==(Object other) =>
      other is StartAttackTargetingCommand &&
      other.attackerUnitId == attackerUnitId;

  @override
  int get hashCode => Object.hash(StartAttackTargetingCommand, attackerUnitId);
}

/// Player cancels combat targeting for [attackerUnitId].
final class CancelAttackTargetingCommand extends GameCommand {
  const CancelAttackTargetingCommand(this.attackerUnitId);

  final String attackerUnitId;

  @override
  bool operator ==(Object other) =>
      other is CancelAttackTargetingCommand &&
      other.attackerUnitId == attackerUnitId;

  @override
  int get hashCode => Object.hash(CancelAttackTargetingCommand, attackerUnitId);
}

/// Player orders [attackerUnitId] to attack the unit on [defenderCol]/[defenderRow].
final class AttackHexCommand extends GameCommand {
  const AttackHexCommand(
    this.attackerUnitId,
    this.defenderCol,
    this.defenderRow, {
    this.cityConquestAction = CityConquestAction.capture,
  });

  final String attackerUnitId;
  final int defenderCol;
  final int defenderRow;
  final CityConquestAction cityConquestAction;

  @override
  bool operator ==(Object other) =>
      other is AttackHexCommand &&
      other.attackerUnitId == attackerUnitId &&
      other.defenderCol == defenderCol &&
      other.defenderRow == defenderRow &&
      other.cityConquestAction == cityConquestAction;

  @override
  int get hashCode => Object.hash(
    AttackHexCommand,
    attackerUnitId,
    defenderCol,
    defenderRow,
    cityConquestAction,
  );
}
