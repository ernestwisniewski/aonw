part of 'balance_pass.dart';

bool _hasFlag(List<String> args, String flag) {
  return args.contains(flag);
}

String? _optionValue(List<String> args, String option) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == option && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$option=')) return arg.substring(option.length + 1);
  }
  return null;
}

int _positiveIntOption(List<String> args, String option, int fallback) {
  final value = _optionValue(args, option);
  if (value == null) return fallback;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw _UsageException('$option must be a positive integer.');
  }
  return parsed;
}

int? _optionalPositiveIntOption(List<String> args, String option) {
  final value = _optionValue(args, option);
  if (value == null) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw _UsageException('$option must be a positive integer.');
  }
  return parsed;
}

GameLengthConfig _targetGameLengthOption(int minutes) {
  try {
    return GameLengthConfig.targetDuration(minutes);
  } on ArgumentError {
    throw const _UsageException('--minutes must be 60, 90, or 120.');
  }
}

AiDifficulty _difficultyOption(List<String> args) {
  final value =
      _optionValue(args, '--difficulty') ?? _optionValue(args, '--diff');
  if (value == null) return AiDifficulty.normal;
  for (final difficulty in AiDifficulty.values) {
    if (difficulty.name == value) return difficulty;
  }
  throw _UsageException(
    '--difficulty must be one of: '
    '${AiDifficulty.values.map((difficulty) => difficulty.name).join(', ')}.',
  );
}

EconomySimulationMctsProfileMode _mctsProfileModeOption(List<String> args) {
  final value =
      _optionValue(args, '--mcts-profile') ??
      _optionValue(args, '--mcts-runtime');
  if (value == null) return EconomySimulationMctsProfileMode.simulation;
  final normalized = _normalizeEnumToken(value);
  for (final mode in EconomySimulationMctsProfileMode.values) {
    if (_normalizeEnumToken(mode.name) == normalized) return mode;
  }
  if (normalized == 'batterysaver') {
    return EconomySimulationMctsProfileMode.batterySaver;
  }
  if (normalized == 'adaptivelocal') {
    return EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer;
  }
  throw const _UsageException(
    '--mcts-profile must be one of: simulation, standard, interactive, '
    'battery-saver, adaptive-local-single-player.',
  );
}

PlayerCountry _countryOption(
  List<String> args,
  String option,
  PlayerCountry fallback,
) {
  final value = _optionValue(args, option);
  if (value == null) return fallback;
  return _countryFromString(value, option);
}

List<PlayerCountry> _civsOption(List<String> args) {
  final value = _optionValue(args, '--civs');
  if (value == null) {
    return const [
      PlayerCountry.germany,
      PlayerCountry.netherlands,
      PlayerCountry.japan,
    ];
  }
  final civs = [
    for (final entry in value.split(','))
      if (entry.trim().isNotEmpty) _countryFromString(entry, '--civs'),
  ];
  if (civs.length != 3) {
    throw const _UsageException(
      '--civs must list exactly three AI civilizations.',
    );
  }
  if (civs.toSet().length != civs.length) {
    throw const _UsageException('--civs cannot contain duplicates.');
  }
  return List.unmodifiable(civs);
}

PlayerCountry _countryFromString(String value, String option) {
  final normalized = _normalizeEnumToken(value);
  for (final country in PlayerCountry.values) {
    if (_normalizeEnumToken(country.name) == normalized) return country;
  }
  throw _UsageException(
    '$option contains unknown civilization "$value". Valid values: '
    '${PlayerCountry.values.map((country) => country.name).join(', ')}.',
  );
}

String _normalizeEnumToken(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _BalancePassOptions {
  const _BalancePassOptions({
    required this.games,
    required this.gameLength,
    required this.rawTurnOverride,
    required this.turns,
    required this.difficulty,
    required this.mctsProfileMode,
    required this.seed,
    required this.primaryCiv,
    required this.civs,
    required this.out,
  });

  factory _BalancePassOptions.fromArgs(List<String> args) {
    final hasTurnOverride = _optionValue(args, '--turns') != null;
    final minutes = _optionalPositiveIntOption(args, '--minutes');
    if (hasTurnOverride && minutes != null) {
      throw const _UsageException('Use either --minutes or --turns, not both.');
    }
    final gameLength = minutes == null
        ? GameLengthConfig.standard60
        : _targetGameLengthOption(minutes);
    final primaryCiv = _countryOption(
      args,
      '--primary-civ',
      PlayerCountry.poland,
    );
    final civs = _civsOption(args);
    if (civs.contains(primaryCiv)) {
      throw const _UsageException(
        '--primary-civ cannot also appear in --civs.',
      );
    }
    return _BalancePassOptions(
      games: _positiveIntOption(args, '--games', 10),
      gameLength: hasTurnOverride ? GameLengthConfig.unlimited : gameLength,
      rawTurnOverride: hasTurnOverride,
      turns: hasTurnOverride
          ? _positiveIntOption(args, '--turns', gameLength.turnLimit!)
          : gameLength.turnLimit!,
      difficulty: _difficultyOption(args),
      mctsProfileMode: _mctsProfileModeOption(args),
      seed: _positiveIntOption(args, '--seed', 4200),
      primaryCiv: primaryCiv,
      civs: civs,
      out: _optionValue(args, '--out') ?? '../../build/reports/ai-balance',
    );
  }

  final int games;
  final GameLengthConfig gameLength;
  final bool rawTurnOverride;
  final int turns;
  final AiDifficulty difficulty;
  final EconomySimulationMctsProfileMode mctsProfileMode;
  final int seed;
  final PlayerCountry primaryCiv;
  final List<PlayerCountry> civs;
  final String out;
}

class _OutputTargets {
  const _OutputTargets({required this.jsonFile, required this.markdownFile});

  factory _OutputTargets.fromPath(String path) {
    if (path.endsWith('.json')) {
      final jsonFile = File(path);
      return _OutputTargets(
        jsonFile: jsonFile,
        markdownFile: File('${path.substring(0, path.length - 5)}.md'),
      );
    }

    final directory = Directory(path);
    return _OutputTargets(
      jsonFile: File('${directory.path}/balance-pass-summary.json'),
      markdownFile: File('${directory.path}/balance-pass-report.md'),
    );
  }

  final File jsonFile;
  final File markdownFile;

  void write({required String json, required String markdown}) {
    jsonFile.parent.createSync(recursive: true);
    markdownFile.parent.createSync(recursive: true);
    jsonFile.writeAsStringSync('$json\n');
    markdownFile.writeAsStringSync(markdown);
  }

  List<File> writeGameCsvs(BalanceBatchReport report) {
    jsonFile.parent.createSync(recursive: true);
    final files = <File>[];
    for (final game in report.games) {
      final file = File(
        '${jsonFile.parent.path}/balance-pass-game-${game.index}.csv',
      )..writeAsStringSync('${_gameCsv(game)}\n');
      files.add(file);
      final runtimeFile = File(
        '${jsonFile.parent.path}/balance-pass-game-${game.index}-runtime.csv',
      )..writeAsStringSync('${_gameRuntimeCsv(game)}\n');
      files.add(runtimeFile);
    }
    return files;
  }

  String _gameCsv(BalanceGameReport game) {
    final lines = <String>[
      ['player_id', ...EconomySimulationTurnRow.csvHeader].map(_csv).join(','),
    ];
    final entries = game.result.rowsByPlayerId.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in entries) {
      for (final row in entry.value) {
        lines.add([entry.key, ...row.toCsvFields()].map(_csv).join(','));
      }
    }
    return lines.join('\n');
  }

  String _gameRuntimeCsv(BalanceGameReport game) {
    final lines = <String>[
      [
        'turn',
        'player_id',
        'strategy_id',
        'mcts_profile_mode',
        'mcts_runtime_profile',
        'adaptive_late_game',
        'planning_us',
        'planning_ms',
        'planned_commands',
        'total_units',
        'total_cities',
        'mcts_iterations',
        'mcts_elapsed_ms',
        'mcts_search_ms',
        'mcts_search_select_ms',
        'mcts_search_expand_ms',
        'mcts_search_rollout_ms',
        'mcts_search_eval_ms',
        'mcts_search_backprop_ms',
        'mcts_validation_ms',
        'mcts_baseline_plan_ms',
        'mcts_merge_ms',
        'mcts_strategy_ms',
        'mcts_explored_nodes',
        'mcts_max_depth',
        'mcts_candidate_calls',
        'mcts_candidate_ms',
        'mcts_source_plan_calls',
        'mcts_source_plan_skipped',
        'mcts_source_plan_ms',
        'mcts_source_plan_commands',
        'mcts_raw_candidates',
        'mcts_selected_candidates',
        'debug_notes',
      ].map(_csv).join(','),
    ];
    for (final row in game.result.aiTurnRuntimes) {
      lines.add(
        [
          row.turn,
          row.playerId,
          row.strategyId.name,
          row.profileMode.name,
          row.runtimeProfile?.name ?? '',
          row.adaptiveLateGame,
          row.planningDuration.inMicroseconds,
          (row.planningDuration.inMicroseconds / 1000.0).toStringAsFixed(3),
          row.plannedCommands,
          row.totalUnitCount,
          row.totalCityCount,
          _metricValue(row, 'mcts.iterations'),
          _metricMicrosAsMs(row, 'mcts.elapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchSelectionElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchExpansionElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchRolloutElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchEvaluationElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.searchBackpropagationElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.validationElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.baselinePlanElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.mergeElapsedMicros'),
          _metricMicrosAsMs(row, 'mcts.strategyElapsedMicros'),
          _metricValue(row, 'mcts.exploredNodes'),
          _metricValue(row, 'mcts.maxDepth'),
          _metricValue(row, 'mcts.candidateCalls'),
          _metricMicrosAsMs(row, 'mcts.candidateElapsedMicros'),
          _metricValue(row, 'mcts.sourcePlanCalls'),
          _metricValue(row, 'mcts.sourcePlanSkipped'),
          _metricMicrosAsMs(row, 'mcts.sourcePlanElapsedMicros'),
          _metricValue(row, 'mcts.sourcePlanCommands'),
          _metricValue(row, 'mcts.rawCandidates'),
          _metricValue(row, 'mcts.selectedCandidates'),
          row.debugNotes.join('; '),
        ].map(_csv).join(','),
      );
    }
    return lines.join('\n');
  }

  Object _metricValue(EconomySimulationAiTurnRuntime row, String key) {
    return row.debugMetrics[key] ?? '';
  }

  Object _metricMicrosAsMs(EconomySimulationAiTurnRuntime row, String key) {
    final value = row.debugMetrics[key];
    if (value is! num) return '';
    return (value / 1000.0).toStringAsFixed(3);
  }

  String _csv(Object? value) {
    final text = '$value';
    if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}

const _usage = '''
Usage:
  dart run tool/balance_pass.dart [options]

Options:
  --games=N          Number of games to run. Default: 10
  --minutes=N        Timed preset: 60, 90, or 120 minutes.
                     Default: 60, estimated as 120 turns at 30s/turn
  --turns=N          Raw turn override for short smoke runs.
                     Cannot be combined with --minutes
  --difficulty=NAME  easy, normal, hard, or veryHard. Default: normal
  --mcts-profile=NAME
                     simulation, standard, interactive, battery-saver, or
                     adaptive-local-single-player. Default: simulation
  --seed=N           Base deterministic seed. Default: 4200
  --primary-civ=NAME Simulated-human civilization. Default: poland
  --civs=A,B,C       Three AI civilizations.
                     Default: germany,netherlands,japan
  --out=PATH         Output directory or .json file path.
                     Default: ../../build/reports/ai-balance
''';
