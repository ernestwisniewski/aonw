import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('combat formatter names defeated units from previous state', (
    tester,
  ) async {
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
    final previousState = GameClientState(
      activePlayerId: 'player_1',
      playerCountries: const {
        'player_1': PlayerCountry.poland,
        'player_2': PlayerCountry.ukraine,
      },
      units: [attacker, defender],
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      playerCountries: const {'player_1': PlayerCountry.poland},
      units: [attacker.copyWithHitPoints(9)],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final combat = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              GameEventNotification(
                id: 1,
                event: CombatResolvedEvent(
                  attackerUnitId: 'warrior_1',
                  defenderUnitId: 'enemy_1',
                  outcome: CombatOutcome(
                    attackerUnitId: 'warrior_1',
                    defenderUnitId: 'enemy_1',
                    attackerHpAfter: 9,
                    defenderHpAfter: 0,
                    attackerKilled: false,
                    defenderKilled: true,
                    steps: [AttackStep(damage: 5)],
                  ),
                ),
                state: state,
                previousState: previousState,
                playerId: 'player_1',
              ),
              null,
            );
            final killed = GameEventNotificationMessage.from(
              AppLocalizations.of(context),
              GameEventNotification(
                id: 2,
                event: const UnitKilledEvent(
                  unitId: 'enemy_1',
                  ownerPlayerId: 'player_2',
                  attackerUnitId: 'warrior_1',
                ),
                state: state,
                previousState: previousState,
                playerId: 'player_2',
              ),
              null,
            );

            expect(
              combat.body,
              'Warrior (Poland) attacked Warrior Enemy (Ukraine) - HP 9:0',
            );
            expect(combat.details, [
              'Warrior Enemy: -5 HP -> defeated',
              'Warrior: no retaliation',
              'Attack: -5 HP',
              'Defender defeated',
            ]);
            expect(killed.body, 'Enemy');
            expect(killed.thumbnail, isA<UnitEventNotificationThumbnail>());
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
