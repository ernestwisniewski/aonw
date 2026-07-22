import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/movement/movement_command_path_constraints.dart';

/// Auto-explore destination together with the route policy used to select it.
final class ScoutAutoExploreTarget {
  const ScoutAutoExploreTarget({
    required this.command,
    required this.pathConstraints,
  });

  final MoveUnitCommand command;
  final MovementCommandPathConstraints pathConstraints;
}
