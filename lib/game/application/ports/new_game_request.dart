import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';

class NewGameRequest {
  final String name;
  final String mapName;
  final MapSource mapSource;
  final GameMode gameMode;
  final MatchRules matchRules;
  final List<Player> players;
  final MapData? mapData;
  final int? startPositionSeed;

  const NewGameRequest({
    required this.name,
    required this.mapName,
    required this.mapSource,
    this.gameMode = GameMode.hotSeat,
    this.matchRules = MatchRules.standard,
    this.players = const [],
    this.mapData,
    this.startPositionSeed,
  });
}
