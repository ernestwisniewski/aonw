import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/game/domain/unit/detach_troop_resolver.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentUnitDetachmentResult {
  const PersistentUnitDetachmentResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

/// Compatibility adapter for the persistence-neutral detachment resolver.
final class PersistentUnitDetachmentResolver {
  const PersistentUnitDetachmentResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentUnitDetachmentResult detachTroop({
    required PersistentGameState state,
    required DetachTroopCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = DetachTroopResolver.detachTroop(
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.runtimeState.diplomacy,
      playerIds: state.knownPlayerIds,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      fogOfWarService: fogOfWarService,
    );
    if (!result.accepted) {
      return PersistentUnitDetachmentResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return PersistentUnitDetachmentResult(
      accepted: true,
      state: state.copyWith(
        units: result.units,
        fogOfWar: result.fogOfWar,
        runtimeState: state.runtimeState.copyWith(diplomacy: result.diplomacy),
      ),
    );
  }
}
