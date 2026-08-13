import 'package:aonw_core/domain.dart';

final class ReducerParityExpectedResult {
  const ReducerParityExpectedResult({
    required this.accepted,
    required this.reason,
    required this.save,
    required this.state,
    required this.events,
    required this.movementExecutions,
  });

  final bool accepted;
  final String? reason;
  final Map<String, dynamic> save;
  final Map<String, dynamic> state;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>>? movementExecutions;
}

ReducerParityExpectedResult readReducerParityExpected(
  Object? value,
  String id,
  int fixtureVersion,
) {
  final expected = _asMap(value, '$id.expected');
  _requireExactKeys(expected, {
    'accepted',
    'reason',
    'save',
    'state',
    'events',
    if (fixtureVersion == 2) 'movementExecutions',
  }, '$id.expected');
  final accepted = _asBool(expected['accepted'], '$id.accepted');
  final reason = _asNullableString(expected['reason'], '$id.reason');
  if (accepted == (reason != null)) {
    throw FormatException(
      '$id must have a null reason exactly when it is accepted.',
    );
  }
  return ReducerParityExpectedResult(
    accepted: accepted,
    reason: reason,
    save: _asMap(expected['save'], '$id.expected.save'),
    state: _asMap(expected['state'], '$id.expected.state'),
    events: _asMapList(expected['events'], '$id.expected.events'),
    movementExecutions: fixtureVersion == 2
        ? _readMovementExecutions(
            expected['movementExecutions'],
            '$id.expected.movementExecutions',
          )
        : null,
  );
}

List<Map<String, dynamic>> reducerParityMovementExecutions(
  Iterable<MovementCommandExecution> executions,
) {
  return [
    for (final execution in executions)
      {
        'unitId': execution.unitId,
        'fromCol': execution.fromCol,
        'fromRow': execution.fromRow,
        'steps': [
          for (final step in execution.steps)
            {
              'col': step.col,
              'row': step.row,
              'enterCost': step.enterCost,
              'cumulativeCost': step.cumulativeCost,
            },
        ],
      },
  ];
}

List<Map<String, dynamic>> _readMovementExecutions(
  Object? value,
  String field,
) {
  final executions = _asMapList(value, field);
  for (
    var executionIndex = 0;
    executionIndex < executions.length;
    executionIndex++
  ) {
    final execution = executions[executionIndex];
    final executionField = '$field[$executionIndex]';
    _requireExactKeys(execution, const {
      'unitId',
      'fromCol',
      'fromRow',
      'steps',
    }, executionField);
    _asNonEmptyString(execution['unitId'], '$executionField.unitId');
    _asInt(execution['fromCol'], '$executionField.fromCol');
    _asInt(execution['fromRow'], '$executionField.fromRow');
    final steps = _asMapList(execution['steps'], '$executionField.steps');
    if (steps.isEmpty) {
      throw FormatException('$executionField.steps must not be empty.');
    }
    var cumulativeCost = 0;
    for (var stepIndex = 0; stepIndex < steps.length; stepIndex++) {
      final step = steps[stepIndex];
      final stepField = '$executionField.steps[$stepIndex]';
      _requireExactKeys(step, const {
        'col',
        'row',
        'enterCost',
        'cumulativeCost',
      }, stepField);
      _asInt(step['col'], '$stepField.col');
      _asInt(step['row'], '$stepField.row');
      final enterCost = _asInt(step['enterCost'], '$stepField.enterCost');
      if (enterCost <= 0) {
        throw FormatException('$stepField.enterCost must be positive.');
      }
      cumulativeCost += enterCost;
      if (_asInt(step['cumulativeCost'], '$stepField.cumulativeCost') !=
          cumulativeCost) {
        throw FormatException(
          '$stepField.cumulativeCost must equal the checked running sum.',
        );
      }
    }
  }
  return executions;
}

Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is Map<Object?, Object?>) return Map<String, dynamic>.from(value);
  throw FormatException('$field must be a JSON object.');
}

List<Map<String, dynamic>> _asMapList(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('$field must be a JSON array.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      _asMap(value[index], '$field[$index]'),
  ];
}

String _asNonEmptyString(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('$field must be a non-empty string.');
}

String? _asNullableString(Object? value, String field) {
  if (value == null) return null;
  return _asNonEmptyString(value, field);
}

int _asInt(Object? value, String field) {
  if (value is int) return value;
  throw FormatException('$field must be an integer.');
}

bool _asBool(Object? value, String field) {
  if (value is bool) return value;
  throw FormatException('$field must be a boolean.');
}

void _requireExactKeys(
  Map<String, dynamic> value,
  Set<String> expected,
  String field,
) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException('$field has unexpected or missing fields.');
  }
}
