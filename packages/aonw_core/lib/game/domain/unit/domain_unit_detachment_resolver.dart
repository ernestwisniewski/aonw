import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/unit/detach_troop_resolver.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainUnitDetachmentResult {
  const DomainUnitDetachmentResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral detachment resolver.
final class DomainUnitDetachmentResolver {
  const DomainUnitDetachmentResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  DomainUnitDetachmentResult detachTroop({
    required DomainState state,
    required DetachTroopCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
  }) {
    final result = DetachTroopResolver.detachTroop(
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
      playerIds: _knownPlayerIds(state),
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      fogOfWarService: fogOfWarService,
    );
    if (!result.accepted) {
      return DomainUnitDetachmentResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainUnitDetachmentResult(
      accepted: true,
      state: state.copyWith(
        units: result.units,
        fogOfWar: result.fogOfWar,
        diplomacy: result.diplomacy,
      ),
    );
  }

  static Set<String> _knownPlayerIds(DomainState state) {
    return <String>{
      for (final participant in state.participants) participant.id,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
      for (final relation in state.diplomacy.relations.values)
        relation.playerAId,
      for (final relation in state.diplomacy.relations.values)
        relation.playerBId,
    }..removeWhere((playerId) => playerId.isEmpty);
  }
}
