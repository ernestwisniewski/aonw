import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Immutable dependency bundle shared by reducers for a single command pass.
///
/// Reducers stay pure and testable, while call sites avoid repeating the same
/// map, rules, command context, and fog service parameters for every branch.
final class ReducerEnvironment {
  final MapReadView mapData;
  final GameRuleset ruleset;
  final GameCommandContext context;
  final FogOfWarService fogOfWarService;

  const ReducerEnvironment({
    required this.mapData,
    this.ruleset = GameRuleset.defaults,
    this.context = const GameCommandContext(),
    this.fogOfWarService = const FogOfWarService(),
  });

  CityRuleset get cityRuleset => ruleset.city;

  TechnologyRuleset get technologyRuleset => ruleset.technology;

  StabilityRuleset get stabilityRuleset => ruleset.stability;

  WonderRuleset get wonderRuleset => ruleset.wonders;

  PaceBalance get paceBalance => context.paceBalance;

  ReducerEnvironment copyWith({
    MapReadView? mapData,
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
