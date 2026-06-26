import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activity log keeps all toast-worthy notifications', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    );
    final defender = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 1,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 1, row: 1),
    );
    final state = GameState(
      activePlayerId: 'player_1',
      cities: const [city],
      units: [attacker],
    );
    final previousState = state.copyWith(units: [attacker, defender]);

    container
        .read(gameEventNotificationsProvider.notifier)
        .addAll(
          [
            const CityFoundedEvent(cityId: 'city_1', ownerPlayerId: 'player_1'),
            CombatResolvedEvent(
              attackerUnitId: 'warrior_1',
              defenderUnitId: 'enemy_1',
              outcome: CombatOutcome(
                attackerUnitId: 'warrior_1',
                defenderUnitId: 'enemy_1',
                attackerHpAfter: 3,
                defenderHpAfter: 0,
                attackerKilled: false,
                defenderKilled: true,
                steps: [AttackStep(damage: 3)],
              ),
            ),
            const TechnologyResearchedEvent(
              playerId: 'player_1',
              technologyId: TechnologyId.agriculture,
            ),
            const DominationThresholdReachedEvent(
              playerId: 'player_1',
              controlPercent: 50,
              requiredControlPercent: 42,
              holdTurns: 1,
              requiredHoldTurns: 4,
            ),
          ],
          state,
          previousState: previousState,
        );

    expect(container.read(gameActivityLogProvider), hasLength(4));
    expect(
      container.read(gameEventNotificationsProvider)[1].previousState,
      same(previousState),
    );

    container.read(gameEventNotificationsProvider.notifier).clear();

    expect(container.read(gameActivityLogProvider), isEmpty);
  });

  test('previous state assigns combat toast when attacker was removed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final attacker = GameUnit(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 1,
      row: 1,
    );
    final defender = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Enemy',
      col: 2,
      row: 1,
    );
    final previousState = GameState(
      activePlayerId: 'player_1',
      units: [attacker, defender],
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [defender.copyWithHitPoints(1)],
    );

    container
        .read(gameEventNotificationsProvider.notifier)
        .addAll(
          [
            CombatResolvedEvent(
              attackerUnitId: 'warrior_1',
              defenderUnitId: 'enemy_1',
              outcome: CombatOutcome(
                attackerUnitId: 'warrior_1',
                defenderUnitId: 'enemy_1',
                attackerHpAfter: 0,
                defenderHpAfter: 1,
                attackerKilled: true,
                defenderKilled: false,
                steps: [AttackStep(damage: 2), RetaliationStep(damage: 9)],
              ),
            ),
          ],
          state,
          previousState: previousState,
        );

    final notification = container.read(gameEventNotificationsProvider).single;
    expect(notification.playerId, 'player_1');
    expect(notification.previousState, same(previousState));
  });

  test('opponent domination threshold is visible to active player', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const state = GameState(activePlayerId: 'player_1');

    container.read(gameEventNotificationsProvider.notifier).addAll(const [
      DominationThresholdReachedEvent(
        playerId: 'player_2',
        controlPercent: 55,
        requiredControlPercent: 42,
        holdTurns: 1,
        requiredHoldTurns: 4,
      ),
    ], state);

    final notification = container.read(gameEventNotificationsProvider).single;
    expect(notification.playerId, 'player_1');
    expect(notification.event, isA<DominationThresholdReachedEvent>());
    expect(container.read(gameActivityLogProvider), hasLength(1));
  });

  test('newly visible opponent creates civilization met notification', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final enemy = GameUnit(
      id: 'enemy_1',
      ownerPlayerId: 'player_2',
      type: GameUnitType.scout,
      name: 'Scout',
      col: 3,
      row: 4,
    );
    final previousState = GameState(
      activePlayerId: 'player_1',
      units: [enemy],
      fogOfWar: _fogForPlayer(
        'player_1',
        visible: const [HexCoordinate(col: 0, row: 0)],
      ),
    );
    final state = previousState.copyWith(
      fogOfWar: _fogForPlayer(
        'player_1',
        visible: const [
          HexCoordinate(col: 0, row: 0),
          HexCoordinate(col: 3, row: 4),
        ],
      ),
    );

    container
        .read(gameEventNotificationsProvider.notifier)
        .addAll(const [], state, previousState: previousState);

    final notification = container.read(gameEventNotificationsProvider).single;
    expect(notification.playerId, 'player_1');
    expect(notification.event, isA<CivilizationMetEvent>());
    expect(
      (notification.event as CivilizationMetEvent).metPlayerId,
      'player_2',
    );
    expect(container.read(gameActivityLogProvider), hasLength(1));
  });

  test('combat against active player city is assigned to defender', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final attacker = GameUnit(
      id: 'attacker',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      name: 'Warrior',
      col: 4,
      row: 4,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'Roma',
      center: CityHex(col: 3, row: 4),
    );
    final previousState = GameState(
      activePlayerId: 'player_1',
      units: [attacker],
      cities: const [city],
    );
    final state = previousState;

    container
        .read(gameEventNotificationsProvider.notifier)
        .addAll(
          [
            CombatResolvedEvent(
              attackerUnitId: 'attacker',
              defenderUnitId: 'city_1',
              outcome: CombatOutcome(
                attackerUnitId: 'attacker',
                defenderUnitId: 'city_1',
                attackerHpAfter: 10,
                defenderHpAfter: 7,
                attackerKilled: false,
                defenderKilled: false,
                steps: [AttackStep(damage: 3)],
              ),
            ),
          ],
          state,
          previousState: previousState,
        );

    final notification = container.read(gameEventNotificationsProvider).single;
    expect(notification.playerId, 'player_1');
    expect(notification.event, isA<CombatResolvedEvent>());
  });
}

FogOfWarState _fogForPlayer(
  String playerId, {
  required List<HexCoordinate> visible,
}) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(
        playerId: playerId,
        visibleHexes: visible.toSet(),
      ),
    },
  );
}
