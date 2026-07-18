part of 'city_expansion_command_resolver_parity_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

typedef _ExpansionStates = ({
  PersistentGameState persistent,
  DomainState domain,
});

typedef _ExpansionResults = ({
  PersistentCityExpansionResult persistent,
  DomainCityExpansionResult domain,
});

_ExpansionStates _expansionStates({
  required GameCity city,
  ResearchState research = ResearchState.empty,
}) {
  final cities = [city, _parityCity(id: 'city_2', centerCol: 3, centerRow: 3)];
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _otherPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _otherPlayerId: PlayerCountry.france,
      },
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      cities: cities,
      research: research,
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: const {_otherPlayerId},
        timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
        turnStartedAt: DateTime.utc(2026, 7, 18),
      ),
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _playerId,
          name: 'One',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _otherPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      cities: cities,
      research: research,
    ),
  );
}

_ExpansionResults _resolveBoth(
  _ExpansionStates states, {
  String actorPlayerId = _playerId,
}) {
  const command = SelectCityExpansionHexCommand('city_1', 1, 2);
  return (
    persistent: const PersistentCityExpansionResolver().selectExpansionHex(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: _parityMap(),
    ),
    domain: const DomainCityExpansionResolver().selectExpansionHex(
      state: states.domain,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: _parityMap(),
    ),
  );
}

ResearchState _urbanizationResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.urbanization},
      ),
    },
  );
}

GameCity _parityCity({
  String id = 'city_1',
  int centerCol = 1,
  int centerRow = 1,
  int maxHexes = GameCity.defaultStartMaxHexes,
  CityHex? preferredExpansionHex,
}) {
  return GameCity(
    id: id,
    ownerPlayerId: _playerId,
    name: id,
    center: CityHex(col: centerCol, row: centerRow),
    controlledHexes: [CityHex(col: centerCol + 1, row: centerRow)],
    maxHexes: maxHexes,
    preferredExpansionHex: preferredExpansionHex,
  );
}

MapTileLookup _parityMap() {
  return WorldMapReadView(
    WorldMap(
      cols: 5,
      rows: 5,
      tiles: [
        for (var row = 0; row < 5; row++)
          for (var col = 0; col < 5; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
