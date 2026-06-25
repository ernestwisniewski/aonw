import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/analysis/human_trace_analyzer.dart';
import 'package:aonw/game/application/ports/logged_command.dart';

void main(List<String> args) async {
  if (_hasFlag(args, '--help') || _hasFlag(args, '-h')) {
    stdout.writeln(_usage);
    return;
  }

  try {
    final options = _Options.fromArgs(args);
    final eventLog = _eventLogFile(options.inputPath);
    final log = await _readLog(eventLog);
    final report = const HumanTraceAnalyzer().analyze(
      log: log,
      humanPlayerId: options.humanPlayerId,
    );
    final metadata = await _readSnapshotMetadata(eventLog.parent);
    final source = _displayPath(eventLog.path);
    final jsonReport = {'source': source, 'save': metadata, ...report.toJson()};
    final markdown = _markdownReport(
      report: report,
      source: source,
      metadata: metadata,
    );

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
      await file.writeAsString(markdown);
      stdout.writeln('Wrote ${file.path}');
    }
    if (options.jsonOut == null && options.markdownOut == null) {
      stdout.write(markdown);
    }
  } on _UsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln()
      ..writeln(_usage);
    exitCode = 64;
  }
}

Future<List<LoggedCommand>> _readLog(File file) async {
  if (!await file.exists()) {
    throw _UsageException('Event log not found: ${file.path}');
  }
  final commands = <LoggedCommand>[];
  final lines = file
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    if (line.trim().isEmpty) continue;
    commands.add(
      LoggedCommand.fromJson(jsonDecode(line) as Map<String, dynamic>),
    );
  }
  return commands;
}

File _eventLogFile(String inputPath) {
  final entityType = FileSystemEntity.typeSync(inputPath);
  if (entityType == FileSystemEntityType.directory) {
    return File('$inputPath/events.log');
  }
  return File(inputPath);
}

Future<Map<String, Object?>> _readSnapshotMetadata(Directory saveDir) async {
  final file = File('${saveDir.path}/snapshot.json');
  if (!await file.exists()) return const {};
  final root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final state = root['state'] as Map<String, dynamic>?;
  final save = state?['save'] as Map<String, dynamic>?;
  if (save == null) return const {};
  return {
    'id': save['id'],
    'name': save['name'],
    'mapName': save['mapName'],
    'turn': save['turn'],
    'gameMode': save['gameMode'],
    'players': save['players'],
    'ruleset': save['ruleset'],
  };
}

String _markdownReport({
  required HumanTraceReport report,
  required String source,
  required Map<String, Object?> metadata,
}) {
  final buffer = StringBuffer()
    ..writeln('# Human Trace Analysis')
    ..writeln()
    ..writeln('- Source: `$source`')
    ..writeln('- Human player: `${report.humanPlayerId}`')
    ..writeln('- Save: `${metadata['name'] ?? 'unknown'}`')
    ..writeln('- Last completed turn: ${report.lastCompletedTurn}')
    ..writeln('- Logged offsets: ${report.offsetCount}')
    ..writeln('- Elapsed real time: ${_duration(report.elapsedSeconds)}')
    ..writeln()
    ..writeln('## Human Benchmarks')
    ..writeln()
    ..writeln('- Cities founded: ${report.humanFoundCities.length}')
    ..writeln('- Research choices: ${report.humanResearch.length}')
    ..writeln('- Production choices: ${report.humanProduction.length}')
    ..writeln(
      '- Worker improvements selected: '
      '${report.humanWorkerImprovements.length}',
    )
    ..writeln('- Attack commands: ${report.humanAttacks.length}')
    ..writeln()
    ..writeln('### City Timeline')
    ..writeln()
    ..writeln('| # | Turn | Founder | Controlled hexes |')
    ..writeln('|---:|---:|---|---|');
  for (var i = 0; i < report.humanFoundCities.length; i++) {
    final city = report.humanFoundCities[i];
    buffer.writeln(
      '| ${i + 1} | ${city.turn} | `${city.founderId}` | '
      '${city.controlledHexes.map((hex) => '(${hex.col},${hex.row})').join(', ')} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### Research Path')
    ..writeln()
    ..writeln(
      _inlineTimeline([
        for (final choice in report.humanResearch)
          'T${choice.turn} `${choice.technologyId}`',
      ]),
    )
    ..writeln()
    ..writeln('### Production Path')
    ..writeln()
    ..writeln('| Turn | Kind | Target | City |')
    ..writeln('|---:|---|---|---|');
  for (final choice in report.humanProduction) {
    buffer.writeln(
      '| ${choice.turn} | ${choice.kind} | `${choice.target}` | `${choice.cityId}` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## AI Problem Signals')
    ..writeln()
    ..writeln('### AI Summaries')
    ..writeln()
    ..writeln('| Player | Cities founded turns | Top commands |')
    ..writeln('|---|---|---|');
  for (final summary in report.aiSummaries) {
    buffer.writeln(
      '| `${summary.playerId}` | '
      '${summary.cityFoundingTurns.map((turn) => 'T$turn').join(', ')} | '
      '${_topCounts(summary.commandCounts, limit: 5)} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### Repeated AI Commands')
    ..writeln()
    ..writeln('| Player | Command | Count | Turns | Payload |')
    ..writeln('|---|---|---:|---|---|');
  for (final repeated in report.repeatedAiCommands.take(12)) {
    buffer.writeln(
      '| `${repeated.playerId}` | `${repeated.commandType}` | '
      '${repeated.count} | T${repeated.firstTurn}-T${repeated.lastTurn} | '
      '` ${jsonEncode(repeated.command)} ` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### AI Worker Stalls')
    ..writeln()
    ..writeln('| Player | Unit | Improvement | Selects | Completions | Turns |')
    ..writeln('|---|---|---|---:|---:|---|');
  for (final stall in report.aiWorkerStalls.take(12)) {
    buffer.writeln(
      '| `${stall.playerId}` | `${stall.unitId}` | '
      '`${stall.improvementType}` | ${stall.selectionCount} | '
      '${stall.completionCount} | T${stall.firstTurn}-T${stall.lastTurn} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Extracted Goals')
    ..writeln()
    ..writeln(
      '- Benchmark AI second-city timing against the human T33 second city.',
    )
    ..writeln(
      '- Treat repeated same-target settler `MoveUnit` commands as a regression signal.',
    )
    ..writeln(
      '- Treat repeated worker improvement selections without completion as a regression signal.',
    )
    ..writeln(
      '- Add combat response checks after sustained human attacks from T81 onward.',
    );

  return buffer.toString();
}

String _inlineTimeline(List<String> values) {
  if (values.isEmpty) return '_none_';
  return values.join(' -> ');
}

String _topCounts(Map<String, int> counts, {required int limit}) {
  if (counts.isEmpty) return '_none_';
  return counts.entries
      .take(limit)
      .map((entry) => '`${entry.key}` ${entry.value}')
      .join(', ');
}

String _duration(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes <= 0) return '${seconds}s';
  return '${minutes}m ${rest}s';
}

String _displayPath(String path) {
  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty && path.startsWith(home)) {
    return '~${path.substring(home.length)}';
  }
  return path;
}

bool _hasFlag(List<String> args, String flag) => args.contains(flag);

class _Options {
  const _Options({
    required this.inputPath,
    required this.humanPlayerId,
    required this.jsonOut,
    required this.markdownOut,
  });

  final String inputPath;
  final String humanPlayerId;
  final String? jsonOut;
  final String? markdownOut;

  factory _Options.fromArgs(List<String> args) {
    final inputPath =
        _readOption(args, '--save-dir') ??
        _readOption(args, '--events') ??
        (args.isNotEmpty && !args.first.startsWith('--') ? args.first : null);
    if (inputPath == null || inputPath.isEmpty) {
      throw const _UsageException('Pass a save directory or events.log path.');
    }
    return _Options(
      inputPath: inputPath,
      humanPlayerId: _readOption(args, '--human-player') ?? 'player_1',
      jsonOut: _readOption(args, '--json-out'),
      markdownOut: _readOption(args, '--markdown-out'),
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
  dart run tool/analyze_human_trace.dart --save-dir <save-dir> [options]
  dart run tool/analyze_human_trace.dart --events <events.log> [options]

Options:
  --human-player <id>  Human player id, default: player_1
  --json-out <path>   Write machine-readable report
  --markdown-out <path>
                       Write markdown report
''';
