import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_modes.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeHudPanelModes', () {
    test('closes city panel when selection is not a city', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        selection: GameSelection.unit(commander),
      );

      final result = normalizeHudPanelModes(
        current: const HudPanelModes(cityBuildings: true, technology: true),
        gameState: state,
      );

      expect(
        result,
        const HudPanelModes(cityBuildings: false, technology: true),
      );
    });

    test('keeps city panel open while a city remains selected', () {
      final city = _city();
      final state = GameState(
        cities: [city],
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0,
        ),
      );

      final result = normalizeHudPanelModes(
        current: const HudPanelModes(cityBuildings: true),
        gameState: state,
      );

      expect(result, const HudPanelModes(cityBuildings: true));
    });

    test('pending worker action does not open a legacy worker panel', () {
      final worker = _worker();
      final state = GameState(
        units: [worker],
        selection: GameSelection.unit(worker),
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'player_1',
          unitId: 'worker_1',
        ),
      );

      final result = normalizeHudPanelModes(
        current: const HudPanelModes(cityBuildings: true, technology: true),
        gameState: state,
      );

      expect(result, const HudPanelModes(technology: true));
    });

    test('ignores pending worker action when selected unit is not a city', () {
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final state = GameState(
        units: [commander],
        selection: GameSelection.unit(commander),
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'player_1',
          unitId: 'worker_1',
        ),
      );

      final result = normalizeHudPanelModes(
        current: const HudPanelModes(cityBuildings: true, technology: true),
        gameState: state,
      );

      expect(result, const HudPanelModes(technology: true));
    });

    test('keeps technology state when there is no game state', () {
      final result = normalizeHudPanelModes(
        current: const HudPanelModes(cityBuildings: true, technology: true),
        gameState: null,
      );

      expect(
        result,
        const HudPanelModes(cityBuildings: false, technology: true),
      );
    });

    test('preserves global panel state while normalizing selection panels', () {
      final result = normalizeHudPanelModes(
        current: const HudPanelModes(
          cityBuildings: true,
          objectives: true,
          empire: true,
          activityLog: true,
        ),
        gameState: null,
      );

      expect(
        result,
        const HudPanelModes(
          cityBuildings: false,
          objectives: true,
          empire: true,
          activityLog: true,
        ),
      );
    });
  });

  group('HudPanelModes operations', () {
    test('openCityBuildings closes global action panels', () {
      final result = const HudPanelModes(
        technology: true,
        objectives: true,
        empire: true,
        activityLog: true,
      ).openCityBuildings();

      expect(result, const HudPanelModes(cityBuildings: true));
    });

    test('openTechnology closes other global action panels', () {
      final result = const HudPanelModes(
        cityBuildings: true,
        objectives: true,
        empire: true,
        activityLog: true,
      ).openTechnology();

      expect(result, const HudPanelModes(technology: true));
    });

    test('openObjectives closes competing panels', () {
      final result = const HudPanelModes(
        cityBuildings: true,
        technology: true,
        empire: true,
        activityLog: true,
      ).openObjectives();

      expect(result, const HudPanelModes(objectives: true));
    });

    test('openEmpire closes other global action panels', () {
      final result = const HudPanelModes(
        cityBuildings: true,
        technology: true,
        objectives: true,
        activityLog: true,
      ).openEmpire();

      expect(result, const HudPanelModes(empire: true));
    });

    test('openActivityLog closes map panels and empire', () {
      final result = const HudPanelModes(
        cityBuildings: true,
        technology: true,
        objectives: true,
        empire: true,
      ).openActivityLog();

      expect(result, const HudPanelModes(activityLog: true));
    });

    test('closePrimaryPanels preserves global overlays', () {
      final result = const HudPanelModes(
        cityBuildings: true,
        technology: true,
        objectives: true,
        empire: true,
        activityLog: true,
      ).closePrimaryPanels();

      expect(result, const HudPanelModes(empire: true, activityLog: true));
    });

    test('closeUnitActionPanels keeps city and global overlays unchanged', () {
      final result = const HudPanelModes(
        cityBuildings: true,
        technology: true,
        objectives: true,
        empire: true,
        activityLog: true,
      ).closeUnitActionPanels();

      expect(
        result,
        const HudPanelModes(
          cityBuildings: true,
          empire: true,
          activityLog: true,
        ),
      );
    });
  });
}

GameUnit _worker() {
  return GameUnit(
    id: 'worker_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: GameUnitType.worker.defaultNameToken,
    col: 0,
    row: 0,
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
