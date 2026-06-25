import 'dart:math' as math;

import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game_single_player_setup.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewGameSinglePlayerSetup', () {
    test('builds human player plus three AI opponents', () {
      final players = NewGameSinglePlayerSetup.players(
        selectedPlayerCountry: PlayerCountry.france,
        aiDifficulty: AiDifficulty.hard,
        leaderNameFor: (country) => country.name,
        random: math.Random(42),
      );

      expect(players, hasLength(NewGameFlowX.singlePlayerPlayerCount));
      expect(players.first.country, PlayerCountry.france);
      expect(players.first.name, 'france');
      expect(players.first.kind, PlayerKind.human);
      expect(players.first.ai, isNull);
      final aiCountries = players.skip(1).map((player) => player.country);
      expect(aiCountries, isNot(contains(PlayerCountry.france)));
      expect(
        aiCountries.toSet(),
        hasLength(NewGameFlowX.singlePlayerAiOpponentCount),
      );
      expect(players.skip(1).map((player) => player.kind), [
        PlayerKind.ai,
        PlayerKind.ai,
        PlayerKind.ai,
      ]);
      expect(players.skip(1).map((player) => player.ai?.strategyId), [
        AiStrategyId.mcts,
        AiStrategyId.mcts,
        AiStrategyId.mcts,
      ]);
      expect(players.skip(1).map((player) => player.ai?.difficulty), [
        AiDifficulty.hard,
        AiDifficulty.hard,
        AiDifficulty.hard,
      ]);
      expect(
        players.skip(1).map((player) => player.ai?.seed),
        everyElement(greaterThanOrEqualTo(0)),
      );
    });

    test('keeps selected country first and excludes it from AI countries', () {
      final countries = NewGameSinglePlayerSetup.countries(
        PlayerCountry.poland,
        random: math.Random(7),
      );

      expect(countries.first, PlayerCountry.poland);
      expect(countries, hasLength(NewGameFlowX.singlePlayerPlayerCount));
      expect(countries.where((country) => country == PlayerCountry.poland), [
        PlayerCountry.poland,
      ]);
    });

    test('builds fewer AI opponents for three-player maps', () {
      final players = NewGameSinglePlayerSetup.players(
        selectedPlayerCountry: PlayerCountry.france,
        aiDifficulty: AiDifficulty.normal,
        leaderNameFor: (country) => country.name,
        playerCount: 3,
        random: math.Random(9),
      );

      expect(players, hasLength(3));
      expect(players.first.kind, PlayerKind.human);
      expect(players.skip(1).map((player) => player.kind), [
        PlayerKind.ai,
        PlayerKind.ai,
      ]);
    });

    test('reports configured single-player counts for bundled maps', () {
      expect(NewGameSinglePlayerSetup.playerCountForMapName('verdantia'), 4);
      expect(NewGameSinglePlayerSetup.playerCountForMapName('myranth'), 3);
      expect(NewGameSinglePlayerSetup.playerCountForMapName('terenos'), 3);
    });

    test('uses seeded random source deterministically for AI setup', () {
      List<Player> build() => NewGameSinglePlayerSetup.players(
        selectedPlayerCountry: PlayerCountry.france,
        aiDifficulty: AiDifficulty.normal,
        leaderNameFor: (country) => country.name,
        random: math.Random(123),
      );

      final first = build();
      final second = build();

      expect(
        first.map((player) => player.country),
        second.map((player) => player.country),
      );
      expect(
        first.skip(1).map((player) => player.ai?.seed),
        second.skip(1).map((player) => player.ai?.seed),
      );
    });
  });
}
