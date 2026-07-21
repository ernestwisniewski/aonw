part of '../timeout_actor_integration_test.dart';

List<String> _decodedSnapshotAliasViolations(CompilationUnit unit) {
  final aliases = unit.declarations.whereType<GenericTypeAlias>().where(
    (declaration) => declaration.name.lexeme == 'DecodedMatchSnapshot',
  );
  return [
    if (aliases.length != 1 ||
        aliases.single.toSource() !=
            'typedef DecodedMatchSnapshot = DecodedRunningMatchSnapshot;')
      'DecodedMatchSnapshot must be exactly a typedef to '
          'DecodedRunningMatchSnapshot',
    if (unit.declarations.any(_isDecodedMatchSnapshotWrapper))
      'DecodedMatchSnapshot must not declare a concrete wrapper',
  ];
}

List<String> _reducerSnapshotDecodeViolations(CompilationUnit unit) => [
  ..._decodeSnapshotDelegationViolations(unit),
  ..._normalReducerDecodeViolations(unit),
];

List<String> _decodeSnapshotDelegationViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, 'decodeSnapshot');
  if (method == null) {
    return const ['must declare exactly one decodeSnapshot'];
  }
  final body = method.body;
  final expression = body is ExpressionFunctionBody ? body.expression : null;
  final calls = _methodInvocations(method.body, 'decode')
      .where((call) => call.target?.toSource() == '_runningMatchSnapshotCodec')
      .toList();
  return [
    if (method.returnType?.toSource() != 'DecodedMatchSnapshot' ||
        !_hasExactRequiredNamedParameters(method, const {
          'match': 'WireMatch',
          'snapshot': 'WireSnapshot',
        }) ||
        expression?.toSource() !=
            '_runningMatchSnapshotCodec.decode('
                'match: match, snapshot: snapshot)' ||
        calls.length != 1)
      'decodeSnapshot must require match/snapshot and delegate directly '
          'to RunningMatchSnapshotCodec',
  ];
}

List<String> _normalReducerDecodeViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, 'reduce');
  if (method == null) return const ['must declare exactly one reduce'];
  final decodedInitializer = _singleVariableInitializer(
    method.body,
    'decodedSnapshot',
  );
  final decodes = _methodInvocations(method.body, 'decodeSnapshot');
  final decode = decodes.length == 1 ? decodes.single : null;
  final runningGuards = _ifStatements(method.body)
      .where(
        (statement) =>
            statement.expression.toSource() == "match.state != 'running'" &&
            _isImmediateReturnGuard(statement),
      )
      .toList();
  return [
    if (decodedInitializer?.toSource() !=
            'decodeSnapshot(match: match, snapshot: snapshot)' ||
        decode == null ||
        _namedArgumentSource(decode.argumentList, 'match') != 'match' ||
        _namedArgumentSource(decode.argumentList, 'snapshot') != 'snapshot' ||
        decode.argumentList.arguments.length != 2)
      'reduce must decode its match and snapshot once',
    if (decode == null ||
        runningGuards.length != 1 ||
        runningGuards.single.offset > decode.offset)
      'reduce must reject non-running matches before decode',
  ];
}

List<String> _timeoutReducerForwardingViolations({
  required CompilationUnit reducer,
  required CompilationUnit turns,
}) => [
  ..._timeoutReducerEntryViolations(reducer),
  ..._normalSubmitForwardingViolations(turns),
  ..._turnFinalizerFallbackViolations(turns),
];

List<String> _timeoutReducerEntryViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, 'reduceTimedOutTurn');
  if (method == null) return const ['must declare reduceTimedOutTurn'];
  final calls = _methodInvocations(method.body, '_finalizeSimultaneousTurn');
  return [
    if (!_hasRequiredNamedParameter(
          method,
          'decodedSnapshot',
          'DecodedMatchSnapshot',
        ) ||
        _hasParameterNamed(method, 'timeoutSnapshot'))
      'reduceTimedOutTurn must require only the decoded snapshot',
    if (calls.length != 1 ||
        _namedArgumentSource(calls.single.argumentList, 'decodedSnapshot') !=
            'decodedSnapshot')
      'reduceTimedOutTurn must forward decodedSnapshot once',
  ];
}

List<String> _normalSubmitForwardingViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_submitTurn');
  if (method == null) return const ['must declare _submitTurn'];
  final calls = _methodInvocations(method.body, '_finalizeSimultaneousTurn');
  return [
    if (calls.length != 1 ||
        _namedArgumentSource(calls.single.argumentList, 'decodedSnapshot') !=
            'decodedSnapshot.withState(submittedState)')
      '_submitTurn must finalize a fresh submitted snapshot',
  ];
}

List<String> _turnFinalizerFallbackViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_finalizeSimultaneousTurn');
  if (method == null) return const ['must declare _finalizeSimultaneousTurn'];
  final requests = _methodInvocations(method.body, 'simultaneousFinalize')
      .where(
        (call) => call.target?.toSource() == 'CanonicalTurnPipelineRequest',
      )
      .toList();
  final snapshot = requests.length == 1
      ? _namedArgumentSource(requests.single.argumentList, 'snapshot')
      : null;
  return [
    if (!_hasRequiredNamedParameter(
          method,
          'decodedSnapshot',
          'DecodedMatchSnapshot',
        ) ||
        _hasParameterNamed(method, 'precomputedSnapshot'))
      '_finalizeSimultaneousTurn must require only decodedSnapshot',
    if (snapshot != 'decodedSnapshot.canonical' ||
        _targetMemberReferences(
              method.body,
              target: 'decodedSnapshot',
              member: 'canonical',
            ).length !=
            1 ||
        (_IdentifierCollector()..collect(method.body)).names.contains(
          'toCanonical',
        ) ||
        _methodInvocations(method.body, '_canonicalSnapshot').isNotEmpty)
      '_finalizeSimultaneousTurn must read decodedSnapshot.canonical once',
  ];
}

bool _isDecodedMatchSnapshotWrapper(CompilationUnitMember declaration) {
  return switch (declaration) {
    ClassDeclaration() =>
      declaration.namePart.typeName.lexeme == 'DecodedMatchSnapshot',
    EnumDeclaration() =>
      declaration.namePart.typeName.lexeme == 'DecodedMatchSnapshot',
    ExtensionTypeDeclaration() =>
      declaration.primaryConstructor.typeName.lexeme == 'DecodedMatchSnapshot',
    MixinDeclaration() => declaration.name.lexeme == 'DecodedMatchSnapshot',
    _ => false,
  };
}
