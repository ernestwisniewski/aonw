part of 'activity_log_panel_test.dart';

List<GameEventNotification> _nonCombatTimelineEntries() {
  const city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'Roma',
    center: CityHex(col: 1, row: 1),
  );
  final state = GameClientState(activePlayerId: 'player_1', cities: [city]);

  return [
    GameEventNotification(
      id: 1,
      event: const CityFoundedEvent(
        cityId: 'city_1',
        ownerPlayerId: 'player_1',
      ),
      state: state,
      playerId: 'player_1',
      turn: 2,
    ),
    GameEventNotification(
      id: 2,
      event: const TechnologyResearchedEvent(
        playerId: 'player_1',
        technologyId: TechnologyId.agriculture,
      ),
      state: state,
      playerId: 'player_1',
      turn: 5,
    ),
  ];
}
