import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Complete deterministic context supplied with one engine command.
final class GameEngineContext {
  const GameEngineContext({
    required this.actorPlayerId,
    required this.mapView,
    required this.ruleset,
    required this.commandTick,
  });

  final String actorPlayerId;
  final MapReadView mapView;
  final GameRuleset ruleset;
  final int commandTick;
}
