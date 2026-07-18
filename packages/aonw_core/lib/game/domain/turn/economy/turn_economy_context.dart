import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Immutable inputs shared by every step of the economy phase.
final class TurnEconomyContext {
  TurnEconomyContext({
    required Iterable<String> playerIds,
    required this.mapData,
    required this.countryForPlayer,
    this.ruleset = GameRuleset.defaults,
    this.fogOfWarService = const FogOfWarService(),
    Iterable<GameEvent> priorEvents = const [],
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
    Iterable<String> baseKnownPlayerIds = const [],
    this.turn,
  }) : playerIds = List.unmodifiable(_orderedDistinctPlayerIds(playerIds)),
       priorEvents = List.unmodifiable(priorEvents),
       mapObjectives = List.unmodifiable(mapObjectives),
       baseKnownPlayerIds = Set.unmodifiable(
         baseKnownPlayerIds.where((playerId) => playerId.isNotEmpty),
       );

  final List<String> playerIds;
  final MapReadView mapData;
  final GameRuleset ruleset;
  final FogOfWarService fogOfWarService;
  final List<GameEvent> priorEvents;
  final List<MapObjectiveDefinition> mapObjectives;
  final Set<String> baseKnownPlayerIds;
  final PlayerCountry Function(String playerId) countryForPlayer;
  final int? turn;
}

List<String> _orderedDistinctPlayerIds(Iterable<String> playerIds) {
  return {
    for (final playerId in playerIds)
      if (playerId.isNotEmpty) playerId,
  }.toList()..sort();
}
