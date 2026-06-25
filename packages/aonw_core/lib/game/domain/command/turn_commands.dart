part of 'game_command.dart';

/// Player ends their turn.
final class EndTurnCommand extends GameCommand {
  const EndTurnCommand(this.playerId);

  final String playerId;

  @override
  bool operator ==(Object other) =>
      other is EndTurnCommand && other.playerId == playerId;

  @override
  int get hashCode => Object.hash(EndTurnCommand, playerId);
}

/// Player submits their simultaneous multiplayer turn.
///
/// Unlike [EndTurnCommand], this only marks readiness. The server decides when
/// all submitted players advance through the simultaneous turn pipeline.
final class SubmitTurnCommand extends GameCommand {
  const SubmitTurnCommand(this.playerId);

  final String playerId;

  @override
  bool operator ==(Object other) =>
      other is SubmitTurnCommand && other.playerId == playerId;

  @override
  int get hashCode => Object.hash(SubmitTurnCommand, playerId);
}

/// Sets the active player, optionally granting action rights.
final class SetActivePlayerCommand extends GameCommand {
  const SetActivePlayerCommand(this.playerId, {required this.canAct});

  final String playerId;
  final bool canAct;

  @override
  bool operator ==(Object other) =>
      other is SetActivePlayerCommand &&
      other.playerId == playerId &&
      other.canAct == canAct;

  @override
  int get hashCode => Object.hash(SetActivePlayerCommand, playerId, canAct);
}
