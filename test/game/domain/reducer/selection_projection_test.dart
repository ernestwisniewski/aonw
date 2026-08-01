import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw/game/domain/turn/phases/selection_refresh_phase.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapData = _map();

  test('city production projects the current city selection', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
      controlledHexes: [CityHex(col: 1, row: 1)],
    );
    final state = GameClientState(
      cities: [city],
      activePlayerId: 'player_1',
      playerColors: {'player_1': 0xFF123456},
    );

    final selection = CitySelectionProjector.project(
      state: state,
      city: city,
      mapTiles: mapData,
      ruleset: GameRuleset.defaults,
    );

    expect(selection.type, GameSelectionType.city);
    expect(selection.city, same(city));
    expect(selection.cityPlayerColor, 0xFF123456);
    expect(selection.cityYield, isNotNull);
  });

  test('tile tap leaves stale move mode before standard selection', () {
    final state = GameClientState(
      interaction: const InteractionState(moveCommandActive: true),
    );

    final transition = SelectionReducer.handleTileTapped(
      state,
      const TileTappedCommand(1, 1),
      mapData,
    );

    expect(transition.state.selection?.type, GameSelectionType.tile);
    expect(transition.state.moveCommandActive, isFalse);
    expect(transition.state.movePreview, isNull);
  });

  test('selecting a fortified unit immediately starts movement targeting', () {
    final fortified = GameUnit.startingWarrior(
      ownerPlayerId: 'player_1',
      col: 1,
      row: 1,
    ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
    final state = GameClientState(
      units: [fortified],
      activePlayerId: 'player_1',
      fogOfWar: _fortifiedSelectionFog,
    );

    final selected = SelectionReducer.selectUnit(
      state,
      SelectUnitCommand(fortified.id),
      mapData,
    );

    expect(selected.selectedUnit, same(fortified));
    expect(selected.moveCommandActive, isTrue);
    expect(selected.movePreview, isNull);
    expect(selected.units.single.posture, UnitPosture.fortified);
  });

  test('tapping a fortified unit immediately starts movement targeting', () {
    final fortified = GameUnit.startingWarrior(
      ownerPlayerId: 'player_1',
      col: 1,
      row: 1,
    ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
    final state = GameClientState(
      units: [fortified],
      activePlayerId: 'player_1',
      fogOfWar: _fortifiedSelectionFog,
    );

    final transition = SelectionReducer.handleTileTapped(
      state,
      const TileTappedCommand(1, 1),
      mapData,
    );

    expect(transition.state.selectedUnit, same(fortified));
    expect(transition.state.moveCommandActive, isTrue);
    expect(transition.state.movePreview, isNull);
  });

  test(
    'city selection forwards custom stability into the fresh projection',
    () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        population: 1,
        center: CityHex(col: 1, row: 1),
      );
      final state = GameClientState(
        cities: [city],
        activePlayerId: 'player_1',
        playerStabilityNet: {'player_1': -2},
      );
      final cityRuleset = CityRulesets.standard.copyWith(
        cityCenterYield: const TileYield(
          food: 2,
          production: 7,
          gold: 7,
          defense: 0,
        ),
      );

      final selected = SelectionReducer.selectCity(
        state,
        const SelectCityCommand('city_1'),
        mapData,
        ruleset: GameRuleset.defaults.copyWith(
          city: cityRuleset,
          stability: _customStabilityRuleset,
        ),
      );

      expect(
        selected.selection?.cityEconomy?.stabilityModifier,
        StabilityPolicy.modifierFor(StabilityBand.unrest),
      );
      expect(selected.selection?.cityEconomy?.netYield.production, 5);
      expect(selected.selection?.cityEconomy?.netYield.gold, 5);
    },
  );

  group('SelectionRefreshPhase', () {
    final MapTileLookup mapTiles = _selectionRefreshWorldMap();

    test('selects a city founded by the previously selected unit', () {
      final founder = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      const foundedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Founded city',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      final state = GameClientState(
        cities: const [foundedCity],
        activePlayerId: 'player_1',
        interaction: InteractionState(selection: GameSelection.unit(founder)),
      );

      final refreshed = const SelectionRefreshPhase().apply(
        _context(state, mapTiles),
      );

      expect(refreshed.state.selection?.type, GameSelectionType.city);
      expect(refreshed.state.selection?.city, same(state.cities.single));
      expect(refreshed.state.selection?.unit, isNull);
      expect(refreshed.state.selection?.tile, isNull);
      expect(refreshed.state.selection?.cityYield, isNotNull);
      expect(refreshed.state.selection?.cityTileYieldBreakdown, isNotNull);
      expect(refreshed.state.selection?.cityEconomy, isNotNull);
      expect(mapTiles.tileAt(1, 1)?.resources, [
        ResourceType.oil,
        ResourceType.wheat,
      ]);
    });

    test('reprojects an updated selected city', () {
      const selectedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Before turn',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      );
      const updatedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'After turn',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
        population: 2,
      );
      final state = GameClientState(
        cities: const [updatedCity],
        activePlayerId: 'player_1',
        playerStabilityNet: const {'player_1': -2},
        interaction: InteractionState(
          selection: GameSelection.city(
            selectedCity,
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
        ),
      );

      final refreshed = const SelectionRefreshPhase().apply(
        _context(
          state,
          mapTiles,
          ruleset: GameRuleset.standard().copyWith(
            stability: _customStabilityRuleset,
          ),
        ),
      );

      expect(refreshed.state.selection?.city, same(state.cities.single));
      expect(refreshed.state.selection?.city?.population, 2);
      expect(refreshed.state.selection?.cityYield, isNotNull);
      expect(
        refreshed.state.selection?.cityEconomy?.stabilityModifier,
        StabilityPolicy.modifierFor(StabilityBand.unrest),
      );
    });

    test('clears a selected city that no longer exists', () {
      const removedCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Removed city',
        center: CityHex(col: 1, row: 1),
      );
      final state = GameClientState(
        activePlayerId: 'player_1',
        interaction: InteractionState(
          selection: GameSelection.city(
            removedCity,
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
        ),
      );

      final refreshed = const SelectionRefreshPhase().apply(
        _context(state, mapTiles),
      );

      expect(refreshed.state.selection, isNull);
    });

    test('hides unrevealed resources when refreshing a selected unit', () {
      final selectedUnit = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      ).copyWith(movementPoints: 0);
      final updatedUnit = selectedUnit.copyWith(movementPoints: 2);
      final state = GameClientState(
        units: [updatedUnit],
        activePlayerId: 'player_1',
        interaction: InteractionState(
          selection: GameSelection.unit(selectedUnit),
        ),
      );

      final refreshed = const SelectionRefreshPhase().apply(
        _context(state, mapTiles),
      );

      expect(refreshed.state.selection?.unit, same(updatedUnit));
      expect(refreshed.state.selection?.tile?.resources, [ResourceType.wheat]);
      expect(mapTiles.tileAt(1, 1)?.resources, [
        ResourceType.oil,
        ResourceType.wheat,
      ]);
    });

    test(
      'keeps revealed and hides unrevealed resources for an improvement',
      () {
        const selectedImprovement = FieldImprovement(
          hex: CityHex(col: 2, row: 1),
          type: FieldImprovementType.farm,
          builtByCityId: 'old_city',
        );
        const updatedImprovement = FieldImprovement(
          hex: CityHex(col: 2, row: 1),
          type: FieldImprovementType.farm,
          builtByCityId: 'city_1',
        );
        final state = GameClientState(
          fieldImprovements: const [updatedImprovement],
          activePlayerId: 'player_1',
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.combustion},
              ),
            },
          ),
          interaction: InteractionState(
            selection: GameSelection.fieldImprovement(selectedImprovement),
          ),
        );

        final refreshed = const SelectionRefreshPhase().apply(
          _context(state, mapTiles),
        );

        expect(
          refreshed.state.selection?.fieldImprovement,
          same(updatedImprovement),
        );
        expect(refreshed.state.selection?.tile?.resources, [
          ResourceType.oil,
          ResourceType.wheat,
        ]);
        expect(mapTiles.tileAt(2, 1)?.resources, [
          ResourceType.oil,
          ResourceType.horses,
          ResourceType.wheat,
        ]);
      },
    );
  });
}

final _fortifiedSelectionFog = FogOfWarState(
  players: {
    'player_1': PlayerFogOfWar(
      playerId: 'player_1',
      discoveredHexes: {const HexCoordinate(col: 1, row: 1)},
      visibleHexes: {const HexCoordinate(col: 1, row: 1)},
    ),
  },
);

final _customStabilityRuleset = StabilityRuleset.standard.copyWith(
  unrestThreshold: -2,
);

TurnContext _context(
  GameClientState state,
  MapTileLookup mapTiles, {
  GameRuleset? ruleset,
}) => TurnContext(
  state: state,
  mapTiles: mapTiles,
  ruleset: ruleset ?? GameRuleset.standard(),
  playerId: 'player_1',
);

WorldMap _map() => WorldMap(
  cols: 3,
  rows: 3,
  tiles: [
    for (var row = 0; row < 3; row += 1)
      for (var col = 0; col < 3; col += 1)
        WorldTile(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

WorldMap _selectionRefreshWorldMap() {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row += 1)
        for (var col = 0; col < 3; col += 1)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.plains],
            resources: switch ((col, row)) {
              (1, 1) => const [ResourceType.oil, ResourceType.wheat],
              (2, 1) => const [
                ResourceType.oil,
                ResourceType.horses,
                ResourceType.wheat,
              ],
              _ => const [],
            },
            height: 0,
          ),
    ],
  );
}
