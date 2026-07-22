import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// State-container-neutral result of applying a movement command.
///
/// Rejections and accepted semantic no-ops borrow all input slices. Changed
/// collections are owned by the resolver and cannot be mutated.
final class MovementCommandResult {
  const MovementCommandResult.accepted({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    this.events = const [],
    this.execution,
  }) : accepted = true,
       reason = null;

  const MovementCommandResult.rejected({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    required this.reason,
  }) : accepted = false,
       events = const [],
       execution = null;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
}
