import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/diplomacy/diplomacy_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiplomacyReducer kernel cutover', () {
    test('preserves exact state identity when the kernel rejects', () {
      final state = _state();
      const command = SendGoldGiftCommand(
        playerId: 'p1',
        targetPlayerId: 'p2',
        amount: 10,
      );

      final cannotAct = DiplomacyReducer.sendGoldGift(
        state,
        command,
        context: const GameCommandContext(canAct: false),
      );
      final actorMismatch = DiplomacyReducer.sendGoldGift(
        state,
        command,
        context: const GameCommandContext(actorPlayerId: 'p2'),
      );

      expect(cannotAct.state, same(state));
      expect(cannotAct.events, isEmpty);
      expect(actorMismatch.state, same(state));
      expect(actorMismatch.events, isEmpty);
    });

    test('keeps unrelated slices shared and forwards kernel events', () {
      final state = _state();
      final units = state.units;
      final warWeariness = state.playerWarWeariness;
      final stability = state.playerStabilityNet;
      final intendedAttacks = state.intendedAttacks;
      final tradeAgreements = state.resourceTradeAgreements;

      final result = DiplomacyReducer.sendGoldGift(
        state,
        const SendGoldGiftCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          amount: 10,
        ),
        context: const GameCommandContext(combatSeedTurn: 13),
      );
      final scoreEvent = result.events
          .whereType<DiplomaticScoreChangedEvent>()
          .single;

      expect(result.state, isNot(same(state)));
      expect(result.state.units, same(units));
      expect(result.state.fogOfWar, same(state.fogOfWar));
      expect(result.state.research, same(state.research));
      expect(result.state.interaction, same(state.interaction));
      expect(result.state.playerWarWeariness, same(warWeariness));
      expect(result.state.playerStabilityNet, same(stability));
      expect(result.state.intendedAttacks, same(intendedAttacks));
      expect(result.state.resourceTradeAgreements, same(tradeAgreements));
      expect(result.state.playerGold, {'p1': 10, 'p2': 10});
      expect(scoreEvent.sourceId, 'gold_gift.13.p1.p2');
    });

    test('falls back from active player to command player as actor', () {
      const command = SendGoldGiftCommand(
        playerId: 'p1',
        targetPlayerId: 'p2',
        amount: 10,
      );

      final activePlayerResult = DiplomacyReducer.sendGoldGift(
        _state(),
        command,
      );
      final commandPlayerResult = DiplomacyReducer.sendGoldGift(
        _state(activePlayerId: ''),
        command,
      );

      expect(activePlayerResult.events, isNotEmpty);
      expect(commandPlayerResult.events, isNotEmpty);
    });
  });
}

GameState _state({String activePlayerId = 'p1'}) {
  final state = GameState(
    activePlayerId: activePlayerId,
    playerColors: const {'p1': 1, 'p2': 2},
    playerGold: const {'p1': 20, 'p2': 0},
    playerWarWeariness: Map.unmodifiable({'p1': 3}),
    playerStabilityNet: Map.unmodifiable({'p1': 2}),
    units: List.unmodifiable([
      GameUnit.startingWarrior(ownerPlayerId: 'p1', col: 0, row: 0),
    ]),
    diplomacy: DiplomacyState.empty.addContact('p1', 'p2'),
  );
  return state.copyWith(
    playerWarWeariness: state.playerWarWeariness,
    playerStabilityNet: state.playerStabilityNet,
    units: state.units,
    intendedAttacks: state.intendedAttacks,
    resourceTradeAgreements: state.resourceTradeAgreements,
  );
}
