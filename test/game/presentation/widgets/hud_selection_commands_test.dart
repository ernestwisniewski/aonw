import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_commands.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
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

    test('creates merchant targeting and destination commands', () {
      final state = _stateWithUnit(
        _unit('merchant_1', type: GameUnitType.merchant),
      );

      expect(
        HudSelectionCommands.startMerchantTradeRouteSelection(state),
        const StartMerchantTradeRouteSelectionCommand('merchant_1'),
      );
      expect(
        HudSelectionCommands.assignMerchantTradeRoute(state, 'city_2'),
        const AssignMerchantTradeRouteCommand('merchant_1', 'city_2'),
      );
      expect(
        HudSelectionCommands.startMerchantMoveToCitySelection(state),
        const StartMerchantMoveToCitySelectionCommand('merchant_1'),
      );
      expect(
        HudSelectionCommands.moveMerchantToCity(state, 'city_2'),
        const MoveMerchantToCityCommand('merchant_1', 'city_2'),
      );
    });

    test('creates artifact commands from selected unit', () {
      final state = _stateWithUnit(_unit('scout_1', type: GameUnitType.scout));

      expect(
        HudSelectionCommands.startArtifactExcavation(state),
        const StartArtifactExcavationCommand('scout_1'),
      );
      expect(
        HudSelectionCommands.storeArtifactInCity(state),
        const StoreArtifactInCityCommand('scout_1'),
      );
    });

    test('creates city worked hex command from selected city', () {
      final city = _city('city_1');
      final state = GameClientState(
        cities: [city],
        interaction: InteractionState(
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
      final state = GameClientState(
        cities: [city],
        interaction: InteractionState(
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
        HudSelectionCommands.startCityWorkedHexSelection(GameClientState()),
        isNull,
      );
      expect(
        HudSelectionCommands.startCityExpansionSelection(GameClientState()),
        isNull,
      );
      expect(
        HudSelectionCommands.cancelSelectedUnitAction(GameClientState()),
        isNull,
      );
    });
  });
}

GameClientState _stateWithUnit(
  GameUnit unit, {
  List<GameCity> cities = const [],
}) {
  return GameClientState(
    units: [unit],
    cities: cities,
    interaction: InteractionState(selection: GameSelection.unit(unit)),
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

GameCity _city(String id, {List<CityHex> controlledHexes = const []}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 0, row: 0),
    controlledHexes: controlledHexes,
  );
}
