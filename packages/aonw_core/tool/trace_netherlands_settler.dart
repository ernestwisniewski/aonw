import 'dart:convert';

import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_player.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/city_site_scorer.dart';
import 'package:aonw_core/ai/civilization/civilization_profile_registry.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_config.dart';
import 'package:aonw_core/ai/mcts/mcts_strategy.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/strategic/city_site_planner.dart';
import 'package:aonw_core/ai/strategic/strategic_planner.dart';
import 'package:aonw_core/ai/strategies/basic_strategy.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/turn.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

void main(List<String> args) {
  final playerId = _stringOption(args, '--player-id') ?? 'player_3';
  final seed = _intOption(args, '--seed', 7600);
  final turns = _turnsOption(args, const [31, 36, 42, 48, 54, 60]);
  for (final turn in turns) {
    final config = BalanceRunner.fourPlayerMctsConfig(
      turns: turn,
      aiDifficulty: AiDifficulty.normal,
      seed: seed,
      primaryCountry: PlayerCountry.poland,
      opponentCountries: const [
        PlayerCountry.germany,
        PlayerCountry.netherlands,
        PlayerCountry.japan,
      ],
    );
    final result = EconomySimulation.run(config: config);
    final row = result.rowsByPlayerId[playerId]!.last;
    final mapData = _simulationMap();
    final state =
        PersistentTurnMovementProcessor.resetForPlayers(
          state: result.state,
          playerIds: const ['player_1', 'player_2', 'player_3', 'player_4'],
          mapData: mapData,
        ).state.copyWith(
          fogOfWar: const FogOfWarService().recompute(
            current: result.state.fogOfWar,
            mapData: mapData,
            playerIds: const ['player_1', 'player_2', 'player_3', 'player_4'],
            units: result.state.units,
            cities: result.state.cities,
          ),
        );

    final player = [config.player, ...config.opponents].firstWhere(
      (candidate) => candidate.id == playerId,
      orElse: () => throw ArgumentError.value(playerId, '--player-id'),
    );
    final ai =
        player.ai ?? const AiPlayer(strategyId: AiStrategyId.basic, seed: 1001);
    const registry = CivilizationProfileRegistry();
    final civProfile = registry.profileFor(player.country);
    var context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: turn + 1,
      rng: AiRng.fromTurn(
        turn: turn + 1,
        playerId: playerId,
        baseSeed: ai.seed,
      ),
      persona: ai.personaForProfile(civProfile),
      difficulty: ai.difficulty,
      civProfile: civProfile,
    );
    final view = GameView.fromPersistentState(
      state,
      forPlayerId: playerId,
      turn: turn + 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final assessment = AiEmpireAssessment.fromView(view, context);
    final strategicPlan = const StrategicPlanner().build(
      view: view,
      context: context,
    );
    context = context.copyWith(strategicPlan: strategicPlan);
    final citySitePlan = const CitySitePlanner().compute(
      view: view,
      context: context,
      assessment: assessment,
    );
    final basic = const BasicStrategy().plan(view, context);
    final mcts = const MctsStrategy(
      config: MctsConfig(
        iterationBudget: 32,
        minIterations: 32,
        maxPlanningDepth: 4,
        candidateLimit: 12,
      ),
    ).plan(view, context);

    print('== after turn $turn / planning ${turn + 1} ==');
    print(
      'row cities=${row.cityCount} settlers=${row.settlerCount} military=${row.militaryCount} '
      'moves=${row.moveCommands} attacks=${row.attackCommands} units=${row.unitCount}',
    );
    print(
      'mode=${strategicPlan.mode.name} sites=${citySitePlan.candidates.take(5).map((c) => '${_hex(c.center)}:${c.score.toStringAsFixed(1)}').join(',')} '
      'assignments=${strategicPlan.settlerAssignments.map((id, hex) => MapEntry(id, _hex(hex)))}',
    );
    print(
      'defenses=${strategicPlan.defenses.map((id, defense) => MapEntry(id, defense.assignedUnitIds))}',
    );
    print(
      'warGoals=${strategicPlan.warGoals.map((goal) => '${goal.kind.name}:${goal.targetPlayerId}@${_coord(goal.targetHex)} units=${goal.assignedUnitIds}').join(',')}',
    );
    print('basic=${_commands(basic.commands)}');
    print('mcts=${_commands(mcts.commands)}');
    print(
      'cities=${view.ownCities.map((c) => '${c.id}@${_hex(c.center)}').join(',')}',
    );
    print(
      'remembered=${view.rememberedEnemyCities.map((c) => '${c.ownerPlayerId}@${_hex(c.center)}').join(',')}',
    );
    _printCitySiteDiagnostics(view, context, assessment);
    for (final unit in view.ownUnits.where(
      (unit) => unit.type == GameUnitType.settler || unit.hasSettlers,
    )) {
      _printSettler(view, context, assessment, citySitePlan, unit);
    }
    print('');
  }
}

int _intOption(List<String> args, String name, int defaultValue) {
  final prefix = '$name=';
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg.startsWith(prefix)) {
      return int.parse(arg.substring(prefix.length));
    }
    if (arg == name && index + 1 < args.length) {
      return int.parse(args[index + 1]);
    }
  }
  return defaultValue;
}

List<int> _turnsOption(List<String> args, List<int> defaultValue) {
  final value = _stringOption(args, '--turns');
  if (value == null || value.trim().isEmpty) return defaultValue;
  return [
    for (final part in value.split(','))
      if (part.trim().isNotEmpty) int.parse(part.trim()),
  ];
}

String? _stringOption(List<String> args, String name) {
  final prefix = '$name=';
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length);
    }
    if (arg == name && index + 1 < args.length) {
      return args[index + 1];
    }
  }
  return null;
}

void _printCitySiteDiagnostics(
  GameView view,
  AiContext context,
  AiEmpireAssessment assessment,
) {
  final founders = [
    for (final unit in view.ownUnits)
      if (CityFoundingRules.canFoundCityWith(unit) &&
          unit.queuedPath == null &&
          !unit.isWorking)
        unit,
  ];
  if (founders.isEmpty) return;

  final knownCities = [...view.ownCities, ...view.rememberedEnemyCities];
  final reserved = {
    for (final city in knownCities) city.center,
    for (final city in knownCities) ...city.controlledHexes,
  };
  const scorer = AiCitySiteScorer();
  final rejectionCounts = <String, int>{};
  final samples = <String, List<String>>{};
  final viable = <String>[];

  for (final tile in view.mapData.tiles) {
    final center = CityHex(col: tile.col, row: tile.row);
    final founder = _nearestFounder(founders, center);
    if (founder == null) continue;
    final reason = _siteRejectionReason(
      view: view,
      context: context,
      assessment: assessment,
      scorer: scorer,
      founder: founder,
      center: center,
      knownCities: knownCities,
      reservedHexes: reserved,
    );
    if (reason == null) {
      viable.add(_hex(center));
      continue;
    }
    rejectionCounts.update(reason, (count) => count + 1, ifAbsent: () => 1);
    samples.putIfAbsent(reason, () => <String>[]);
    if (samples[reason]!.length < 4) samples[reason]!.add(_hex(center));
  }

  print(
    'siteDiag viable=${viable.take(6).join(',')} reject=${rejectionCounts.entries.map((e) => '${e.key}:${e.value}[${samples[e.key]!.join(',')}]').join(' ')}',
  );
}

String? _siteRejectionReason({
  required GameView view,
  required AiContext context,
  required AiEmpireAssessment assessment,
  required AiCitySiteScorer scorer,
  required GameUnit founder,
  required CityHex center,
  required List<GameCity> knownCities,
  required Set<CityHex> reservedHexes,
}) {
  final tile = view.mapData.tileAt(center.col, center.row);
  if (tile == null) return 'missing';
  if (!view.visibility.canInspectTile(tile)) return 'unknown';
  if (reservedHexes.contains(center)) return 'reserved';
  final hypotheticalFounder = founder.copyWith(
    col: center.col,
    row: center.row,
  );
  final startFailure = CityFoundingRules.startFailure(
    unit: hypotheticalFounder,
    centerTile: tile,
    cities: knownCities,
  );
  if (startFailure != null) return startFailure.name;
  final site = scorer.scoreSite(
    founder: founder,
    center: center,
    view: view,
    context: context,
    assessment: assessment,
    knownCities: knownCities,
    reservedHexes: reservedHexes,
    requireKnownExclusionZone: false,
  );
  if (site == null) return 'controlled';
  return null;
}

GameUnit? _nearestFounder(List<GameUnit> founders, CityHex center) {
  GameUnit? best;
  var bestDistance = 1 << 30;
  for (final founder in founders) {
    final distance = HexDistance.between(
      HexCoordinate(col: founder.col, row: founder.row),
      HexCoordinate(col: center.col, row: center.row),
    );
    if (distance < bestDistance ||
        (distance == bestDistance &&
            (best == null || founder.id.compareTo(best.id) < 0))) {
      best = founder;
      bestDistance = distance;
    }
  }
  return best;
}

void _printSettler(
  GameView view,
  AiContext context,
  AiEmpireAssessment assessment,
  CitySitePlan plan,
  GameUnit unit,
) {
  const scorer = AiCitySiteScorer();
  final knownCities = [...view.ownCities, ...view.rememberedEnemyCities];
  final reserved = {
    for (final city in knownCities) city.center,
    for (final city in knownCities) ...city.controlledHexes,
  };
  final current = scorer.scoreCurrentSite(
    founder: unit,
    view: view,
    context: context,
    assessment: assessment,
    knownCities: knownCities,
    reservedHexes: reserved,
  );
  final best = scorer.bestNearbySite(
    founder: unit,
    view: view,
    context: context,
    assessment: assessment,
    knownCities: knownCities,
    reservedHexes: reserved,
    requireKnownExclusionZone: false,
  );
  final assigned = context.strategicPlan?.settlerAssignments[unit.id];
  final pathfinder = UnitMovementPathfinder(
    mapData: view.mapData,
    units: [...view.ownUnits, ...view.visibleEnemyUnits],
  );
  final target = best == null
      ? null
      : view.mapData.tileAt(best.center.col, best.center.row);
  final path = target == null
      ? null
      : pathfinder.plan(unit: unit, targetTile: target);
  print(
    'settler ${unit.id}@(${unit.col},${unit.row}) mp=${unit.movementPoints} queued=${unit.queuedPath != null ? _queued(unit.queuedPath!) : '-'} '
    'assigned=${assigned == null ? '-' : _hex(assigned)} current=${current?.score.toStringAsFixed(1) ?? '-'} '
    'best=${best == null ? '-' : '${_hex(best.center)}:${best.score.toStringAsFixed(1)} known=${best.hasKnownExclusionZone} dist=${best.distanceFromFounder}'} '
    'path=${path == null ? '-' : '${path.totalCost}/${unit.movementPoints} via ${path.steps.map((s) => '(${s.col},${s.row}:${s.cumulativeCost})').join('>')}'} '
    'planSites=${plan.candidates.take(3).map((c) => _hex(c.center)).join(',')}',
  );
  final enemies = view.visibleEnemyUnits
      .where(
        (enemy) =>
            HexDistance.between(
              HexCoordinate(col: unit.col, row: unit.row),
              HexCoordinate(col: enemy.col, row: enemy.row),
            ) <=
            4,
      )
      .map(
        (enemy) =>
            '${enemy.type.name}:${enemy.ownerPlayerId}@(${enemy.col},${enemy.row})',
      )
      .join(',');
  if (enemies.isNotEmpty) {
    print('nearEnemies=$enemies');
  }
}

String _commands(List<GameCommand> commands) {
  return commands
      .map((command) => jsonEncode(GameCommandSerializer.toJson(command)))
      .join(' | ');
}

String _hex(CityHex hex) => '(${hex.col},${hex.row})';

String _coord(HexCoordinate hex) => '(${hex.col},${hex.row})';

String _queued(QueuedMovePath path) =>
    '(${path.targetCol},${path.targetRow}) ${path.steps.length}';

MapData _simulationMap() {
  const size = 9;
  return MapData(
    cols: size,
    rows: size,
    mapName: 'economy_simulation',
    tiles: [
      for (var row = 0; row < size; row++)
        for (var col = 0; col < size; col++) _tile(col, row),
    ],
  );
}

TileData _tile(int col, int row) {
  final resource = switch ((col, row)) {
    (3, 2) || (7, 7) => ResourceType.wheat,
    (2, 4) || (8, 6) => ResourceType.iron,
    (4, 3) => ResourceType.deer,
    _ => null,
  };
  final terrain = switch ((col + row) % 7) {
    0 => TerrainType.hills,
    1 => TerrainType.forest,
    2 => TerrainType.grassland,
    _ => TerrainType.plains,
  };
  return TileData(
    col: col,
    row: row,
    terrains: [terrain],
    resources: [?resource],
    height: terrain == TerrainType.hills ? 1 : 0,
  );
}
