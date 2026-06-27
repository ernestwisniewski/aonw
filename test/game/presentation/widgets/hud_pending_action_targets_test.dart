import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_pending_action_targets.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudPendingActionTargets', () {
    test('prefers pending attack unit before selected unit', () {
      final state = GameState(
        units: [_unit('selected')],
        interaction: GameInteractionState(
          selection: GameSelection.unit(_unit('selected')),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'pending',
          ),
        ),
      );

      expect(HudPendingActionTargets.attackUnitId(state), 'pending');
    });

    test(
      'falls back to selected unit when no matching pending action exists',
      () {
        final state = GameState(
          units: [_unit('selected')],
          interaction: GameInteractionState(
            selection: GameSelection.unit(_unit('selected')),
          ),
        );

        expect(HudPendingActionTargets.attackUnitId(state), 'selected');
        expect(HudPendingActionTargets.workerUnitId(state), 'selected');
      },
    );

    test('prefers pending worker action unit before selected unit', () {
      final state = GameState(
        units: [_unit('selected')],
        interaction: GameInteractionState(
          selection: GameSelection.unit(_unit('selected')),
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'pending_worker',
          ),
        ),
      );

      expect(HudPendingActionTargets.workerUnitId(state), 'pending_worker');
    });

    test('prefers pending worked-hex city before selected city', () {
      final state = GameState(
        interaction: GameInteractionState(
          selection: GameSelection.city(
            _city('selected_city'),
            cityYield: TileYield.zero,
            playerColor: 0xFF4488cc,
          ),
          pendingAction: const PendingCityWorkedHexSelection(
            ownerPlayerId: 'player_1',
            cityId: 'pending_city',
          ),
        ),
      );

      expect(
        HudPendingActionTargets.cityWorkedHexCityId(state),
        'pending_city',
      );
    });

    test('prefers pending expansion city before selected city', () {
      final state = GameState(
        interaction: GameInteractionState(
          selection: GameSelection.city(
            _city('selected_city'),
            cityYield: TileYield.zero,
            playerColor: 0xFF4488cc,
          ),
          pendingAction: const PendingCityExpansionSelection(
            ownerPlayerId: 'player_1',
            cityId: 'pending_city',
          ),
        ),
      );

      expect(
        HudPendingActionTargets.cityExpansionCityId(state),
        'pending_city',
      );
    });
  });
}

GameUnit _unit(String id) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.worker,
    name: GameUnitType.worker.defaultNameToken,
    col: 0,
    row: 0,
  );
}

GameCity _city(String id) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 0, row: 0),
  );
}
