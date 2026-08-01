import 'package:aonw_core/game/domain/command.dart';

sealed class MctsAction {
  const MctsAction();

  bool get endsPlanning => false;

  DomainCommand? toCommand();

  String get debugLabel;
}

final class CommandMctsAction extends MctsAction {
  final DomainCommand command;

  const CommandMctsAction(this.command);

  @override
  DomainCommand toCommand() => command;

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
  DomainCommand? toCommand() => null;

  @override
  String get debugLabel => 'EndPlanningAction';

  @override
  bool operator ==(Object other) => other is EndPlanningAction;

  @override
  int get hashCode => Object.hashAll(const [EndPlanningAction]);
}
