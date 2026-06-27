import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_next_action_panel.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudNextActionPanelResolver', () {
    test('opens technology for active player research selection', () {
      expect(
        HudNextActionPanelResolver.afterFocus(
          state: const GameState(
            interaction: GameInteractionState(
              pendingAction: PendingResearchSelection(
                ownerPlayerId: 'player_1',
              ),
            ),
          ),
          activePlayerId: 'player_1',
        ),
        HudNextActionPanel.technology,
      );
    });

    test('ignores research selection owned by another player', () {
      expect(
        HudNextActionPanelResolver.afterFocus(
          state: const GameState(
            interaction: GameInteractionState(
              pendingAction: PendingResearchSelection(
                ownerPlayerId: 'player_2',
              ),
            ),
          ),
          activePlayerId: 'player_1',
        ),
        HudNextActionPanel.none,
      );
    });

    test(
      'opens city production for selected active city without production',
      () {
        final city = _city(productionQueued: false);

        expect(
          HudNextActionPanelResolver.afterFocus(
            state: GameState(
              cities: [city],
              interaction: GameInteractionState(
                selection: GameSelection.city(
                  city,
                  cityYield: TileYield.zero,
                  playerColor: 0xFF4488cc,
                ),
              ),
            ),
            activePlayerId: 'player_1',
          ),
          HudNextActionPanel.cityProduction,
        );
      },
    );

    test('does not open city production when city is already queued', () {
      final city = _city();

      expect(
        HudNextActionPanelResolver.afterFocus(
          state: GameState(
            cities: [city],
            interaction: GameInteractionState(
              selection: GameSelection.city(
                city,
                cityYield: TileYield.zero,
                playerColor: 0xFF4488cc,
              ),
            ),
          ),
          activePlayerId: 'player_1',
        ),
        HudNextActionPanel.none,
      );
    });
  });
}

GameCity _city({bool productionQueued = true}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 0, row: 0),
    productionQueue: productionQueued
        ? CityProductionQueue.building(
            buildingType: CityBuildingType.granary,
            investedProduction: 0,
          )
        : null,
  );
}
