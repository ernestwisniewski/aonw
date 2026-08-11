import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Read-only dependencies and player scopes for one movement phase.
final class TurnMovementContext {
  TurnMovementContext({
    required Iterable<String> playerIds,
    required Iterable<String> phaseKnownPlayerIds,
    required this.mapData,
    this.fogOfWarService = const FogOfWarService(),
    this.ruleset = GameRuleset.defaults,
    this.fogRecomputedBeforePhase = false,
  }) : playerIds = Set.unmodifiable(_nonEmptyIds(playerIds)),
       phaseKnownPlayerIds = Set.unmodifiable(phaseKnownPlayerIds);

  final Set<String> playerIds;

  /// Stable caller-supplied player scope used for the post-queued fog/contact
  /// recompute and forwarded through each auto-explore continuation.
  final Set<String> phaseKnownPlayerIds;
  final MapTraversalView mapData;
  final FogOfWarService fogOfWarService;
  final GameRuleset ruleset;

  /// The economy phase immediately preceding canonical movement already
  /// rebuilt visibility for the same units and cities. Standalone movement
  /// callers keep the conservative legacy refresh by leaving this false.
  final bool fogRecomputedBeforePhase;
}

Set<String> _nonEmptyIds(Iterable<String> source) => {
  for (final id in source)
    if (id.isNotEmpty) id,
};
