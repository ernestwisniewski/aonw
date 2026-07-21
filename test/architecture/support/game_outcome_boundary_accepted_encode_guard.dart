part of '../game_outcome_boundary_test.dart';

List<String> _rootReductionDelegationViolations(
  CompilationUnit unit,
  String methodName,
) {
  final method = _singleMethod(unit, methodName);
  if (method == null) return ['must declare exactly one $methodName method'];

  final acceptedReductions = _MethodInvocationCollector('_acceptedReduction')
    ..collect(method.body);
  final conversions = _MethodInvocationCollector('_canonicalSnapshot')
    ..collect(method.body);
  final outcomes = _MethodInvocationCollector('_gameOutcome')
    ..collect(method.body);
  final acceptedReduction = acceptedReductions.invocations.length == 1
      ? acceptedReductions.invocations.single
      : null;
  return [
    if (acceptedReductions.invocations.length != 1)
      '$methodName must call _acceptedReduction exactly once; found '
          '${acceptedReductions.invocations.length}',
    if (conversions.invocations.isNotEmpty)
      '$methodName must not call _canonicalSnapshot directly',
    if (outcomes.invocations.isNotEmpty)
      '$methodName must not call _gameOutcome directly',
    if (acceptedReduction != null &&
        _namedArgument(
              acceptedReduction.argumentList,
              'decodedSnapshot',
            )?.toSource() !=
            'decodedSnapshot')
      '$methodName must forward decodedSnapshot unchanged to '
          '_acceptedReduction',
  ];
}

List<String> _acceptedReductionFallbackArgumentViolations(
  CompilationUnit unit,
) {
  const methodName = '_acceptedReduction';
  final method = _singleMethod(unit, methodName);
  if (method == null) return const ['must declare exactly one $methodName'];

  final variables = _NamedVariableCollector('canonicalSnapshot')
    ..collect(method.body);
  final initializer = variables.variables.length == 1
      ? variables.variables.single.initializer
      : null;
  final fallback =
      initializer is BinaryExpression && initializer.operator.lexeme == '??'
      ? initializer.rightOperand
      : null;
  return [
    if (!_isExactCanonicalFallback(fallback))
      '$methodName canonicalSnapshot fallback must use nextSave, '
          'result.state, and decodedSnapshot.eventLogOffset',
  ];
}

bool _isExactCanonicalFallback(Expression? fallback) {
  if (fallback is! MethodInvocation ||
      fallback.target != null ||
      fallback.methodName.name != '_canonicalSnapshot') {
    return false;
  }
  final arguments = fallback.argumentList;
  return arguments.arguments.length == 3 &&
      _namedArgument(arguments, 'save')?.toSource() == 'nextSave' &&
      _namedArgument(arguments, 'state')?.toSource() == 'result.state' &&
      _namedArgument(arguments, 'eventLogOffset')?.toSource() ==
          'decodedSnapshot.eventLogOffset';
}

List<String> _acceptedReductionEncodeViolations(CompilationUnit unit) {
  const methodName = '_acceptedReduction';
  final method = _singleMethod(unit, methodName);
  if (method == null) return const ['must declare exactly one $methodName'];

  return [
    ..._acceptedPreviousStateViolations(method),
    ..._acceptedCodecCallViolations(method),
    ..._acceptedSnapshotBypassViolations(method),
    ..._acceptedReductionResultViolations(method),
  ];
}

List<String> _acceptedPreviousStateViolations(MethodDeclaration method) {
  const methodName = '_acceptedReduction';
  final previousStates = _NamedVariableCollector('previousState')
    ..collect(method.body);
  final previousState = previousStates.variables.length == 1
      ? previousStates.variables.single
      : null;
  final previousStateDeclaration = previousState?.parent;
  return [
    if (previousState == null ||
        previousStateDeclaration is! VariableDeclarationList ||
        !previousStateDeclaration.isFinal ||
        previousState.initializer?.toSource() != 'decodedSnapshot.state')
      '$methodName must declare final previousState from '
          'decodedSnapshot.state',
  ];
}

List<String> _acceptedCodecCallViolations(MethodDeclaration method) {
  const methodName = '_acceptedReduction';
  final allEncodes = _MethodInvocationCollector('encode')..collect(method.body);
  final codecEncodes = allEncodes.invocations
      .where(
        (invocation) =>
            invocation.target?.toSource() == '_runningMatchSnapshotCodec',
      )
      .toList();
  final encode = allEncodes.invocations.length == 1 && codecEncodes.length == 1
      ? codecEncodes.single
      : null;
  final identicalCalls = _MethodInvocationCollector('identical')
    ..collect(method.body);
  return [
    if (encode == null)
      '$methodName must call _runningMatchSnapshotCodec.encode exactly once; '
          'found ${codecEncodes.length}',
    if (encode != null && !_hasExactAcceptedEncodeArguments(encode))
      '$methodName encode must receive decodedSnapshot and change-only '
          'save/state values',
    if (identicalCalls.invocations.isNotEmpty)
      '$methodName must use value equality (==), never identical',
  ];
}

List<String> _acceptedSnapshotBypassViolations(MethodDeclaration method) {
  const methodName = '_acceptedReduction';
  final wireConstructions = _AcceptedConstructionCollector('WireSnapshot')
    ..collect(method.body);
  final directSnapshotPatches = _directSnapshotPatches(method.body);
  return [
    if (wireConstructions.references.isNotEmpty)
      '$methodName must not construct a WireSnapshot',
    if (directSnapshotPatches.isNotEmpty)
      '$methodName must not patch snapshot save/state directly',
  ];
}

List<String> _acceptedReductionResultViolations(MethodDeclaration method) {
  const methodName = '_acceptedReduction';
  final reductions = _AcceptedConstructionCollector('ServerCommandReduction')
    ..collect(method.body);
  if (reductions.references.length != 1) {
    return [
      '$methodName must construct exactly one ServerCommandReduction; found '
          '${reductions.references.length}',
    ];
  }
  final arguments = reductions.references.single.arguments;
  return [
    ..._acceptedReductionStateViolations(arguments),
    ..._acceptedReductionSnapshotViolations(method, arguments),
  ];
}

List<String> _acceptedReductionStateViolations(ArgumentList arguments) => [
  if (_namedArgument(arguments, 'previousState')?.toSource() !=
          'previousState' ||
      _namedArgument(arguments, 'state')?.toSource() != 'result.state')
    '_acceptedReduction must expose previousState: previousState and '
        'state: result.state',
];

List<String> _acceptedReductionSnapshotViolations(
  MethodDeclaration method,
  ArgumentList arguments,
) {
  final encode = _singleAcceptedCodecEncode(method.body);
  final snapshot = _namedArgument(arguments, 'snapshot');
  return [
    if (encode == null ||
        snapshot == null ||
        !_expressionUsesInvocation(method.body, snapshot, encode))
      '_acceptedReduction must return the codec-encoded snapshot',
  ];
}

MethodInvocation? _singleAcceptedCodecEncode(AstNode body) {
  final allEncodes = _MethodInvocationCollector('encode')..collect(body);
  if (allEncodes.invocations.length != 1) return null;
  final encode = allEncodes.invocations.single;
  return encode.target?.toSource() == '_runningMatchSnapshotCodec'
      ? encode
      : null;
}

bool _hasExactAcceptedEncodeArguments(MethodInvocation encode) {
  final positional = encode.argumentList.arguments
      .where((argument) => argument is! NamedExpression)
      .toList();
  if (encode.argumentList.arguments.length != 3 ||
      positional.length != 1 ||
      positional.single.toSource() != 'decodedSnapshot') {
    return false;
  }
  final save = _namedArgument(encode.argumentList, 'save');
  final state = _namedArgument(encode.argumentList, 'state');
  return save != null &&
      state != null &&
      _isChangedValueOrNull(
        save,
        replacement: 'nextSave',
        current: 'decodedSnapshot.save',
      ) &&
      _isChangedValueOrNull(
        state,
        replacement: 'result.state',
        current: 'previousState',
      );
}

bool _isChangedValueOrNull(
  Expression expression, {
  required String replacement,
  required String current,
}) {
  if (expression is! ConditionalExpression) return false;
  final condition = expression.condition;
  return condition is BinaryExpression &&
      condition.operator.lexeme == '==' &&
      condition.leftOperand.toSource() == replacement &&
      condition.rightOperand.toSource() == current &&
      expression.thenExpression.toSource() == 'null' &&
      expression.elseExpression.toSource() == replacement;
}

List<MethodInvocation> _directSnapshotPatches(AstNode body) {
  final copyCalls = _MethodInvocationCollector('copyWith')..collect(body);
  return copyCalls.invocations.where((invocation) {
    final target = invocation.target?.toSource().toLowerCase() ?? '';
    if (!target.contains('snapshot')) return false;
    return invocation.argumentList.arguments.whereType<NamedExpression>().any(
      (argument) => const {'save', 'state'}.contains(argument.name.label.name),
    );
  }).toList();
}

bool _expressionUsesInvocation(
  AstNode body,
  Expression expression,
  MethodInvocation invocation,
) {
  if (expression.offset == invocation.offset &&
      expression.length == invocation.length) {
    return true;
  }
  if (expression is! SimpleIdentifier) return false;
  final variables = _NamedVariableCollector(expression.name)..collect(body);
  return variables.variables.length == 1 &&
      variables.variables.single.initializer?.offset == invocation.offset &&
      variables.variables.single.initializer?.length == invocation.length;
}

final class _AcceptedConstructionReference {
  const _AcceptedConstructionReference({
    required this.node,
    required this.arguments,
  });

  final AstNode node;
  final ArgumentList arguments;
}

final class _AcceptedConstructionCollector extends RecursiveAstVisitor<void> {
  _AcceptedConstructionCollector(this.type);

  final String type;
  final List<_AcceptedConstructionReference> references = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == type) {
      references.add(
        _AcceptedConstructionReference(
          node: node,
          arguments: node.argumentList,
        ),
      );
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final isUnnamed = node.target == null && node.methodName.name == type;
    final isNamed = node.target?.toSource() == type;
    if (isUnnamed || isNamed) {
      references.add(
        _AcceptedConstructionReference(
          node: node,
          arguments: node.argumentList,
        ),
      );
    }
    super.visitMethodInvocation(node);
  }
}
