part of '../timeout_actor_integration_test.dart';

List<String> _timeoutCanonicalFlowViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, 'advanceTimedOutTurn');
  if (method == null) return const ['must declare advanceTimedOutTurn'];
  return [
    ..._timeoutDecodeViolations(method),
    ..._timeoutLifecycleViolations(method),
    ..._timeoutCanonicalReadViolations(method),
    ..._timeoutForbiddenConversionViolations(method),
    ..._timeoutCheckForwardingViolations(method),
    ..._timeoutSelectionForwardingViolations(method),
    ..._timeoutReductionForwardingViolations(method),
  ];
}

List<String> _timeoutDecodeViolations(MethodDeclaration method) {
  final decodedVariable = _singleVariable(method.body, 'decodedSnapshot');
  final decode = _singleCommandReducerDecode(method);
  return [
    if (!_isExpectedDecodedDeclaration(decodedVariable) ||
        !_isExpectedTimeoutDecode(decode))
      'advanceTimedOutTurn must decode state.match/state.snapshot once',
  ];
}

List<String> _timeoutLifecycleViolations(MethodDeclaration method) {
  final decode = _singleCommandReducerDecode(method);
  final runningGuards = _ifStatements(method.body)
      .where(
        (statement) =>
            statement.expression.toSource() ==
                "state.match.state != 'running'" &&
            _isImmediateReturnGuard(statement),
      )
      .toList();
  return [
    if (decode == null ||
        runningGuards.length != 1 ||
        runningGuards.single.offset > decode.offset)
      'advanceTimedOutTurn must reject non-running matches before decode',
  ];
}

List<String> _timeoutCanonicalReadViolations(MethodDeclaration method) {
  final canonicalVariable = _singleVariable(method.body, 'canonicalSnapshot');
  final references = _targetMemberReferences(
    method.body,
    target: 'decodedSnapshot',
    member: 'canonical',
  );
  return [
    if (!_isExpectedCanonicalDeclaration(canonicalVariable) ||
        references.length != 1)
      'canonicalSnapshot must be a final local reading '
          'decodedSnapshot.canonical once',
  ];
}

List<String> _timeoutForbiddenConversionViolations(MethodDeclaration method) {
  final identifiers = _IdentifierCollector()..collect(method.body);
  return [
    if (identifiers.names.contains('toCanonical'))
      'timeout canonical flow must not call toCanonical',
    if (identifiers.names.contains('LegacyGameSnapshotAdapter'))
      'timeout service must not use LegacyGameSnapshotAdapter directly',
  ];
}

List<String> _timeoutCheckForwardingViolations(MethodDeclaration method) {
  final calls = _methodInvocations(method.body, 'hasTurnTimedOut');
  return [
    if (calls.length != 1 ||
        _namedArgumentSource(calls.single.argumentList, 'decodedSnapshot') !=
            'decodedSnapshot')
      'hasTurnTimedOut must receive decodedSnapshot',
  ];
}

List<String> _timeoutSelectionForwardingViolations(MethodDeclaration method) {
  final calls = _methodInvocations(method.body, '_selectTimeoutActorPlayerId');
  return [
    if (calls.length != 1 ||
        _namedArgumentSource(calls.single.argumentList, 'canonicalSnapshot') !=
            'canonicalSnapshot')
      '_selectTimeoutActorPlayerId must receive canonicalSnapshot',
  ];
}

List<String> _timeoutReductionForwardingViolations(MethodDeclaration method) {
  final calls = _methodInvocations(method.body, 'reduceTimedOutTurn');
  return [
    if (calls.length != 1 ||
        _namedArgumentSource(calls.single.argumentList, 'decodedSnapshot') !=
            'decodedSnapshot' ||
        _namedArguments(
          calls.single.argumentList,
          'timeoutSnapshot',
        ).isNotEmpty)
      'reduceTimedOutTurn must receive only decodedSnapshot',
  ];
}

MethodInvocation? _singleCommandReducerDecode(MethodDeclaration method) {
  final calls = _methodInvocations(method.body, 'decodeSnapshot');
  if (calls.length != 1) return null;
  return calls.single.target?.toSource() == '_commandReducer'
      ? calls.single
      : null;
}

bool _isExpectedDecodedDeclaration(VariableDeclaration? variable) {
  final declaration = variable?.parent;
  return declaration is VariableDeclarationList &&
      declaration.parent is VariableDeclarationStatement &&
      declaration.isFinal &&
      declaration.type?.toSource() == 'DecodedMatchSnapshot' &&
      variable?.initializer?.toSource() ==
          '_commandReducer.decodeSnapshot('
              'match: state.match, snapshot: state.snapshot)';
}

bool _isExpectedTimeoutDecode(MethodInvocation? decode) {
  if (decode == null) return false;
  return decode.argumentList.arguments.length == 2 &&
      _namedArgumentSource(decode.argumentList, 'match') == 'state.match' &&
      _namedArgumentSource(decode.argumentList, 'snapshot') == 'state.snapshot';
}

bool _isExpectedCanonicalDeclaration(VariableDeclaration? variable) {
  final declaration = variable?.parent;
  return declaration is VariableDeclarationList &&
      declaration.parent is VariableDeclarationStatement &&
      declaration.isFinal &&
      variable?.initializer?.toSource() == 'decodedSnapshot.canonical';
}
