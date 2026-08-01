import 'package:aonw_core/game/view.dart';
import 'package:test/test.dart';

void main() {
  const codec = PlayerViewStateWireCodec();

  test('owns a projected JSON tree before wire serialization', () {
    final gold = <String, int>{'player-1': 12};
    final units = <Map<String, dynamic>>[
      {'id': 'unit-1', 'ownerPlayerId': 'player-1'},
    ];
    final projectedState = <String, dynamic>{
      'playerGold': gold,
      'units': units,
    };
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

  test('wire codec preserves projection JSON without view metadata', () {
    final projectedState = <String, dynamic>{
      'playerColors': <String, int>{'player-1': 0xFFAA5500},
      'playerGold': <String, int>{'player-1': 12},
    };
    final view = PlayerViewState(
      projectedState: projectedState,
      recipientPlayerId: 'player-1',
    );

    final encoded = codec.encode(view);

    expect(encoded, projectedState);
    expect(encoded, isNot(contains('recipientPlayerId')));
    (encoded['playerGold'] as Map<String, dynamic>)['player-1'] = 99;
    expect(codec.encode(view)['playerGold'], {'player-1': 12});
  });
}
