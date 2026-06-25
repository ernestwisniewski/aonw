import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyCitySpecializationPlanner', () {
    test('selects specialization from effective persona weights', () {
      final mapData = _map();
      final view = _view(
        mapData: mapData,
        research: _researchWithUnlockedSpecialization(),
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view, persona: AiPersona.scientific),
      );

      expect(commands, [
        const SetCitySpecializationCommand(
          'capital',
          CitySpecializationType.science,
        ),
      ]);
    });

    test('waits until specialization technology is unlocked', () {
      final mapData = _map();
      final view = _view(mapData: mapData, research: ResearchState.empty);

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands, isEmpty);
    });

    test('waits until a city has an anchor building', () {
      final mapData = _map();
      final view = _view(
        mapData: mapData,
        research: _researchWithUnlockedSpecialization(),
        cities: const [_bareCapital],
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view, persona: AiPersona.scientific),
      );

      expect(commands, isEmpty);
    });

    test('specializes coastal cities for commerce', () {
      final view = _view(
        mapData: _map(const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
        ]),
        research: _researchWithUnlockedSpecialization(),
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands.single.specialization, CitySpecializationType.commerce);
    });

    test('specializes food-rich cities for growth', () {
      final view = _view(
        mapData: _map(const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [ResourceType.wheat],
            height: 0,
          ),
        ]),
        research: _researchWithUnlockedSpecialization(),
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands.single.specialization, CitySpecializationType.growth);
    });

    test('specializes threatened cities for military', () {
      final view = _view(
        mapData: _map(),
        research: _researchWithUnlockedSpecialization(),
        pendingCityAttackThreats: const [
          PendingCityAttackThreat(
            attackerPlayerId: 'player_2',
            attackerUnitId: 'enemy_warrior',
            attackerHex: HexCoordinate(col: 1, row: 0),
            cityId: 'capital',
            cityCenter: CityHex(col: 0, row: 0),
          ),
        ],
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands.single.specialization, CitySpecializationType.military);
    });

    test('respecializes cities when strategic pressure clearly changes', () {
      final view = _view(
        mapData: _map(),
        research: _researchWithUnlockedSpecialization(),
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            specialization: CitySpecializationType.commerce,
            buildings: {
              CityBuildingType.granary,
              CityBuildingType.workshop,
              CityBuildingType.merchantHall,
              CityBuildingType.archive,
              CityBuildingType.barracks,
            },
          ),
        ],
        pendingCityAttackThreats: const [
          PendingCityAttackThreat(
            attackerPlayerId: 'player_2',
            attackerUnitId: 'enemy_warrior',
            attackerHex: HexCoordinate(col: 1, row: 0),
            cityId: 'capital',
            cityCenter: CityHex(col: 0, row: 0),
          ),
        ],
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands, [
        const SetCitySpecializationCommand(
          'capital',
          CitySpecializationType.military,
        ),
      ]);
    });

    test('keeps current specialization when the new fit is only marginal', () {
      final view = _view(
        mapData: _map(const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.coast],
            resources: [],
            height: 0,
          ),
        ]),
        research: _researchWithUnlockedSpecialization(),
        cities: const [
          GameCity(
            id: 'capital',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            specialization: CitySpecializationType.industry,
            buildings: {
              CityBuildingType.granary,
              CityBuildingType.workshop,
              CityBuildingType.merchantHall,
              CityBuildingType.archive,
              CityBuildingType.barracks,
            },
          ),
        ],
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands, isEmpty);
    });

    test('does not specialize around unrevealed strategic resources', () {
      final view = _view(
        mapData: _map(const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [ResourceType.oil],
            height: 0,
          ),
        ]),
        research: _researchWithUnlockedSpecialization(),
      );

      final commands = const BasicStrategyCitySpecializationPlanner().plan(
        view,
        _context(view),
      );

      expect(commands.single.specialization, CitySpecializationType.industry);
    });
  });
}

const _capital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
  buildings: {
    CityBuildingType.granary,
    CityBuildingType.workshop,
    CityBuildingType.merchantHall,
    CityBuildingType.archive,
    CityBuildingType.barracks,
  },
);

const _bareCapital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

ResearchState _researchWithUnlockedSpecialization() {
  return ResearchState(
    players: {
      'player_1': PlayerResearchState(
        unlockedTechnologyIds: {TechnologyId.specialization},
      ),
    },
  );
}

GameView _view({
  required MapData mapData,
  required ResearchState research,
  List<GameCity> cities = const [_capital],
  List<PendingCityAttackThreat> pendingCityAttackThreats = const [],
}) {
  return GameView.fromPersistentState(
    PersistentGameState(cities: cities, research: research),
    forPlayerId: 'player_1',
    turn: 2,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    pendingCityAttackThreats: pendingCityAttackThreats,
  );
}

AiContext _context(GameView view, {AiPersona persona = AiPersona.balanced}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
    persona: persona,
  );
}

MapData _map([
  List<TileData> tiles = const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
]) {
  return MapData(cols: 1, rows: 1, tiles: tiles);
}
