import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';

/// Immutable dependency bundle shared by reducers for a single command pass.
///
/// Reducers stay pure and testable, while call sites avoid repeating the same
/// map, rules, command context, and fog service parameters for every branch.
final class ReducerEnvironment {
  final MapData mapData;
  final GameRuleset ruleset;
  final GameCommandContext context;
  final FogOfWarService fogOfWarService;

  const ReducerEnvironment({
    required this.mapData,
    this.ruleset = GameRuleset.defaults,
    this.context = const GameCommandContext(),
    this.fogOfWarService = const FogOfWarService(),
  });

  ReducerEnvironment copyWith({
    MapData? mapData,
    GameRuleset? ruleset,
    GameCommandContext? context,
    FogOfWarService? fogOfWarService,
  }) {
    return ReducerEnvironment(
      mapData: mapData ?? this.mapData,
      ruleset: ruleset ?? this.ruleset,
      context: context ?? this.context,
      fogOfWarService: fogOfWarService ?? this.fogOfWarService,
    );
  }
}
