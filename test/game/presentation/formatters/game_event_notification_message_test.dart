import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_event_notification_message.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameEventNotificationMessage', () {
    test(
      'formats city production events through descriptor message groups',
      () {
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
        );

        final message = GameEventNotificationMessage.from(
          AppLocalizationsEn(),
          const GameEventNotification(
            id: 1,
            event: CityProducedUnitEvent(
              cityId: 'city_1',
              unitType: GameUnitType.warrior,
              producedUnitId: 'warrior_1',
            ),
            state: GameState(cities: [city]),
            playerId: 'player_1',
          ),
          null,
        );

        expect(message.title, 'Unit trained');
        expect(message.body, contains('Capital'));
        expect(message.thumbnail, isA<UnitEventNotificationThumbnail>());
      },
    );

    test('formats system-adjacent turn events through descriptor groups', () {
      final message = GameEventNotificationMessage.from(
        AppLocalizationsEn(),
        const GameEventNotification(
          id: 2,
          event: StabilityBandChangedEvent(
            playerId: 'player_1',
            previousBand: StabilityBand.stable,
            newBand: StabilityBand.strained,
            net: -2,
          ),
          state: GameState(activePlayerId: 'player_1'),
          playerId: 'player_1',
        ),
        null,
      );

      expect(message.title, 'Empire stability changed');
      expect(message.body, contains('Strained (-2)'));
      expect(message.thumbnail, isA<IconEventNotificationThumbnail>());
    });
  });
}
