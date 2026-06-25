import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyResourceTradePlanner', () {
    test(
      'opens import when unlocked unit is blocked by known rival resource',
      () {
        final view = _view(
          ownGold: 12,
          ownResearch: _research().forPlayer('player_1'),
          research: _research(),
          rememberedEnemyCities: const [
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Horse City',
              center: CityHex(col: 2, row: 2),
            ),
          ],
          diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
        );

        final commands = const BasicStrategyResourceTradePlanner().plan(view);

        expect(commands, [
          const OpenResourceTradeCommand(
            playerId: 'player_1',
            targetPlayerId: 'player_2',
            resource: ResourceType.horses,
            goldPerTurn: 2,
            durationTurns: 8,
          ),
        ]);
      },
    );

    test('does not duplicate an active import', () {
      final view = _view(
        ownGold: 12,
        ownResearch: _research().forPlayer('player_1'),
        research: _research(),
        rememberedEnemyCities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Horse City',
            center: CityHex(col: 2, row: 2),
          ),
        ],
        diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
        resourceTradeAgreements: const [
          ResourceTradeAgreement(
            id: 'trade_1',
            exporterPlayerId: 'player_2',
            importerPlayerId: 'player_1',
            resource: ResourceType.horses,
            goldPerTurn: 2,
            remainingTurns: 4,
          ),
        ],
      );

      final commands = const BasicStrategyResourceTradePlanner().plan(view);

      expect(commands, isEmpty);
    });

    test('offers surplus resource exchange before paying gold', () {
      final research = _researchWith({
        'player_1': {
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
          TechnologyId.ironWorking,
        },
        'player_2': {
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
          TechnologyId.ironWorking,
        },
      });
      final view = _view(
        ownGold: 12,
        ownResearch: research.forPlayer('player_1'),
        research: research,
        ownCities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Iron City',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 0, row: 1)],
          ),
        ],
        rememberedEnemyCities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Horse City',
            center: CityHex(col: 2, row: 2),
            controlledHexes: [CityHex(col: 2, row: 1)],
          ),
        ],
        diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
        mapData: _exchangeMap(),
      );

      final commands = const BasicStrategyResourceTradePlanner().plan(view);

      expect(commands, [
        const OpenResourceExchangeCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          offeredResource: ResourceType.iron,
          requestedResource: ResourceType.horses,
          durationTurns: 8,
        ),
      ]);
    });

    test('does not request an exporter reserved last strategic resource', () {
      final research = _researchWith({
        'player_1': {
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
        },
        'player_2': {
          TechnologyId.animalHusbandry,
          TechnologyId.horsebackRiding,
        },
      });
      final view = _view(
        ownGold: 12,
        ownResearch: research.forPlayer('player_1'),
        research: research,
        rememberedEnemyCities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Horse City',
            center: CityHex(col: 2, row: 2),
          ),
        ],
        diplomacy: DiplomacyState.empty.addContact('player_1', 'player_2'),
      );

      final commands = const BasicStrategyResourceTradePlanner().plan(view);

      expect(commands, isEmpty);
    });
  });
}

GameView _view({
  required int ownGold,
  required PlayerResearchState ownResearch,
  required ResearchState research,
  List<GameCity>? ownCities,
  required List<GameCity> rememberedEnemyCities,
  required DiplomacyState diplomacy,
  List<ResourceTradeAgreement> resourceTradeAgreements = const [],
  MapData? mapData,
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 12,
    ownGold: ownGold,
    ownResearch: ownResearch,
    research: research,
    ownUnits: const [],
    ownCities:
        ownCities ??
        const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        ],
    ownImprovements: const [],
    resourceTradeAgreements: resourceTradeAgreements,
    diplomacy: diplomacy,
    visibleEnemyUnits: const [],
    rememberedEnemyCities: rememberedEnemyCities,
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: mapData ?? _map(),
    ruleset: GameRuleset.defaults,
  );
}

ResearchState _research() {
  return _researchWith({
    'player_1': {TechnologyId.animalHusbandry, TechnologyId.horsebackRiding},
    'player_2': {TechnologyId.animalHusbandry},
  });
}

ResearchState _researchWith(Map<String, Set<TechnologyId>> technologies) {
  return ResearchState(
    players: {
      for (final entry in technologies.entries)
        entry.key: PlayerResearchState(unlockedTechnologyIds: entry.value),
    },
  );
}

MapData _map() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: col == 2 && row == 2
                ? const [ResourceType.horses]
                : const [],
            height: 0,
          ),
    ],
  );
}

MapData _exchangeMap() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: switch ((col, row)) {
              (0, 0) || (0, 1) => const [ResourceType.iron],
              (2, 1) || (2, 2) => const [ResourceType.horses],
              _ => const [],
            },
            height: 0,
          ),
    ],
  );
}
