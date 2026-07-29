part of 'movement_reducer.dart';

abstract final class _AutoExploreProcessor {
  static TurnAutoExploreAdvance advanceForNewTurn({
    required GameState state,
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
      interaction: PersistedInteractionState(
        cityFoundingDraft: state.cityFoundingDraft,
        pendingAction: state.pendingAction,
      ),
      playerIds: playerIds,
      phaseKnownPlayerIds: knownPlayerIds(state),
      mapData: mapView,
      fogOfWarService: fogOfWarService,
    );
  }
}
