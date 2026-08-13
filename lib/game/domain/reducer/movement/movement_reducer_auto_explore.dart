part of 'movement_reducer.dart';

abstract final class _AutoExploreProcessor {
  static TurnAutoExploreAdvance advanceForNewTurn({
    required GameClientState state,
    required MapTraversalView mapView,
    required String? resetPlayerId,
    required FogOfWarService fogOfWarService,
  }) {
    final playerIds = resetPlayerId == null
        ? knownPlayerIds(state)
        : {resetPlayerId};
    return TurnAutoExploreAdvancer.advance(
      units: state.units,
      cities: state.cities,
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      interaction: DomainActionState(
        cityFoundingDraft: state.cityFoundingDraft,
        pendingAction: state.pendingAction,
      ),
      playerIds: playerIds,
      phaseKnownPlayerIds: knownPlayerIds(state),
      mapData: mapView,
      fogOfWarService: fogOfWarService,
      transportNetwork: state.transportNetwork,
    );
  }
}
