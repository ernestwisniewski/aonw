import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/presentation/widgets/hud/city/hud_city_production_context.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudCityProductionContext', () {
    test('exposes selected city only when production panel is open', () {
      final selection = _selection(cityYield: _yield(production: 3));

      expect(
        HudCityProductionContext.from(
          modes: const HudPanelModes(cityBuildings: true),
          selection: selection,
        ).city,
        selection.city,
      );
      expect(
        HudCityProductionContext.from(
          modes: const HudPanelModes(),
          selection: selection,
        ).city,
        isNull,
      );
    });

    test('prefers economy production over raw city yield', () {
      final context = HudCityProductionContext.from(
        modes: const HudPanelModes(cityBuildings: true),
        selection: _selection(
          cityYield: _yield(production: 3),
          cityEconomy: CityEconomyBreakdown(
            city: _city(),
            tileYield: _yield(production: 5),
            buildingYield: _yield(production: 2),
            populationUpkeep: 1,
            netFood: 1,
            foodDeposit: 1,
            growthCost: 10,
          ),
        ),
      );

      expect(context.productionPerTurn, 7);
    });

    test('falls back to raw city yield and then to one production', () {
      expect(
        HudCityProductionContext.from(
          modes: const HudPanelModes(),
          selection: _selection(cityYield: _yield(production: 4)),
        ).productionPerTurn,
        4,
      );
      expect(
        HudCityProductionContext.from(
          modes: const HudPanelModes(),
          selection: null,
        ).productionPerTurn,
        1,
      );
    });
  });
}

GameSelection _selection({
  required TileYield cityYield,
  CityEconomyBreakdown? cityEconomy,
}) {
  return GameSelection.city(
    _city(),
    cityYield: cityYield,
    cityEconomy: cityEconomy,
    playerColor: 0,
  );
}

GameCity _city() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 0, row: 0),
  );
}

TileYield _yield({required int production}) {
  return TileYield(food: 0, production: production, gold: 0, defense: 0);
}
