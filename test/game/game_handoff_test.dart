import 'package:aonw/game/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(gameHandoffProvider), isNull);
  });

  test('setPending sets handoff data', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const data = HandoffData(
      playerId: 'player_2',
      playerName: 'Bob',
      playerColorValue: 0xFFc45050,
      turnNumber: 2,
    );
    container.read(gameHandoffProvider.notifier).setPending(data);

    final state = container.read(gameHandoffProvider);
    expect(state, isNotNull);
    expect(state!.playerId, 'player_2');
    expect(state.turnNumber, 2);
  });

  test('clear sets state back to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(gameHandoffProvider.notifier)
        .setPending(
          const HandoffData(
            playerId: 'player_2',
            playerName: 'Bob',
            playerColorValue: 0xFFc45050,
            turnNumber: 2,
          ),
        );
    container.read(gameHandoffProvider.notifier).clear();

    expect(container.read(gameHandoffProvider), isNull);
  });
}
