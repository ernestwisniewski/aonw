import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_commands.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudSelectionCommands', () {
    test('creates unit action commands from selected unit', () {
      final state = _stateWithUnit(
        _unit('warrior_1', type: GameUnitType.warrior),
      );

      expect(
        HudSelectionCommands.startAttackTargeting(state),
        const StartAttackTargetingCommand('warrior_1'),
      );
      expect(
        HudSelectionCommands.cancelWorkerJob(state),
        const CancelWorkerJobCommand('warrior_1'),
      );
      expect(
        HudSelectionCommands.cancelSelectedUnitAction(state),
        const CancelUnitActionCommand('warrior_1'),
      );
      expect(
        HudSelectionCommands.skipSelectedUnitTurn(state),
        const SkipUnitTurnCommand('warrior_1'),
      );
      expect(
        HudSelectionCommands.fortifySelectedUnit(state),
        const FortifyUnitCommand('warrior_1'),
      );
    });

    test('starts worker action selection only for workers', () {
      expect(
        HudSelectionCommands.startWorkerActionSelection(
          _stateWithUnit(_unit('worker_1')),
        ),
        const StartWorkerActionSelectionCommand('worker_1'),
      );
      expect(
        HudSelectionCommands.startWorkerActionSelection(
          _stateWithUnit(_unit('warrior_1', type: GameUnitType.warrior)),
        ),
        isNull,
      );
    });

    test('creates auto-explore command for selected scout', () {
      final scout = _unit('scout_1', type: GameUnitType.scout, col: 1);
      final command = HudSelectionCommands.autoExploreSelectedUnit(
        _stateWithUnit(scout),
        _grassMap(cols: 6, rows: 1),
      );

      expect(
        command,
        isA<AutoExploreUnitCommand>().having(
          (value) => value.unitId,
          'unitId',
          scout.id,
        ),
      );
    });

    test('creates city worked hex command from selected city', () {
      final city = _city('city_1');
      final state = GameState(
        cities: [city],
        interaction: GameInteractionState(
          selection: GameSelection.city(
            city,
            cityYield: TileYield.zero,
            playerColor: 0xFF4488cc,
          ),
        ),
      );

      expect(
        HudSelectionCommands.startCityWorkedHexSelection(state),
        const StartCityWorkedHexSelectionCommand('city_1'),
      );
    });

    test('creates city expansion command from selected city', () {
      final city = _city('city_1');
      final state = GameState(
        cities: [city],
        interaction: GameInteractionState(
          selection: GameSelection.city(
            city,
            cityYield: TileYield.zero,
            playerColor: 0xFF4488cc,
          ),
        ),
      );

      expect(
        HudSelectionCommands.startCityExpansionSelection(state),
        const StartCityExpansionSelectionCommand('city_1'),
      );
    });

    test('returns null without matching selection', () {
      expect(HudSelectionCommands.startAttackTargeting(null), isNull);
      expect(
        HudSelectionCommands.startCityWorkedHexSelection(const GameState()),
        isNull,
      );
      expect(
        HudSelectionCommands.startCityExpansionSelection(const GameState()),
        isNull,
      );
      expect(
        HudSelectionCommands.cancelSelectedUnitAction(const GameState()),
        isNull,
      );
    });
  });
}

GameState _stateWithUnit(GameUnit unit, {List<GameCity> cities = const []}) {
  return GameState(
    units: [unit],
    cities: cities,
    interaction: GameInteractionState(selection: GameSelection.unit(unit)),
  );
}

GameUnit _unit(
  String id, {
  GameUnitType type = GameUnitType.worker,
  int col = 0,
  int row = 0,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
  );
}

MapData _grassMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

GameCity _city(String id, {List<CityHex> controlledHexes = const []}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 0, row: 0),
    controlledHexes: controlledHexes,
  );
}
