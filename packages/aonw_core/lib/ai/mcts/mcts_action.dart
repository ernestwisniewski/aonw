import 'package:aonw_core/game/domain/command.dart';

sealed class MctsAction {
  const MctsAction();

  bool get endsPlanning => false;

  GameCommand? toCommand();

  String get debugLabel;
}

final class CommandMctsAction extends MctsAction {
  final GameCommand command;

  const CommandMctsAction(this.command);

  @override
  GameCommand toCommand() => command;

  @override
  String get debugLabel => command.runtimeType.toString();

  @override
  bool operator ==(Object other) =>
      other is CommandMctsAction && other.command == command;

  @override
  int get hashCode => Object.hash(CommandMctsAction, command);
}

final class EndPlanningAction extends MctsAction {
  const EndPlanningAction();

  @override
  bool get endsPlanning => true;

  @override
  GameCommand? toCommand() => null;

  @override
  String get debugLabel => 'EndPlanningAction';

  @override
  bool operator ==(Object other) => other is EndPlanningAction;

  @override
  int get hashCode => Object.hashAll(const [EndPlanningAction]);
}
