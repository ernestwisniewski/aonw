import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_controller.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudPanelController', () {
    test('starts with all panels closed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(hudPanelControllerProvider), const HudPanelModes());
    });

    test('applies explicit modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(hudPanelControllerProvider.notifier)
          .apply(const HudPanelModes(activityLog: true));

      expect(
        container.read(hudPanelControllerProvider),
        const HudPanelModes(activityLog: true),
      );
    });

    test('syncWithGameState stores normalized modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');

      container
          .read(hudPanelControllerProvider.notifier)
          .apply(const HudPanelModes(cityBuildings: true, technology: true));

      final result = container
          .read(hudPanelControllerProvider.notifier)
          .syncWithGameState(
            GameState(
              units: [commander],
              selection: GameSelection.unit(commander),
            ),
          );

      expect(
        result,
        const HudPanelModes(cityBuildings: false, technology: true),
      );
      expect(container.read(hudPanelControllerProvider), result);
    });
  });
}
