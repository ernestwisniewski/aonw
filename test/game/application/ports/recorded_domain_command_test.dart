import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/recorded_domain_command_codec.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecordedDomainCommandCodec', () {
    test('ignores every historical non-domain discriminator', () {
      final decodedTypes = <String>{};

      expect(_historicalCommandFixtures, hasLength(25));
      for (final fixture in _historicalCommandFixtures) {
        expect(
          RecordedDomainCommandCodec.fromJson(fixture.json),
          isNull,
          reason: '${fixture.json['type']} must not recreate a GameIntent',
        );
        decodedTypes.add(fixture.json['type']! as String);
      }

      expect(decodedTypes, _historicalCommandTypes);
    });

    test('maps removed lifecycle records to replay tombstones', () {
      expect(
        RecordedDomainCommandCodec.fromJson(const {
          'type': 'ResetUnitMovement',
          'playerId': 'player_1',
        }),
        isNull,
      );
      expect(
        RecordedDomainCommandCodec.fromJson(const {
          'type': 'SetActivePlayer',
          'playerId': 'player_2',
          'canAct': false,
        }),
        isNull,
      );
    });
  });

  group('RecordedDomainCommand', () {
    test('round-trips command, events, actor and timestamp', () {
      final logged = RecordedDomainCommand(
        offset: 7,
        timestamp: DateTime.utc(2026, 4, 24, 10, 30),
        turn: 4,
        actorPlayerId: 'p1',
        canAct: false,
        commandTick: 42,
        ignoreFogOfWar: true,
        command: const MoveUnitCommand('unit_1', 4, 5),
        events: const [
          UnitMovedEvent(
            unitId: 'unit_1',
            fromCol: 3,
            fromRow: 5,
            toCol: 4,
            toRow: 5,
          ),
        ],
        activity: const [
          LoggedActivityEntry(
            eventIndex: 0,
            playerId: 'p1',
            event: UnitMovedEvent(
              unitId: 'unit_1',
              fromCol: 3,
              fromRow: 5,
              toCol: 4,
              toRow: 5,
            ),
            context: GameActivityContext.empty,
          ),
        ],
      );

      final json = logged.toJson();
      final restored = RecordedDomainCommand.fromJson(json);

      expect(restored.offset, 7);
      expect(restored.timestamp, DateTime.utc(2026, 4, 24, 10, 30));
      expect(restored.turn, 4);
      expect(restored.actorPlayerId, 'p1');
      expect(restored.canAct, isFalse);
      expect(restored.commandTick, 42);
      expect(restored.ignoreFogOfWar, isTrue);
      expect(restored.toCommandContext().actorPlayerId, 'p1');
      expect(restored.toCommandContext().combatSeedTurn, 4);
      expect(restored.toCommandContext().ignoreFogOfWar, isTrue);
      expect(
        restored.toCommandContext(paceBalance: PaceBalance.long120).paceBalance,
        PaceBalance.long120,
      );
      expect(restored.command, isA<MoveUnitCommand>());
      expect(restored.events.single, isA<UnitMovedEvent>());
      expect(restored.activity.single.event, isA<UnitMovedEvent>());
    });

    test('reads a historical presentation intent as a tombstone', () {
      final restored = RecordedDomainCommand.fromJson({
        'offset': 1,
        'timestamp': DateTime.utc(2026).toIso8601String(),
        'turn': 1,
        'command': {'type': 'ToggleMoveTargeting'},
      });

      expect(restored.command, isNull);
    });

    test('reads lifecycle tombstones without dispatchable commands', () {
      final restored = RecordedDomainCommand.fromJson({
        'offset': 1,
        'timestamp': DateTime.utc(2026).toIso8601String(),
        'turn': 1,
        'command': {'type': 'ResetUnitMovement', 'playerId': 'p1'},
      });
      expect(restored.command, isNull);
    });

    test('round-trips an event-only entry without inventing a command', () {
      final logged = RecordedDomainCommand(
        offset: 2,
        timestamp: DateTime.utc(2026),
        turn: null,
        actorPlayerId: 'p2',
        command: null,
        events: const [
          UnitAttackedEvent(
            attackerUnitId: 'attacker',
            attackerOwnerPlayerId: 'p2',
            defenderUnitId: 'defender',
            defenderOwnerPlayerId: 'p1',
          ),
        ],
      );

      final json = logged.toJson();
      final restored = RecordedDomainCommand.fromJson(json);

      expect(json.containsKey('command'), isFalse);
      expect(json.containsKey('turn'), isFalse);
      expect(restored.command, isNull);
      expect(restored.turn, isNull);
      expect(restored.events.single, isA<UnitAttackedEvent>());
    });
  });
}

const _historicalCommandFixtures =
    <({Map<String, dynamic> json, Object command})>[
      (
        json: {'type': 'TileTapped', 'col': 2, 'row': 3},
        command: TileTappedCommand(2, 3),
      ),
      (
        json: {'type': 'CityTapped', 'cityId': 'city_1'},
        command: CityTappedCommand('city_1'),
      ),
      (
        json: {
          'type': 'StartMerchantTradeRouteSelection',
          'unitId': 'merchant_1',
        },
        command: StartMerchantTradeRouteSelectionCommand('merchant_1'),
      ),
      (
        json: {
          'type': 'CancelMerchantTradeRouteSelection',
          'unitId': 'merchant_2',
        },
        command: CancelMerchantTradeRouteSelectionCommand('merchant_2'),
      ),
      (
        json: {
          'type': 'StartMerchantMoveToCitySelection',
          'unitId': 'merchant_3',
        },
        command: StartMerchantMoveToCitySelectionCommand('merchant_3'),
      ),
      (
        json: {
          'type': 'CancelMerchantMoveToCitySelection',
          'unitId': 'merchant_4',
        },
        command: CancelMerchantMoveToCitySelectionCommand('merchant_4'),
      ),
      (
        json: {'type': 'CancelResearchSelection', 'playerId': 'player_3'},
        command: CancelResearchSelectionCommand('player_3'),
      ),
      (
        json: {'type': 'ToggleMoveTargeting'},
        command: ToggleMoveTargetingCommand(),
      ),
      (
        json: {'type': 'StartCityFounding'},
        command: StartCityFoundingCommand(),
      ),
      (
        json: {'type': 'CancelCityFounding'},
        command: CancelCityFoundingCommand(),
      ),
      (
        json: {'type': 'StartCityWorkedHexSelection', 'cityId': 'city_2'},
        command: StartCityWorkedHexSelectionCommand('city_2'),
      ),
      (
        json: {'type': 'CancelCityWorkedHexSelection', 'cityId': 'city_3'},
        command: CancelCityWorkedHexSelectionCommand('city_3'),
      ),
      (
        json: {'type': 'StartCityExpansionSelection', 'cityId': 'city_4'},
        command: StartCityExpansionSelectionCommand('city_4'),
      ),
      (
        json: {'type': 'CancelCityExpansionSelection', 'cityId': 'city_5'},
        command: CancelCityExpansionSelectionCommand('city_5'),
      ),
      (
        json: {'type': 'StartWorkerActionSelection', 'unitId': 'worker_1'},
        command: StartWorkerActionSelectionCommand('worker_1'),
      ),
      (
        json: {'type': 'CancelWorkerActionSelection', 'unitId': 'worker_2'},
        command: CancelWorkerActionSelectionCommand('worker_2'),
      ),
      (
        json: {'type': 'StartAttackTargeting', 'attackerUnitId': 'warrior_1'},
        command: StartAttackTargetingCommand('warrior_1'),
      ),
      (
        json: {'type': 'CancelAttackTargeting', 'attackerUnitId': 'warrior_2'},
        command: CancelAttackTargetingCommand('warrior_2'),
      ),
      (
        json: {
          'type': 'StartCommanderMergeSelection',
          'commanderUnitId': 'commander_1',
        },
        command: StartCommanderMergeSelectionCommand('commander_1'),
      ),
      (
        json: {
          'type': 'CancelCommanderMergeSelection',
          'commanderUnitId': 'commander_2',
        },
        command: CancelCommanderMergeSelectionCommand('commander_2'),
      ),
      (
        json: {'type': 'SelectTile', 'col': 5, 'row': 6},
        command: SelectTileCommand(5, 6),
      ),
      (
        json: {'type': 'SelectUnit', 'unitId': 'warrior_3'},
        command: SelectUnitCommand('warrior_3'),
      ),
      (
        json: {'type': 'SelectCity', 'cityId': 'city_6'},
        command: SelectCityCommand('city_6'),
      ),
      (
        json: {
          'type': 'FocusNextPendingAction',
          'playerId': 'player_4',
          'preferredObjectiveAdvice': 'improveField',
          'actionIndex': 4,
          'actionStep': -1,
        },
        command: FocusNextPendingActionCommand(
          'player_4',
          preferredObjectiveAdvice: GameObjectiveAdvice.improveField,
          actionIndex: 4,
          actionStep: -1,
        ),
      ),
      (
        json: {'type': 'FocusTurnStartAction', 'playerId': 'player_5'},
        command: FocusTurnStartActionCommand('player_5'),
      ),
    ];

const _historicalCommandTypes = {
  'TileTapped',
  'CityTapped',
  'StartMerchantTradeRouteSelection',
  'CancelMerchantTradeRouteSelection',
  'StartMerchantMoveToCitySelection',
  'CancelMerchantMoveToCitySelection',
  'CancelResearchSelection',
  'ToggleMoveTargeting',
  'StartCityFounding',
  'CancelCityFounding',
  'StartCityWorkedHexSelection',
  'CancelCityWorkedHexSelection',
  'StartCityExpansionSelection',
  'CancelCityExpansionSelection',
  'StartWorkerActionSelection',
  'CancelWorkerActionSelection',
  'StartAttackTargeting',
  'CancelAttackTargeting',
  'StartCommanderMergeSelection',
  'CancelCommanderMergeSelection',
  'SelectTile',
  'SelectUnit',
  'SelectCity',
  'FocusNextPendingAction',
  'FocusTurnStartAction',
};
