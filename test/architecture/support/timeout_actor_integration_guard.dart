part of '../timeout_actor_integration_test.dart';

List<String> _timeoutSelectionViolations(CompilationUnit unit) => [
  ..._timeoutSelectionShapeViolations(unit),
  ..._timeoutSelectionSourceViolations(unit),
  ..._timeoutSelectionCallViolations(unit),
  ..._timeoutSelectionForbiddenViolations(unit),
];

List<String> _timeoutSelectionShapeViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) {
    return const ['must declare exactly one _selectTimeoutActorPlayerId'];
  }
  return [
    if (method.returnType?.toSource() != 'String?' ||
        !_hasExactRequiredNamedParameters(method, const {
          'match': 'WireMatch',
          'save': 'GameSave',
          'canonicalSnapshot': 'CanonicalGameSnapshot',
        }))
      '_selectTimeoutActorPlayerId must require match/save/canonicalSnapshot',
    if (_singleMethod(unit, '_timeoutActorPlayerId') != null)
      'legacy _timeoutActorPlayerId must be removed',
  ];
}

List<String> _timeoutSelectionSourceViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const [];
  final active = _singleVariableInitializer(method.body, 'activePlayerIds');
  const expected =
      '{for (final player in save.players) '
      'if (player.id.isNotEmpty) player.id, '
      'for (final playerId in '
      'canonicalSnapshot.session.turnStatesByPlayerId.keys) '
      'if (playerId.isNotEmpty) playerId}';
  return [
    if (active?.toSource() != expected)
      'timeout active IDs must use save players and canonical turn states',
  ];
}

List<String> _timeoutSelectionCallViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const [];
  final calls = _methodInvocations(
    method.body,
    'select',
  ).where((call) => call.target?.toSource() == 'TimeoutActorSelector').toList();
  if (calls.length != 1) {
    return const [
      'timeout selection must call TimeoutActorSelector.select once',
    ];
  }
  final arguments = calls.single.argumentList;
  final returns = _ReturnCollector()..collect(method.body);
  const ordered =
      '[for (final player in match.players) '
      'if (activePlayerIds.contains(player.id)) player.id]';
  return [
    if (_namedArgumentSource(arguments, 'orderedParticipantPlayerIds') !=
        ordered)
      'timeout selection must use the filtered Wire roster',
    if (_namedArgumentSource(arguments, 'submittedPlayerIds') !=
        'canonicalSnapshot.session.submittedPlayerIds')
      'timeout selection must read submitted from canonical session',
    if (_namedArgumentSource(arguments, 'kickedPlayerIds') !=
        'canonicalSnapshot.session.kickedPlayerIds')
      'timeout selection must read kicked from canonical session',
    if (returns.statements.length != 1 ||
        !identical(returns.statements.single.expression, calls.single))
      'timeout selector result must be returned directly',
  ];
}

List<String> _timeoutSelectionForbiddenViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const [];
  final identifiers = _IdentifierCollector()..collect(method.body);
  return [
    if (identifiers.names.contains('runtimeState'))
      'timeout selection must not read runtimeState',
    if (identifiers.names.contains('sort'))
      'timeout selection must preserve Wire order without sort()',
  ];
}

List<String> _timeoutCanonicalFlowViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, 'advanceTimedOutTurn');
  if (method == null) return const ['must declare advanceTimedOutTurn'];
  final conversions = _methodInvocations(method.body, 'toCanonical')
      .where(
        (call) =>
            call.target?.toSource() == 'decodedSnapshot' &&
            call.argumentList.arguments.isEmpty,
      )
      .toList();
  final canonicalInitializer = _singleVariableInitializer(
    method.body,
    'canonicalSnapshot',
  );
  final canonicalVariable = _singleVariable(method.body, 'canonicalSnapshot');
  final canonicalDeclaration = canonicalVariable?.parent;
  final selections = _methodInvocations(
    method.body,
    '_selectTimeoutActorPlayerId',
  );
  final reductions = _methodInvocations(method.body, 'reduceTimedOutTurn');
  final identifiers = _IdentifierCollector()..collect(method.body);
  return [
    if (conversions.length != 1 ||
        canonicalInitializer?.toSource() != 'decodedSnapshot.toCanonical()')
      'advanceTimedOutTurn must canonicalize decodedSnapshot once',
    if (canonicalDeclaration is! VariableDeclarationList ||
        !canonicalDeclaration.isFinal)
      'canonicalSnapshot must be a final local',
    if (selections.length != 1 ||
        _namedArgumentSource(
              selections.single.argumentList,
              'canonicalSnapshot',
            ) !=
            'canonicalSnapshot')
      '_selectTimeoutActorPlayerId must receive canonicalSnapshot',
    if (reductions.length != 1 ||
        _namedArgumentSource(
              reductions.single.argumentList,
              'decodedSnapshot',
            ) !=
            'decodedSnapshot' ||
        _namedArguments(
          reductions.single.argumentList,
          'timeoutSnapshot',
        ).isNotEmpty)
      'reduceTimedOutTurn must receive only decodedSnapshot',
    if (identifiers.names.contains('LegacyGameSnapshotAdapter'))
      'timeout service must not use LegacyGameSnapshotAdapter directly',
  ];
}

List<String> _decodedCanonicalBridgeViolations(CompilationUnit unit) => [
  ..._canonicalCacheViolations(unit),
  ..._toCanonicalMethodViolations(unit),
  ..._withStateCacheViolations(unit),
];

List<String> _canonicalCacheViolations(CompilationUnit unit) {
  final cache = _singleVariable(unit, '_canonicalSnapshotValue');
  final cacheDeclaration = cache?.parent;
  const expectedInitializer =
      '_canonicalSnapshot(save: save, state: state, '
      'eventLogOffset: eventLogOffset)';
  final cacheIsLateFinal =
      cacheDeclaration is VariableDeclarationList &&
      cacheDeclaration.parent is FieldDeclaration &&
      cacheDeclaration.isLate &&
      cacheDeclaration.isFinal &&
      cacheDeclaration.type?.toSource() == 'CanonicalGameSnapshot';
  return [
    if (!cacheIsLateFinal ||
        cache?.initializer?.toSource() != expectedInitializer ||
        _methodInvocations(unit, '_canonicalSnapshot').length != 1)
      'canonical cache must convert save/state/offset exactly once',
  ];
}

List<String> _toCanonicalMethodViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, 'toCanonical');
  if (method == null) {
    return const ['DecodedMatchSnapshot must declare toCanonical'];
  }
  final body = method.body;
  final expression = body is ExpressionFunctionBody ? body.expression : null;
  return [
    if (method.returnType?.toSource() != 'CanonicalGameSnapshot' ||
        (method.parameters?.parameters.isNotEmpty ?? true))
      'toCanonical must be parameterless and return CanonicalGameSnapshot',
    if (expression?.toSource() != '_canonicalSnapshotValue' ||
        _methodInvocations(method.body, '_canonicalSnapshot').isNotEmpty)
      'toCanonical must return only the memoized canonical snapshot',
  ];
}

List<String> _withStateCacheViolations(CompilationUnit unit) {
  final withState = _singleMethod(unit, 'withState');
  final body = withState?.body;
  final expression = body is ExpressionFunctionBody ? body.expression : null;
  return [
    if (!_hasFreshStateParameter(withState) ||
        expression?.toSource() !=
            'DecodedMatchSnapshot(save, state, eventLogOffset)')
      'withState must create a fresh decoded snapshot without the cache',
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
    if (snapshot != 'decodedSnapshot.toCanonical()' ||
        _methodInvocations(method.body, 'toCanonical').length != 1 ||
        _methodInvocations(method.body, '_canonicalSnapshot').isNotEmpty)
      '_finalizeSimultaneousTurn must read the decoded canonical cache',
  ];
}

MethodDeclaration? _singleMethod(CompilationUnit unit, String name) {
  final collector = _MethodCollector(name)..collect(unit);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

List<MethodInvocation> _methodInvocations(AstNode node, String name) {
  final collector = _InvocationCollector(name)..collect(node);
  return collector.invocations;
}

Expression? _singleVariableInitializer(AstNode node, String name) {
  return _singleVariable(node, name)?.initializer;
}

VariableDeclaration? _singleVariable(AstNode node, String name) {
  final collector = _VariableCollector(name)..collect(node);
  return collector.variables.length == 1 ? collector.variables.single : null;
}

String? _namedArgumentSource(ArgumentList arguments, String name) {
  final matches = _namedArguments(arguments, name);
  return matches.length == 1 ? matches.single.expression.toSource() : null;
}

List<NamedExpression> _namedArguments(ArgumentList arguments, String name) =>
    arguments.arguments
        .whereType<NamedExpression>()
        .where((argument) => argument.name.label.name == name)
        .toList();

bool _hasExactRequiredNamedParameters(
  MethodDeclaration method,
  Map<String, String> expected,
) {
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != expected.length) return false;
  return expected.entries.every(
    (entry) => _hasRequiredNamedParameter(method, entry.key, entry.value),
  );
}

bool _hasRequiredNamedParameter(
  MethodDeclaration method,
  String name,
  String type,
) => _matchingParameter(method, name, type, required: true);

bool _hasParameterNamed(MethodDeclaration method, String name) =>
    method.parameters?.parameters.any(
      (parameter) => parameter.name?.lexeme == name,
    ) ??
    false;

bool _hasFreshStateParameter(MethodDeclaration? method) {
  if (method == null ||
      method.returnType?.toSource() != 'DecodedMatchSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 1) return false;
  final parameter = parameters.single;
  return parameter is SimpleFormalParameter &&
      parameter.name?.lexeme == 'state' &&
      parameter.type?.toSource() == 'PersistentGameState';
}

bool _matchingParameter(
  MethodDeclaration method,
  String name,
  String type, {
  required bool required,
}) {
  final matches = <DefaultFormalParameter>[];
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) continue;
    final normalized = parameter.parameter;
    if (normalized.name?.lexeme == name) matches.add(parameter);
  }
  if (matches.length != 1) return false;
  final normalized = matches.single.parameter;
  final actualType = normalized is SimpleFormalParameter
      ? normalized.type?.toSource()
      : null;
  return actualType == type && (normalized.requiredKeyword != null) == required;
}

final class _MethodCollector extends RecursiveAstVisitor<void> {
  _MethodCollector(this.name);

  final String name;
  final List<MethodDeclaration> methods = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }
}

final class _InvocationCollector extends RecursiveAstVisitor<void> {
  _InvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> invocations = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _VariableCollector extends RecursiveAstVisitor<void> {
  _VariableCollector(this.name);

  final String name;
  final List<VariableDeclaration> variables = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitVariableDeclaration(node);
  }
}

final class _ReturnCollector extends RecursiveAstVisitor<void> {
  final List<ReturnStatement> statements = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitReturnStatement(ReturnStatement node) {
    statements.add(node);
    super.visitReturnStatement(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
