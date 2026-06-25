part of '../run_save_ai_benchmark.dart';

bool _hasFlag(List<String> args, String flag) => args.contains(flag);

String? _readOption(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

T _enumByName<T extends Enum>(String name, List<T> values, String label) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw _UsageException('Unknown $label: $name');
}

class _UsageException implements Exception {
  const _UsageException(this.message);
  final String message;
}

const _usage = '''
Usage:
  dart run tool/run_save_ai_benchmark.dart [options]

Options:
  --save <path>          snapshot.json path; default: latest save >= --min-turn
  --saves-root <path>    Directory containing save folders
  --min-turn <n>         Minimum turn for auto-discovery, default: 100
  --map <path>           Map JSON path, default: assets/maps/<save map>/map.json
  --profiles <list>      Comma-separated: auto,batterySaver,interactive,standard
                         default: auto
  --strategy <id>        Override saved AI strategy: basic,mcts,random
  --repeats <n>          Planning repeats per AI/profile, default: 1
  --multi-turns <n>      Replay n full AI cycles with human auto-submitted
  --json-out <path>      Write machine-readable report
  --markdown-out <path>  Write markdown report
  --include-deadline     Emulate multiplayer 115s turn deadline from save time
  --fail-on-finding      Exit 1 when fail-level findings are reported
''';
