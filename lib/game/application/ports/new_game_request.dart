import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/map/domain/map_selection.dart';

class NewGameRequest {
  final String name;
  final String mapName;
  final MapSource mapSource;
  final GameMode gameMode;
  final MatchRules matchRules;
  final List<Player> players;
  final WorldMap? mapData;
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
