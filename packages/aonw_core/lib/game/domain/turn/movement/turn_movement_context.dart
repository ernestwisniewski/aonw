import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Read-only dependencies and player scopes for one movement phase.
final class TurnMovementContext {
  TurnMovementContext({
    required Iterable<String> playerIds,
    required Iterable<String> phaseKnownPlayerIds,
    required this.mapData,
    this.fogOfWarService = const FogOfWarService(),
  }) : playerIds = Set.unmodifiable(_nonEmptyIds(playerIds)),
       phaseKnownPlayerIds = Set.unmodifiable(phaseKnownPlayerIds);

  final Set<String> playerIds;

  /// Player scope used for the recompute between queued and automatic moves.
  ///
  /// Auto-exploration deliberately derives a narrower, live scope from fog,
  /// units, and cities after every move.
  final Set<String> phaseKnownPlayerIds;
  final MapTraversalView mapData;
  final FogOfWarService fogOfWarService;
}

Set<String> _nonEmptyIds(Iterable<String> source) => {
  for (final id in source)
    if (id.isNotEmpty) id,
};
