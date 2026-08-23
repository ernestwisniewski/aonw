import 'dart:convert';
import 'dart:io';

const _maximumReportedDifferences = 50;

void main(List<String> arguments) {
  if (arguments.length != 3 && arguments.length != 5) {
    stderr.writeln(
      'usage: dart run tool/compare_map_render_probes.dart '
      '<flutter.json> <godot.json> <scenario.json> '
      '[<flutter-diagnostics.json> <godot-diagnostics.json>]',
    );
    exitCode = 64;
    return;
  }

  final flutter = _readJson(File(arguments[0]));
  final godot = _readJson(File(arguments[1]));
  final scenario = _object(_readJson(File(arguments[2])), r'$');
  final tolerance = _double(scenario['floatTolerance'], r'$.floatTolerance');
  final differences = <String>[];
  _compare(flutter, godot, r'$', tolerance, differences);
  _validateExpectedSelections('Flutter', flutter, scenario, differences);
  _validateExpectedSelections('Godot', godot, scenario, differences);

  if (arguments.length == 5) {
    _printDiagnostics(
      scenario,
      _readJson(File(arguments[3])),
      _readJson(File(arguments[4])),
    );
  }

  if (differences.isNotEmpty) {
    stderr.writeln(
      'MapRenderProbe mismatch: ${differences.length} semantic '
      '${differences.length == 1 ? 'difference' : 'differences'}.',
    );
    for (final difference in differences.take(_maximumReportedDifferences)) {
      stderr.writeln('  $difference');
    }
    if (differences.length > _maximumReportedDifferences) {
      stderr.writeln(
        '  ... ${differences.length - _maximumReportedDifferences} more',
      );
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('MapRenderProbe parity: OK (float tolerance $tolerance)');
}

void _validateExpectedSelections(
  String client,
  Object? probeValue,
  Map<String, dynamic> scenario,
  List<String> differences,
) {
  final probe = _object(probeValue, '$client probe');
  final maps = _list(probe['maps'], '$client.maps');
  final expectedCases = _list(scenario['cases'], r'$.cases');
  for (var mapIndex = 0; mapIndex < maps.length; mapIndex++) {
    final map = _object(maps[mapIndex], '$client.maps[$mapIndex]');
    final cases = _list(map['cases'], '$client.maps[$mapIndex].cases');
    if (cases.length != expectedCases.length) {
      differences.add(
        '$client.maps[$mapIndex].cases.length: '
        'actual=${cases.length}, expected=${expectedCases.length}',
      );
      continue;
    }
    for (var caseIndex = 0; caseIndex < cases.length; caseIndex++) {
      final actual = _object(
        cases[caseIndex],
        '$client.maps[$mapIndex].cases[$caseIndex]',
      );
      final expected = _object(expectedCases[caseIndex], r'$.cases[]');
      final expectedHex = expected['expectedHex'];
      final path = '$client.maps[$mapIndex].cases[$caseIndex]';
      _compare(
        expectedHex,
        actual['selectedHex'],
        '$path.selectedHex(expected)',
        0,
        differences,
      );
      final viewports = _list(actual['viewports'], '$path.viewports');
      for (
        var viewportIndex = 0;
        viewportIndex < viewports.length;
        viewportIndex++
      ) {
        final viewport = _object(
          viewports[viewportIndex],
          '$path.viewports[$viewportIndex]',
        );
        _compare(
          expectedHex,
          viewport['selectedHex'],
          '$path.viewports[$viewportIndex].selectedHex(expected)',
          0,
          differences,
        );
      }
    }
  }
}

void _compare(
  Object? flutter,
  Object? godot,
  String path,
  double tolerance,
  List<String> differences,
) {
  if (flutter is Map<String, dynamic> && godot is Map<String, dynamic>) {
    _compareObjects(flutter, godot, path, tolerance, differences);
    return;
  }

  if (flutter is List<dynamic> && godot is List<dynamic>) {
    _compareLists(flutter, godot, path, tolerance, differences);
    return;
  }

  if (flutter is int && godot is int) {
    _compareIntegers(flutter, godot, path, differences);
    return;
  }

  if (flutter is double && godot is double) {
    _compareFloats(flutter, godot, path, tolerance, differences);
    return;
  }

  if (flutter is num || godot is num) {
    _reportNumericTypeMismatch(flutter, godot, path, differences);
    return;
  }

  _compareScalars(flutter, godot, path, differences);
}

void _compareObjects(
  Map<String, dynamic> flutter,
  Map<String, dynamic> godot,
  String path,
  double tolerance,
  List<String> differences,
) {
  final keys = {...flutter.keys, ...godot.keys}.toList()..sort();
  for (final key in keys) {
    final childPath = '$path.${_pathSegment(key)}';
    if (!flutter.containsKey(key)) {
      differences.add('$childPath: missing from Flutter');
    } else if (!godot.containsKey(key)) {
      differences.add('$childPath: missing from Godot');
    } else {
      _compare(flutter[key], godot[key], childPath, tolerance, differences);
    }
  }
}

void _compareLists(
  List<dynamic> flutter,
  List<dynamic> godot,
  String path,
  double tolerance,
  List<String> differences,
) {
  if (flutter.length != godot.length) {
    differences.add(
      '$path.length: Flutter=${flutter.length}, Godot=${godot.length}',
    );
  }
  final sharedLength = flutter.length < godot.length
      ? flutter.length
      : godot.length;
  for (var index = 0; index < sharedLength; index++) {
    _compare(
      flutter[index],
      godot[index],
      '$path[$index]',
      tolerance,
      differences,
    );
  }
}

void _compareIntegers(
  int flutter,
  int godot,
  String path,
  List<String> differences,
) {
  if (flutter != godot) {
    differences.add('$path: Flutter=$flutter, Godot=$godot');
  }
}

void _compareFloats(
  double flutter,
  double godot,
  String path,
  double tolerance,
  List<String> differences,
) {
  final delta = (flutter - godot).abs();
  if (!flutter.isFinite || !godot.isFinite || delta > tolerance) {
    differences.add(
      '$path: Flutter=$flutter, Godot=$godot '
      '(delta=$delta, tolerance=$tolerance)',
    );
  }
}

void _reportNumericTypeMismatch(
  Object? flutter,
  Object? godot,
  String path,
  List<String> differences,
) {
  differences.add(
    '$path: numeric type mismatch '
    '(Flutter=${flutter.runtimeType} $flutter, '
    'Godot=${godot.runtimeType} $godot)',
  );
}

void _compareScalars(
  Object? flutter,
  Object? godot,
  String path,
  List<String> differences,
) {
  if (flutter.runtimeType == godot.runtimeType && flutter == godot) {
    return;
  }
  differences.add(
    '$path: Flutter=${jsonEncode(flutter)}, Godot=${jsonEncode(godot)}',
  );
}

void _printDiagnostics(
  Map<String, dynamic> scenario,
  Object? flutterValue,
  Object? godotValue,
) {
  final budget = _object(
    scenario['largeMapDiagnosticBudget'],
    r'$.largeMapDiagnosticBudget',
  );
  final mapId = _string(budget['mapId'], r'$.largeMapDiagnosticBudget.mapId');
  final durationBudget = _integer(
    budget['maxDurationMicros'],
    r'$.largeMapDiagnosticBudget.maxDurationMicros',
  );
  final memoryBudget = _integer(
    budget['maxResidentMemoryDeltaBytes'],
    r'$.largeMapDiagnosticBudget.maxResidentMemoryDeltaBytes',
  );
  for (final entry in <(String, Object?)>[
    ('Flutter', flutterValue),
    ('Godot', godotValue),
  ]) {
    final diagnostics = _object(entry.$2, '${entry.$1} diagnostics');
    final maps = _list(diagnostics['maps'], '${entry.$1} diagnostics.maps');
    final map = maps
        .map((value) => _object(value, '${entry.$1} diagnostics.maps[]'))
        .where((value) => value['mapId'] == mapId)
        .single;
    final duration = _integer(
      map['elapsedMicros'],
      '${entry.$1} diagnostics.elapsedMicros',
    );
    final memory = _integer(
      map['residentMemoryDeltaBytes'],
      '${entry.$1} diagnostics.residentMemoryDeltaBytes',
    );
    final bytes = _integer(
      map['serializedProbeBytes'],
      '${entry.$1} diagnostics.serializedProbeBytes',
    );
    stdout.writeln(
      'MapRenderProbe diagnostic ${entry.$1}/$mapId: '
      '${_milliseconds(duration)} ms '
      '(${_budgetStatus(duration, durationBudget)}), '
      '${_mebibytes(memory)} MiB resident delta '
      '(${_budgetStatus(memory, memoryBudget)}), '
      '${_mebibytes(bytes)} MiB JSON.',
    );
  }
}

Object? _readJson(File file) {
  try {
    return jsonDecode(file.readAsStringSync());
  } on FileSystemException catch (error) {
    throw FormatException('Cannot read ${file.path}: ${error.message}');
  } on FormatException catch (error) {
    throw FormatException('Invalid JSON in ${file.path}: ${error.message}');
  }
}

Map<String, dynamic> _object(Object? value, String path) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$path must be an object.');
  }
  return value;
}

List<dynamic> _list(Object? value, String path) {
  if (value is! List<dynamic>) {
    throw FormatException('$path must be an array.');
  }
  return value;
}

String _string(Object? value, String path) {
  if (value is! String) throw FormatException('$path must be a string.');
  return value;
}

int _integer(Object? value, String path) {
  if (value is! int) throw FormatException('$path must be an integer.');
  return value;
}

double _double(Object? value, String path) {
  if (value is! double || !value.isFinite || value <= 0) {
    throw FormatException('$path must be a positive finite float.');
  }
  return value;
}

String _pathSegment(String value) =>
    RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value)
    ? value
    : '[${jsonEncode(value)}]';

String _budgetStatus(int actual, int budget) => actual <= budget
    ? 'within diagnostic budget $budget'
    : 'OVER diagnostic budget $budget';

String _milliseconds(int micros) => (micros / 1000).toStringAsFixed(3);

String _mebibytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(3);
