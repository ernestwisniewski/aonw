import 'package:aonw_core/game/domain/combat/combat_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Complete deterministic context supplied with one engine command.
final class GameEngineContext {
  const GameEngineContext({
    required this.actorPlayerId,
    required this.mapView,
    required this.ruleset,
    required this.commandTick,
    this.movementVisibilityMode = MovementCommandVisibilityMode.authoritative,
    this.combatVisibilityMode = CombatCommandVisibilityMode.authoritative,
  });

  final String actorPlayerId;
  final MapReadView mapView;
  final GameRuleset ruleset;
  final int commandTick;
  final MovementCommandVisibilityMode movementVisibilityMode;
  final CombatCommandVisibilityMode combatVisibilityMode;
}
