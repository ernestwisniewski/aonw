import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/analysis/human_trace_benchmark.dart';
import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_player.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';

void main(List<String> args) async {
  if (_hasFlag(args, '--help') || _hasFlag(args, '-h')) {
    stdout.writeln(_usage);
    return;
  }

  try {
    final options = _Options.fromArgs(args);
    final traceJson =
        jsonDecode(await File(options.tracePath).readAsString())
            as Map<String, dynamic>;
    final benchmark = HumanTraceBenchmark.fromTraceJson(traceJson);
    final countries = _countriesFromTrace(traceJson);
    final configs = [
      for (var index = 0; index < options.games; index++)
        _configFor(
          countries: countries,
          turns: options.turns ?? benchmark.lastCompletedTurn,
          strategyId: options.strategyId,
          difficulty: options.difficulty,
          seed: options.seed + index * 1000,
        ),
    ];
    final simulation = BalanceRunner.run(configs: configs);
    final report = HumanTraceSimulationBenchmark(
      benchmark,
    ).evaluate(simulation);
    final jsonReport = {
      'parameters': {
        'trace': options.tracePath,
        'games': options.games,
        'turns': options.turns ?? benchmark.lastCompletedTurn,
        'strategyId': options.strategyId.name,
        'difficulty': options.difficulty.name,
        'seed': options.seed,
        'countries': [for (final country in countries) country.name],
      },
      ...report.toJson(),
    };

    if (options.jsonOut != null) {
      final file = File(options.jsonOut!);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(jsonReport)}\n',
      );
      stdout.writeln('Wrote ${file.path}');
    }
    if (options.markdownOut != null) {
      final file = File(options.markdownOut!);
      await file.parent.create(recursive: true);
      await file.writeAsString(report.toMarkdown());
      stdout.writeln('Wrote ${file.path}');
    }
    if (options.jsonOut == null && options.markdownOut == null) {
      stdout.write(report.toMarkdown());
    }
    if (!report.passed && options.failOnRegression) {
      exitCode = 1;
    }
  } on _UsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln()
      ..writeln(_usage);
    exitCode = 64;
  }
}

EconomySimulationConfig _configFor({
  required List<PlayerCountry> countries,
  required int turns,
  required AiStrategyId strategyId,
  required AiDifficulty difficulty,
  required int seed,
}) {
  if (countries.length != 4) {
    throw _UsageException(
      'Trace benchmark requires exactly four player countries, got '
      '${countries.length}.',
    );
  }
  return EconomySimulationConfig.forGameLength(
    gameLength: GameLengthConfig.unlimited,
    turns: turns,
    player: _player(
      id: 'player_1',
      country: countries[0],
      colorValue: Player.palette[0],
      strategyId: strategyId,
      difficulty: difficulty,
      seed: seed + 1,
    ),
    opponents: [
      for (var index = 1; index < countries.length; index++)
        _player(
          id: 'player_${index + 1}',
          country: countries[index],
          colorValue: Player.palette[index % Player.palette.length],
          strategyId: strategyId,
          difficulty: difficulty,
          seed: seed + index + 1,
        ),
    ],
  );
}

Player _player({
  required String id,
  required PlayerCountry country,
  required int colorValue,
  required AiStrategyId strategyId,
  required AiDifficulty difficulty,
  required int seed,
}) {
  return Player(
    id: id,
    name: _countryLabel(country),
    colorValue: colorValue,
    country: country,
    kind: PlayerKind.ai,
    ai: AiPlayer(strategyId: strategyId, difficulty: difficulty, seed: seed),
  );
}

List<PlayerCountry> _countriesFromTrace(Map<String, dynamic> traceJson) {
  final save = traceJson['save'] as Map<String, dynamic>? ?? const {};
  final players = save['players'] as List<dynamic>? ?? const [];
  if (players.isEmpty) {
    return const [
      PlayerCountry.poland,
      PlayerCountry.germany,
      PlayerCountry.france,
      PlayerCountry.unitedKingdom,
    ];
  }
  return [
    for (final raw in players)
      _enumByName<PlayerCountry>(
        (raw as Map<String, dynamic>)['country'] as String?,
        PlayerCountry.values,
        'country',
      ),
  ];
}

String _countryLabel(PlayerCountry country) {
  final spaced = country.name.replaceAllMapped(
    RegExp(r'(?<=[a-z])([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

bool _hasFlag(List<String> args, String flag) => args.contains(flag);

T _enumByName<T extends Enum>(String? name, List<T> values, String label) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw _UsageException('Unknown $label: $name');
}

class _Options {
  const _Options({
    required this.tracePath,
    required this.games,
    required this.turns,
    required this.seed,
    required this.strategyId,
    required this.difficulty,
    required this.jsonOut,
    required this.markdownOut,
    required this.failOnRegression,
  });

  final String tracePath;
  final int games;
  final int? turns;
  final int seed;
  final AiStrategyId strategyId;
  final AiDifficulty difficulty;
  final String? jsonOut;
  final String? markdownOut;
  final bool failOnRegression;

  factory _Options.fromArgs(List<String> args) {
    final tracePath = _readOption(args, '--trace');
    if (tracePath == null || tracePath.trim().isEmpty) {
      throw const _UsageException('--trace is required.');
    }
    return _Options(
      tracePath: tracePath,
      games: int.parse(_readOption(args, '--games') ?? '1'),
      turns: _readOption(args, '--turns') == null
          ? null
          : int.parse(_readOption(args, '--turns')!),
      seed: int.parse(_readOption(args, '--seed') ?? '1001'),
      strategyId: _enumByName<AiStrategyId>(
        _readOption(args, '--strategy') ?? AiStrategyId.basic.name,
        AiStrategyId.values,
        'strategy',
      ),
      difficulty: _enumByName<AiDifficulty>(
        _readOption(args, '--difficulty') ?? AiDifficulty.normal.name,
        AiDifficulty.values,
        'difficulty',
      ),
      jsonOut: _readOption(args, '--json-out'),
      markdownOut: _readOption(args, '--markdown-out'),
      failOnRegression: _hasFlag(args, '--fail-on-regression'),
    );
  }
}

String? _readOption(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

class _UsageException implements Exception {
  const _UsageException(this.message);
  final String message;
}

const _usage = '''
Usage:
  dart run tool/run_human_trace_benchmark.dart --trace <path> [options]

Options:
  --trace <path>        Human trace JSON path, required
  --games <n>          Number of simulations, default: 1
  --turns <n>          Turn count, default: trace lastCompletedTurn
  --strategy <id>      basic, mcts, utility, scripted, random; default: basic
  --difficulty <id>    easy, normal, hard; default: normal
  --seed <n>           Base seed, default: 1001
  --json-out <path>    Write machine-readable report
  --markdown-out <path>
                       Write markdown report
  --fail-on-regression Exit with code 1 when fail-level findings exist
''';
