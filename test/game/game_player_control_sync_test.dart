import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers.dart';
import 'package:aonw/game/presentation/widgets.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);

const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFa65f3f);

GameSave _save({List<Player> players = const [_player1]}) {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: {
      for (final player in players) player.id: PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 4, 16),
    camera: CameraState.zero,
    players: players,
  );
}

Widget _host(
  GameSave? save,
  ValueChanged<PlayerControlState> onState, {
  NetworkSession? networkSession,
}) {
  return ProviderScope(
    overrides: [
      gamePlayerControlSaveProvider.overrideWithValue(save),
      if (networkSession != null)
        networkSessionProvider.overrideWithValue(networkSession),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          GamePlayerControlSync(gameSave: save),
          Consumer(
            builder: (context, ref, child) {
              onState(ref.watch(gamePlayerControlControllerProvider));
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('syncs player control state after render', (tester) async {
    final states = <PlayerControlState>[];

    await tester.pumpWidget(_host(_save(), states.add));

    final state = states.last;
    expect(state.activePlayerId, 'player_1');
    expect(state.canAct, isTrue);
  });

  testWidgets('resyncs player control state when save changes', (tester) async {
    final states = <PlayerControlState>[];

    await tester.pumpWidget(_host(_save(), states.add));
    await tester.pumpWidget(
      _host(_save(players: const [_player2]), states.add),
    );

    final state = states.last;
    expect(state.activePlayerId, 'player_2');
    expect(state.canAct, isTrue);
  });

  testWidgets('syncs to the multiplayer session player after render', (
    tester,
  ) async {
    final states = <PlayerControlState>[];
    final save = _save(players: const [_player1, _player2]);

    await tester.pumpWidget(
      _host(
        save,
        states.add,
        networkSession: NetworkSession(
          userId: 'user-2',
          playerId: 'player_2',
          token: AuthToken('token'),
          matchId: save.id,
        ),
      ),
    );
    expect(states.last.activePlayerId, 'player_1');

    await tester.pump();

    final state = states.last;
    expect(state.activePlayerId, 'player_2');
    expect(state.canAct, isTrue);
  });
}
