import 'package:aonw/game/presentation/screens/lobby/lobby_player_setup_controller.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LobbyPlayerSetupController', () {
    test('manages editable hot-seat players and builds domain players', () {
      final controller = LobbyPlayerSetupController(
        flow: NewGameFlow.hotSeat,
        primaryCountry: PlayerCountry.poland,
      );
      addTearDown(controller.dispose);

      controller.applyLocalizedDefaults(_nameFor);

      expect(controller.playerCount, 2);
      expect(controller.canAddPlayers, isTrue);
      expect(controller.canEditPlayerKinds, isTrue);
      expect(controller.nameControllerAt(0).text, 'poland-1');

      expect(controller.addPlayer(_nameFor), isTrue);
      expect(controller.playerCount, 3);
      expect(controller.setKind(1, PlayerKind.ai), isTrue);
      expect(controller.setCountry(1, PlayerCountry.sweden, _nameFor), isTrue);
      expect(
        controller.countryOptionsFor(2),
        isNot(contains(PlayerCountry.sweden)),
      );

      controller.nameControllerAt(1).text = '';
      final players = controller.buildPlayers(_nameFor);

      expect(players, hasLength(3));
      expect(players[1].name, 'sweden-2');
      expect(players[1].kind, PlayerKind.ai);
      expect(players[1].ai?.strategyId, AiStrategyId.mcts);
      expect(players[1].ai?.seed, 1001);
    });

    test(
      'locks single-player opponents as AI and keeps localized names fresh',
      () {
        final controller = LobbyPlayerSetupController(
          flow: NewGameFlow.singlePlayer,
          primaryCountry: PlayerCountry.japan,
        );
        addTearDown(controller.dispose);

        controller.applyLocalizedDefaults(_nameFor);

        expect(controller.playerCount, NewGameFlowX.singlePlayerPlayerCount);
        expect(controller.canAddPlayers, isFalse);
        expect(controller.canEditPlayerKinds, isFalse);
        expect(controller.kindAt(0), PlayerKind.human);
        expect(controller.kindAt(1), PlayerKind.ai);
        expect(controller.addPlayer(_nameFor), isFalse);
        expect(controller.setKind(1, PlayerKind.human), isFalse);

        expect(controller.nameControllerAt(0).text, 'japan-1');
        expect(
          controller.setCountry(0, PlayerCountry.sweden, _nameFor),
          isTrue,
        );
        expect(controller.nameControllerAt(0).text, 'sweden-1');

        final players = controller.buildPlayers(_nameFor);

        expect(players.first.country, PlayerCountry.sweden);
        expect(players.first.ai, isNull);
        expect(players.skip(1).every((player) => player.ai != null), isTrue);
      },
    );

    test('uses map player capacity as the add-player limit', () {
      final controller = LobbyPlayerSetupController(
        flow: NewGameFlow.hotSeat,
        primaryCountry: PlayerCountry.poland,
        maximumPlayers: 3,
      );
      addTearDown(controller.dispose);

      controller.applyLocalizedDefaults(_nameFor);

      expect(controller.maximumPlayers, 3);
      expect(controller.addPlayer(_nameFor), isTrue);
      expect(controller.playerCount, 3);
      expect(controller.addPlayer(_nameFor), isFalse);
      expect(controller.playerCount, 3);
    });

    test('trims players when map capacity shrinks after loading map data', () {
      final controller = LobbyPlayerSetupController(
        flow: NewGameFlow.hotSeat,
        primaryCountry: PlayerCountry.poland,
        maximumPlayers: 4,
      );
      addTearDown(controller.dispose);

      controller.applyLocalizedDefaults(_nameFor);
      expect(controller.addPlayer(_nameFor), isTrue);
      expect(controller.addPlayer(_nameFor), isTrue);
      expect(controller.playerCount, 4);

      expect(controller.updateMaximumPlayers(3), isTrue);

      expect(controller.maximumPlayers, 3);
      expect(controller.playerCount, 3);
      expect(controller.addPlayer(_nameFor), isFalse);
      expect(controller.canStartLocalGame, isTrue);
    });
  });
}

String _nameFor(int index, PlayerCountry country) =>
    '${country.name}-${index + 1}';
