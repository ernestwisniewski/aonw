import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'selection_commands.dart';
part 'research_commands.dart';
part 'turn_commands.dart';
part 'unit_commands.dart';
part 'artifact_commands.dart';
part 'combat_commands.dart';
part 'commander_commands.dart';
part 'city_commands.dart';
part 'worker_commands.dart';
part 'diplomacy_commands.dart';

/// Sealed hierarchy representing every player action in the game.
/// Commands are immutable value objects suitable for serialization
/// and dispatch to a pure [GameStateReducer].
sealed class GameCommand {
  const GameCommand();
}

/// Commands routed through the diplomacy application service.
sealed class DiplomaticCommand extends GameCommand {
  const DiplomaticCommand();
}
