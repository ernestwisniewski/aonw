import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_focus_target.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudMapFocusTarget', () {
    test('creates unit focus target', () {
      final target = HudMapFocusTarget.unit(_unit('unit_1', col: 2, row: 3));

      expect(target.selectCommand, const SelectUnitCommand('unit_1'));
      expect(target.col, 2);
      expect(target.row, 3);
      expect(target.cameraEffect.col, 2);
      expect(target.cameraEffect.row, 3);
    });

    test('creates city focus target', () {
      final target = HudMapFocusTarget.city(_city('city_1', col: 4, row: 5));

      expect(target.selectCommand, const SelectCityCommand('city_1'));
      expect(target.col, 4);
      expect(target.row, 5);
      expect(target.cameraEffect.col, 4);
      expect(target.cameraEffect.row, 5);
    });

    test('creates notification target from current state first', () {
      final staleState = GameState(cities: [_city('city_1', col: 1, row: 1)]);
      final currentState = GameState(cities: [_city('city_1', col: 6, row: 7)]);
      final notification = GameEventNotification(
        id: 1,
        event: const CityFoundedEvent(
          cityId: 'city_1',
          ownerPlayerId: 'player_1',
        ),
        state: staleState,
        playerId: 'player_1',
      );

      final target = HudMapFocusTarget.notification(
        notification: notification,
        currentState: currentState,
      );

      expect(target?.selectCommand, const SelectCityCommand('city_1'));
      expect(target?.col, 6);
      expect(target?.row, 7);
    });

    test('falls back to notification state when current state is missing', () {
      final notification = GameEventNotification(
        id: 1,
        event: const CityFoundedEvent(
          cityId: 'city_1',
          ownerPlayerId: 'player_1',
        ),
        state: GameState(cities: [_city('city_1', col: 8, row: 9)]),
        playerId: 'player_1',
      );

      final target = HudMapFocusTarget.notification(
        notification: notification,
        currentState: null,
      );

      expect(target?.selectCommand, const SelectCityCommand('city_1'));
      expect(target?.col, 8);
      expect(target?.row, 9);
    });

    test('returns null for notification without focus target', () {
      const notification = GameEventNotification(
        id: 1,
        event: TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.mining,
        ),
        state: GameState(),
        playerId: 'player_1',
      );

      expect(
        HudMapFocusTarget.notification(
          notification: notification,
          currentState: null,
        ),
        isNull,
      );
    });

    test('anchors technology notification on player city', () {
      const notification = GameEventNotification(
        id: 1,
        event: TechnologyResearchedEvent(
          playerId: 'player_1',
          technologyId: TechnologyId.mining,
        ),
        state: GameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 3, row: 4),
            ),
          ],
          activePlayerId: 'player_1',
        ),
        playerId: 'player_1',
      );

      final target = HudMapFocusTarget.notification(
        notification: notification,
        currentState: null,
      );

      expect(target?.selectCommand, const SelectCityCommand('city_1'));
      expect(target?.col, 3);
      expect(target?.row, 4);
    });

    test('does not focus an undiscovered foreign city notification', () {
      const hiddenCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Hidden',
        center: CityHex(col: 8, row: 9),
      );
      final notification = GameEventNotification(
        id: 1,
        event: const CityProducedUnitEvent(
          cityId: 'city_2',
          unitType: GameUnitType.warrior,
          producedUnitId: 'warrior_2',
        ),
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [hiddenCity],
          fogOfWar: _fog(visible: {const HexCoordinate(col: 0, row: 0)}),
        ),
        playerId: 'player_1',
      );

      expect(
        HudMapFocusTarget.notification(
          notification: notification,
          currentState: null,
        ),
        isNull,
      );
    });

    test('does not focus a remembered foreign city outside vision', () {
      const rememberedCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Remembered',
        center: CityHex(col: 8, row: 9),
      );
      final notification = GameEventNotification(
        id: 1,
        event: const CityProducedUnitEvent(
          cityId: 'city_2',
          unitType: GameUnitType.warrior,
          producedUnitId: 'warrior_2',
        ),
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [rememberedCity],
          fogOfWar: _fog(
            discovered: {const HexCoordinate(col: 8, row: 9)},
            visible: {const HexCoordinate(col: 0, row: 0)},
          ),
        ),
        playerId: 'player_1',
      );

      expect(
        HudMapFocusTarget.notification(
          notification: notification,
          currentState: null,
        ),
        isNull,
      );
    });

    test('civilization met focuses visible unit instead of hidden capital', () {
      const hiddenCapital = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Capital',
        center: CityHex(col: 8, row: 9),
      );
      final visibleWarrior = _unit(
        'enemy_1',
        ownerPlayerId: 'player_2',
        col: 3,
        row: 4,
      );
      final notification = GameEventNotification(
        id: 1,
        event: const CivilizationMetEvent(
          playerId: 'player_1',
          metPlayerId: 'player_2',
        ),
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [hiddenCapital],
          units: [visibleWarrior],
          fogOfWar: _fog(visible: {const HexCoordinate(col: 3, row: 4)}),
        ),
        playerId: 'player_1',
      );

      final target = HudMapFocusTarget.notification(
        notification: notification,
        currentState: null,
      );

      expect(target?.selectCommand, const SelectUnitCommand('enemy_1'));
      expect(target?.col, 3);
      expect(target?.row, 4);
    });

    test(
      'civilization met focuses visible unit instead of remembered capital',
      () {
        const rememberedCapital = GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_2',
          name: 'Capital',
          center: CityHex(col: 8, row: 9),
        );
        final visibleWarrior = _unit(
          'enemy_1',
          ownerPlayerId: 'player_2',
          col: 3,
          row: 4,
        );
        final notification = GameEventNotification(
          id: 1,
          event: const CivilizationMetEvent(
            playerId: 'player_1',
            metPlayerId: 'player_2',
          ),
          state: GameState(
            activePlayerId: 'player_1',
            cities: const [rememberedCapital],
            units: [visibleWarrior],
            fogOfWar: _fog(
              discovered: {const HexCoordinate(col: 8, row: 9)},
              visible: {const HexCoordinate(col: 3, row: 4)},
            ),
          ),
          playerId: 'player_1',
        );

        final target = HudMapFocusTarget.notification(
          notification: notification,
          currentState: null,
        );

        expect(target?.selectCommand, const SelectUnitCommand('enemy_1'));
        expect(target?.col, 3);
        expect(target?.row, 4);
      },
    );
  });
}

GameUnit _unit(
  String id, {
  String ownerPlayerId = 'player_1',
  required int col,
  required int row,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    name: 'Warrior',
    col: col,
    row: row,
  );
}

GameCity _city(String id, {required int col, required int row}) {
  return GameCity(
    id: id,
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: col, row: row),
  );
}

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}
