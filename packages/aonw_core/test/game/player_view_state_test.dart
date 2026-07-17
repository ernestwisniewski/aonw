import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/view.dart';
import 'package:test/test.dart';

void main() {
  const codec = PlayerViewStateWireCodec();

  test('owns a projected legacy state before wire serialization', () {
    final gold = <String, int>{'player-1': 12};
    final units = <GameUnit>[
      GameUnit(
        id: 'unit-1',
        ownerPlayerId: 'player-1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 2,
      ),
    ];
    final projectedState = PersistentGameState(playerGold: gold, units: units);
    final view = PlayerViewState(
      projectedState: projectedState,
      recipientPlayerId: 'player-1',
    );
    final expected = codec.encode(view);

    gold['player-1'] = 999;
    units.clear();

    expect(view.recipientPlayerId, 'player-1');
    expect(codec.encode(view), expected);
  });

  test('wire codec preserves persistent JSON without view metadata', () {
    final projectedState = PersistentGameState.snapshot(
      playerColors: const {'player-1': 0xFFAA5500},
      playerGold: const {'player-1': 12},
    );
    final view = PlayerViewState(
      projectedState: projectedState,
      recipientPlayerId: 'player-1',
    );

    final encoded = codec.encode(view);

    expect(encoded, projectedState.toJson());
    expect(encoded, isNot(contains('recipientPlayerId')));
    (encoded['playerGold'] as Map<String, dynamic>)['player-1'] = 99;
    expect(codec.encode(view)['playerGold'], {'player-1': 12});
  });
}
