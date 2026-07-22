import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

const movementPreviewReducerPath =
    'lib/game/domain/reducer/movement/movement_reducer_move_preview.dart';

const _forbiddenExecutorTypes = {
  'UnitMovementPathfinder',
  'MovementCommandResolver',
  'MovementCommandExecutor',
  'UnitMovedEvent',
  'AnimateUnitMoveEffect',
};

const _forbiddenExecutorMembers = {
  'replaceUnit',
  'recomputeAfterUnitMove',
  'withDiscoveredDiplomaticContacts',
  '_queuedPathFor',
  'copyWithQueuedPath',
  'copyWith',
};

List<String> movementPreviewKernelViolations(String? source) {
  if (source == null) return const ['movement preview reducer must exist'];
  final unit = parseString(
    content: source,
    path: movementPreviewReducerPath,
  ).unit;
  final reducer = _singlePreviewReducer(unit);
  if (reducer == null) {
    return const ['_MovePreviewReducer must be declared exactly once'];
  }
  final confirm = _singleConfirmMethod(reducer);
  if (confirm == null) {
    return const ['confirmPreview must be declared exactly once'];
  }
  final reachableBodies = _reachablePreviewBodies(unit, confirm);

  return [
    ..._confirmSignatureViolations(confirm),
    ..._delegationViolations(confirm, reachableBodies),
    ..._forbiddenExecutorViolations(unit, reachableBodies),
  ];
}

ClassDeclaration? _singlePreviewReducer(CompilationUnit unit) {
  final reducers = unit.declarations
      .whereType<ClassDeclaration>()
      .where(
        (declaration) =>
            declaration.namePart.typeName.lexeme == '_MovePreviewReducer',
      )
      .toList();
  return reducers.length == 1 ? reducers.single : null;
}

MethodDeclaration? _singleConfirmMethod(ClassDeclaration reducer) {
  final methods = reducer.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == 'confirmPreview')
      .toList();
  return methods.length == 1 ? methods.single : null;
}

List<String> _confirmSignatureViolations(MethodDeclaration confirm) => [
  if (!confirm.isStatic)
    'confirmPreview must remain a static reducer entry point',
  if (!_hasRequiredNamedParameter(
    confirm,
    name: 'context',
    type: 'GameCommandContext',
  ))
    'confirmPreview must require the command context used by the kernel',
  if (!_hasRequiredNamedParameter(
    confirm,
    name: 'fogOfWarService',
    type: 'FogOfWarService',
  ))
    'confirmPreview must require the fog service used by the kernel',
];

List<String> _delegationViolations(
  MethodDeclaration confirm,
  List<FunctionBody> reachableBodies,
) {
  final delegation = _PreviewKernelDelegationVisitor();
  for (final body in reachableBodies) {
    body.accept(delegation);
  }
  final calls = delegation.moveUnitCalls;
  return [
    if (calls.length != 1)
      'confirmPreview must call MovementReducer.moveUnit exactly once',
    if (calls.length == 1) ...[
      ..._exactCallViolations(confirm, calls.single),
      ..._transitionOutputViolations(confirm, calls.single),
    ],
  ];
}

List<String> _exactCallViolations(
  MethodDeclaration confirm,
  MethodInvocation call,
) => [
  if (!_isInside(call, confirm.body))
    'confirmPreview must delegate to MovementReducer.moveUnit directly',
  if (!_hasExactInputBindings(confirm.body))
    'confirmPreview must derive workState, selected, and preview from state',
  if (!_hasExactPositionalForwarding(call))
    'confirmPreview must forward workState, the selected preview target, '
        'and mapView exactly',
  if (!_hasExactNamedForwarding(call, 'context'))
    'confirmPreview must forward context: context exactly',
  if (!_hasExactNamedForwarding(call, 'fogOfWarService'))
    'confirmPreview must forward fogOfWarService: fogOfWarService exactly',
  if (!_hasOnlyExpectedArguments(call))
    'confirmPreview must not widen the MovementReducer.moveUnit call',
  if (!_isFinalTransitionBinding(call))
    'confirmPreview must bind the delegated result to final transition',
];

List<String> _transitionOutputViolations(
  MethodDeclaration confirm,
  MethodInvocation call,
) {
  final shape = _ConfirmBodyShape(confirm.body, afterOffset: call.end);
  confirm.body.accept(shape);
  final returned = shape.returns.length == 1
      ? shape.returns.single.expression
      : null;
  if (_isIdentifier(returned, 'transition')) return const [];
  final arguments = _gameStateTransitionArguments(returned);
  final variables = shape.finalVariables;
  return [
    if (!_isExactDelegatedState(_namedArgument(arguments, 'state'), variables))
      'confirmPreview must preserve the delegated transition state',
    if (!_isDelegatedMember(_namedArgument(arguments, 'events'), 'events'))
      'confirmPreview must preserve the delegated transition events',
    if (!_isDelegatedMember(
      _namedArgument(arguments, 'uiEffects'),
      'uiEffects',
    ))
      'confirmPreview must preserve the delegated transition UI effects',
  ];
}

List<String> _forbiddenExecutorViolations(
  CompilationUnit unit,
  List<FunctionBody> reachableBodies,
) {
  final symbols = _forbiddenSymbolsAndAliases(unit);
  final found = <String>{};
  for (final body in reachableBodies) {
    found.addAll(_identifierNames(body).where(symbols.contains));
  }
  return [
    for (final symbol in found)
      '$symbol must not execute movement in confirmPreview',
  ];
}

bool _hasRequiredNamedParameter(
  MethodDeclaration method, {
  required String name,
  required String type,
}) {
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) continue;
    final normalized = parameter.parameter;
    if (normalized is SimpleFormalParameter &&
        normalized.name?.lexeme == name &&
        normalized.type?.toSource() == type &&
        normalized.requiredKeyword != null &&
        parameter.defaultValue == null) {
      return true;
    }
  }
  return false;
}

bool _hasExactPositionalForwarding(MethodInvocation call) {
  final positional = call.argumentList.arguments
      .where((argument) => argument is! NamedExpression)
      .toList();
  return positional.length == 3 &&
      _isIdentifier(positional[0], 'workState') &&
      _isExpectedMoveCommand(positional[1]) &&
      _isIdentifier(positional[2], 'mapView');
}

bool _hasExactNamedForwarding(MethodInvocation call, String name) {
  final matching = call.argumentList.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == name)
      .toList();
  return matching.length == 1 &&
      _isIdentifier(matching.single.expression, name);
}

bool _hasOnlyExpectedArguments(MethodInvocation call) {
  final positional = call.argumentList.arguments
      .where((argument) => argument is! NamedExpression)
      .length;
  final named = {
    for (final argument
        in call.argumentList.arguments.whereType<NamedExpression>())
      argument.name.label.name,
  };
  return positional == 3 &&
      call.argumentList.arguments.length == 5 &&
      _sameSet(named, const {'context', 'fogOfWarService'});
}

bool _isExpectedMoveCommand(Expression expression) {
  final ArgumentList? arguments = switch (expression) {
    InstanceCreationExpression(:final constructorName, :final argumentList)
        when constructorName.type.name.lexeme == 'MoveUnitCommand' =>
      argumentList,
    MethodInvocation(:final target, :final methodName, :final argumentList)
        when target == null && methodName.name == 'MoveUnitCommand' =>
      argumentList,
    _ => null,
  };
  if (arguments == null || arguments.arguments.length != 3) return false;
  return _isMember(arguments.arguments[0], 'selected', 'id') &&
      _isMember(arguments.arguments[1], 'preview', 'targetCol') &&
      _isMember(arguments.arguments[2], 'preview', 'targetRow');
}

bool _isIdentifier(Expression? expression, String name) =>
    expression is SimpleIdentifier && expression.name == name;

bool _isMember(Expression expression, String expectedTarget, String member) {
  return switch (expression) {
    PrefixedIdentifier(:final prefix, :final identifier) =>
      prefix.name == expectedTarget && identifier.name == member,
    PropertyAccess(target: final receiver, :final propertyName) =>
      receiver is SimpleIdentifier &&
          receiver.name == expectedTarget &&
          propertyName.name == member,
    _ => false,
  };
}

bool _isFinalTransitionBinding(MethodInvocation call) {
  final declaration = call.parent;
  final declarationList = declaration?.parent;
  return declaration is VariableDeclaration &&
      declaration.name.lexeme == 'transition' &&
      declaration.initializer == call &&
      declarationList is VariableDeclarationList &&
      declarationList.isFinal;
}

bool _hasExactInputBindings(FunctionBody body) {
  final shape = _ConfirmBodyShape(body, afterOffset: body.end);
  body.accept(shape);
  final variables = shape.finalVariables;
  return variables['preview']?.toSource() == 'state.movePreview' &&
      variables['selected']?.toSource() == 'state.selectedUnit' &&
      variables['workState']?.toSource() ==
          'state.copyWithInteraction(movePreview: null)';
}

List<FunctionBody> _reachablePreviewBodies(
  CompilationUnit unit,
  MethodDeclaration confirm,
) {
  final bodyIndex = _PreviewBodyIndexVisitor();
  unit.accept(bodyIndex);
  final aliasesByName = _aliasReferences(unit);
  final reachable = <FunctionBody>[confirm.body];
  final reachedBodies = <FunctionBody>{confirm.body};
  final pendingNames = _identifierNames(confirm.body).toList();
  final reachedNames = <String>{};
  for (var index = 0; index < pendingNames.length; index++) {
    final name = pendingNames[index];
    if (!reachedNames.add(name)) continue;
    pendingNames.addAll(aliasesByName[name] ?? const {});
    for (final body in bodyIndex.bodiesByName[name] ?? const <FunctionBody>[]) {
      if (!reachedBodies.add(body)) continue;
      reachable.add(body);
      pendingNames.addAll(_identifierNames(body));
    }
  }
  return reachable;
}

Map<String, Set<String>> _aliasReferences(CompilationUnit unit) {
  final visitor = _AliasReferenceVisitor();
  unit.accept(visitor);
  return visitor.aliases;
}

ArgumentList? _gameStateTransitionArguments(Expression? expression) {
  final arguments = switch (expression) {
    InstanceCreationExpression(:final constructorName, :final argumentList)
        when constructorName.type.name.lexeme == 'GameStateTransition' =>
      argumentList,
    MethodInvocation(:final target, :final methodName, :final argumentList)
        when target == null && methodName.name == 'GameStateTransition' =>
      argumentList,
    _ => null,
  };
  if (arguments == null || arguments.arguments.length != 3) return null;
  final names = {
    for (final argument in arguments.arguments.whereType<NamedExpression>())
      argument.name.label.name,
  };
  return _sameSet(names, const {'state', 'events', 'uiEffects'})
      ? arguments
      : null;
}

Expression? _namedArgument(ArgumentList? arguments, String name) {
  if (arguments == null) return null;
  final matches = arguments.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == name)
      .toList();
  return matches.length == 1 ? matches.single.expression : null;
}

bool _isDelegatedMember(Expression? expression, String member) =>
    expression != null && _isMember(expression, 'transition', member);

bool _isExactDelegatedState(
  Expression? expression,
  Map<String, Expression> variables,
) =>
    _isIdentifier(expression, 'next') &&
    variables['updatedUnit']?.toSource() ==
        'transition.state.unitById(selected.id)' &&
    variables['completedNow']?.toSource() ==
        'updatedUnit != null && updatedUnit.queuedPath == null' &&
    variables['next']?.toSource() ==
        'identical(transition.state, workState) ? '
            'MovementReducer._clearMoveTargeting(transition.state) : '
            'transition.state.copyWithInteraction('
            'moveCommandActive: completedNow, movePreview: null)';

bool _isInside(AstNode node, AstNode ancestor) {
  AstNode? current = node;
  while (current != null) {
    if (identical(current, ancestor)) return true;
    current = current.parent;
  }
  return false;
}

bool _sameSet<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);

Set<String> _forbiddenSymbolsAndAliases(CompilationUnit unit) {
  final roots = {..._forbiddenExecutorTypes, ..._forbiddenExecutorMembers};
  final aliases = _aliasReferences(unit);
  for (final alias in unit.declarations.whereType<GenericTypeAlias>()) {
    aliases[alias.name.lexeme] = _identifierNames(alias.type);
  }
  return {
    ...roots,
    for (final name in aliases.keys)
      if (_reachesForbidden(name, aliases, roots, <String>{})) name,
  };
}

bool _reachesForbidden(
  String name,
  Map<String, Set<String>> aliases,
  Set<String> roots,
  Set<String> visiting,
) {
  if (!visiting.add(name)) return false;
  for (final reference in aliases[name] ?? const <String>{}) {
    if (roots.contains(reference) ||
        _reachesForbidden(reference, aliases, roots, visiting)) {
      return true;
    }
  }
  return false;
}

Set<String> _identifierNames(AstNode node) {
  final visitor = _IdentifierNameVisitor();
  node.accept(visitor);
  return visitor.names;
}

final class _PreviewKernelDelegationVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> moveUnitCalls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isIdentifier(node.target, 'MovementReducer') &&
        node.methodName.name == 'moveUnit') {
      moveUnitCalls.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

final class _ConfirmBodyShape extends RecursiveAstVisitor<void> {
  _ConfirmBodyShape(this.body, {required this.afterOffset});

  final FunctionBody body;
  final int afterOffset;
  final List<ReturnStatement> returns = [];
  final Map<String, Expression> finalVariables = {};

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.offset > afterOffset) returns.add(node);
    super.visitReturnStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final variables = node.parent;
    if (variables is VariableDeclarationList && variables.isFinal) {
      final initializer = node.initializer;
      if (initializer != null) {
        finalVariables[node.name.lexeme] = initializer;
      }
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (identical(node.body, body)) super.visitFunctionExpression(node);
  }
}

final class _PreviewBodyIndexVisitor extends RecursiveAstVisitor<void> {
  final Map<String, List<FunctionBody>> bodiesByName = {};

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    bodiesByName.putIfAbsent(node.name.lexeme, () => []).add(node.body);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    bodiesByName
        .putIfAbsent(node.name.lexeme, () => [])
        .add(node.functionExpression.body);
    super.visitFunctionDeclaration(node);
  }
}

final class _AliasReferenceVisitor extends RecursiveAstVisitor<void> {
  final Map<String, Set<String>> aliases = {};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer != null) {
      aliases[node.name.lexeme] = _identifierNames(initializer);
    }
    super.visitVariableDeclaration(node);
  }
}

final class _IdentifierNameVisitor extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    names
      ..add(node.prefix.name)
      ..add(node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
