import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/technology/player_research_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

typedef PlayerResearchLookup = PlayerResearchState Function(String playerId);

/// Read-only dependencies used while resolving one combat phase.
final class TurnCombatContext {
  const TurnCombatContext({
    required this.turn,
    required this.researchForPlayer,
    this.mapTiles,
    this.ruleset = GameRuleset.defaults,
  });

  final int turn;
  final PlayerResearchLookup researchForPlayer;
  final MapTileLookup? mapTiles;
  final GameRuleset ruleset;
}
