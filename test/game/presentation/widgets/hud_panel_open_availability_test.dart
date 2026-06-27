import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_modes.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_open_availability.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudPanelOpenAvailability', () {
    test('allows city production only for selected city and closed panel', () {
      final state = GameState(
        cities: [_city()],
        interaction: GameInteractionState(
          selection: GameSelection.city(
            _city(),
            cityYield: TileYield.zero,
            playerColor: 0,
          ),
        ),
      );

      expect(
        HudPanelOpenAvailability.cityProduction(
          modes: const HudPanelModes(),
          state: state,
        ),
        isTrue,
      );
      expect(
        HudPanelOpenAvailability.cityProduction(
          modes: const HudPanelModes(cityBuildings: true),
          state: state,
        ),
        isFalse,
      );
      expect(
        HudPanelOpenAvailability.cityProduction(
          modes: const HudPanelModes(),
          state: const GameState(),
        ),
        isFalse,
      );
    });

    test('requires active player and closed mode for player panels', () {
      expect(
        HudPanelOpenAvailability.technology(
          modes: const HudPanelModes(),
          activePlayerId: 'player_1',
        ),
        isTrue,
      );
      expect(
        HudPanelOpenAvailability.objectives(
          modes: const HudPanelModes(),
          activePlayerId: 'player_1',
        ),
        isTrue,
      );
      expect(
        HudPanelOpenAvailability.technology(
          modes: const HudPanelModes(technology: true),
          activePlayerId: 'player_1',
        ),
        isFalse,
      );
      expect(
        HudPanelOpenAvailability.objectives(
          modes: const HudPanelModes(),
          activePlayerId: '',
        ),
        isFalse,
      );
    });

    test('requires state for empire and visible entries for activity log', () {
      expect(
        HudPanelOpenAvailability.empire(
          modes: const HudPanelModes(),
          state: const GameState(),
          activePlayerId: 'player_1',
        ),
        isTrue,
      );
      expect(
        HudPanelOpenAvailability.empire(
          modes: const HudPanelModes(),
          state: null,
          activePlayerId: 'player_1',
        ),
        isFalse,
      );
      expect(
        HudPanelOpenAvailability.activityLog(
          modes: const HudPanelModes(),
          activePlayerId: 'player_1',
        ),
        isTrue,
      );
      expect(
        HudPanelOpenAvailability.activityLog(
          modes: const HudPanelModes(activityLog: true),
          activePlayerId: 'player_1',
        ),
        isFalse,
      );
      expect(
        HudPanelOpenAvailability.activityLog(
          modes: const HudPanelModes(),
          activePlayerId: '',
        ),
        isFalse,
      );
    });
  });
}

GameCity _city() {
  return const GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 0, row: 0),
  );
}
