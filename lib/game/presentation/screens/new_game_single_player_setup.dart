import 'dart:math' as math;

import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';

typedef SinglePlayerLeaderNameResolver = String Function(PlayerCountry country);

abstract final class NewGameSinglePlayerSetup {
  static List<PlayerCountry> countries(
    PlayerCountry selectedPlayerCountry, {
    int playerCount = NewGameFlowX.singlePlayerPlayerCount,
    math.Random? random,
  }) {
    final opponents = [
      for (final country in PlayerCountry.values)
        if (country != selectedPlayerCountry) country,
    ]..shuffle(random ?? math.Random());
    return [
      selectedPlayerCountry,
      ...opponents.take(
        MapPlayerCapacityRules.aiOpponentsForPlayerCount(playerCount),
      ),
    ];
  }

  static List<Player> players({
    required PlayerCountry selectedPlayerCountry,
    required AiDifficulty aiDifficulty,
    required SinglePlayerLeaderNameResolver leaderNameFor,
    int playerCount = NewGameFlowX.singlePlayerPlayerCount,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final playerCountries = countries(
      selectedPlayerCountry,
      playerCount: playerCount,
      random: rng,
    );
    return List<Player>.generate(playerCount, (index) {
      final base = Player.forIndex(index);
      final country = playerCountries[index];
      final isHuman = index == 0;
      return Player(
        id: base.id,
        name: leaderNameFor(country),
        colorValue: base.colorValue,
        country: country,
        kind: isHuman ? PlayerKind.human : PlayerKind.ai,
        ai: isHuman
            ? null
            : AiPlayer(
                strategyId: AiStrategyId.mcts,
                difficulty: aiDifficulty,
                persona: AiPersona.balanced,
                seed: rng.nextInt(0x7fffffff),
              ),
      );
    });
  }

  static int playerCountForMapData(MapData mapData) {
    return MapPlayerCapacityRules.singlePlayerPlayersForMapData(mapData);
  }

  static int playerCountForMapName(String? mapName) {
    return MapPlayerCapacityRules.singlePlayerPlayersForMapName(mapName);
  }

  static int aiOpponentCountForPlayerCount(int playerCount) {
    return MapPlayerCapacityRules.aiOpponentsForPlayerCount(playerCount);
  }
}
