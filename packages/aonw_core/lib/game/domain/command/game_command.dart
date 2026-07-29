import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/city_conquest_action.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
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

/// Transitional umbrella for presentation, player-domain, and trusted
/// server commands.
///
/// Serialization is defined separately for each command boundary.
sealed class GameCommand {
  const GameCommand();
}

/// Presentation input handled by application and UI controllers.
sealed class GameIntent extends GameCommand {
  const GameIntent();
}

/// A player-authored request to change authoritative game state.
sealed class DomainCommand extends GameCommand {
  const DomainCommand();
}

/// A trusted server-authored request to change authoritative game state.
sealed class ServerSystemCommand extends GameCommand {
  const ServerSystemCommand();
}

/// Commands routed through the diplomacy application service.
sealed class DiplomaticCommand extends DomainCommand {
  const DiplomaticCommand();
}
