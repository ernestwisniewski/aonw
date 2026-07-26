part of 'authoritative_turn_movement_transport_guard.dart';

List<String> _rendererRetentionViolations(
  Map<String, ResolvedUnitResult> resolvedUnits,
) {
  final unit = resolvedUnits[_dispatcherPath]?.unit;
  final method = _method(unit, 'GameEffectDispatcher', '_handleUnitMove');
  final handleEffect = _method(unit, 'GameEffectDispatcher', '_handleEffect');
  final rendererSyncElement = _fieldElement(
    unit,
    'GameEffectDispatcher',
    '_onRendererStateChanged',
  );
  if (method == null) {
    return const ['GameEffectDispatcher._handleUnitMove must exist.'];
  }
  final retainParameter = method.parameters?.parameters
      .map(
        (parameter) => parameter is DefaultFormalParameter
            ? parameter.parameter
            : parameter,
      )
      .where((parameter) => parameter.name?.lexeme == 'retainAtDestination')
      .singleOrNull;
  final retainElement = retainParameter?.declaredFragment?.element.baseElement;
  final calls = _InvocationCollector(
    'UnitAnimationController',
    'animateUnitMove',
  );
  method.accept(calls);
  if (retainElement == null || calls.nodes.length != 1) {
    return const [
      'GameEffectDispatcher._handleUnitMove must call '
          'UnitAnimationController.animateUnitMove exactly once with a '
          'resolved retainAtDestination parameter.',
    ];
  }
  final arguments = {
    for (final argument
        in calls.nodes.single.argumentList.arguments
            .whereType<NamedExpression>())
      argument.name.label.name: argument.expression,
  };
  final retainExpression = arguments['retainAtDestination'];
  final completionExpression = arguments['onComplete'];
  final retainForwarded =
      retainExpression != null &&
      _sameElement(_expressionElement(retainExpression), retainElement);
  final finalOnlySync =
      completionExpression is ConditionalExpression &&
      _sameElement(
        _expressionElement(completionExpression.condition),
        retainElement,
      ) &&
      _isEmptyClosure(completionExpression.thenExpression) &&
      _sameElement(
        _expressionElement(completionExpression.elseExpression),
        rendererSyncElement,
      );
  final retentionFlowForwarded =
      handleEffect != null &&
      _parameterForwardedToInvocation(
        handleEffect,
        parameterName: 'retainMovementAtDestination',
        calledType: 'GameEffectDispatcher',
        calledMember: '_handleUnitMove',
        argumentName: 'retainAtDestination',
      );
  final violations = <String>[];
  if (!retainForwarded) {
    violations.add(
      'GameEffectDispatcher._handleUnitMove must forward '
      'retainAtDestination directly to '
      'UnitAnimationController.animateUnitMove.',
    );
  }
  if (!finalOnlySync) {
    violations.add(
      'GameEffectDispatcher._handleUnitMove must use the '
      '_onRendererStateChanged field only for the final segment.',
    );
  }
  if (!retentionFlowForwarded) {
    violations.add(
      'GameEffectDispatcher._handleEffect must forward '
      'retainMovementAtDestination directly to _handleUnitMove.',
    );
  }
  return violations;
}

Element? _fieldElement(
  CompilationUnit? unit,
  String ownerName,
  String fieldName,
) {
  if (unit == null) return null;
  for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
    if (declaration.namePart.typeName.lexeme != ownerName) continue;
    for (final field
        in declaration.body.members.whereType<FieldDeclaration>()) {
      for (final variable in field.fields.variables) {
        if (variable.name.lexeme != fieldName) continue;
        return variable.declaredFragment?.element.baseElement;
      }
    }
  }
  return null;
}

bool _parameterForwardedToInvocation(
  MethodDeclaration method, {
  required String parameterName,
  required String calledType,
  required String calledMember,
  required String argumentName,
}) {
  final parameterElement = _parameterElement(method, parameterName);
  if (parameterElement == null) return false;
  final calls = _InvocationCollector(calledType, calledMember);
  method.accept(calls);
  if (calls.nodes.length != 1) return false;
  final arguments = calls.nodes.single.argumentList.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == argumentName)
      .toList();
  return arguments.length == 1 &&
      _sameElement(
        _expressionElement(arguments.single.expression),
        parameterElement,
      );
}

bool _isEmptyClosure(Expression expression) {
  if (expression is! FunctionExpression) return false;
  final body = expression.body;
  return body is BlockFunctionBody && body.block.statements.isEmpty;
}

MethodDeclaration? _method(
  CompilationUnit? unit,
  String ownerName,
  String methodName,
) {
  if (unit == null) return null;
  for (final declaration in unit.declarations) {
    final members = switch (declaration) {
      ClassDeclaration(:final body)
          when declaration.namePart.typeName.lexeme == ownerName =>
        body.members,
      ExtensionDeclaration(:final body)
          when declaration.name?.lexeme == ownerName =>
        body.members,
      _ => const <ClassMember>[],
    };
    for (final method in members.whereType<MethodDeclaration>()) {
      if (method.name.lexeme == methodName) return method;
    }
  }
  return null;
}

bool _isDirectMember(
  Expression expression, {
  required String ownerName,
  required String memberName,
}) {
  final element = switch (expression) {
    PrefixedIdentifier(:final identifier) => identifier.element,
    PropertyAccess(:final propertyName) => propertyName.element,
    SimpleIdentifier(:final element) => element,
    ParenthesizedExpression(:final expression) => _expressionElement(
      expression,
    ),
    _ => null,
  };
  return _elementMemberKey(element) == '$ownerName.$memberName';
}

bool _isDirectNamedMemberOfElement(
  Expression expression, {
  required String memberName,
  required Element receiverElement,
}) {
  final memberElement = _expressionElement(expression);
  if (memberElement?.displayName != memberName) {
    return false;
  }
  final target = _directMemberTarget(expression);
  return target != null &&
      _sameElement(_expressionElement(target), receiverElement);
}

Element? _expressionElement(Expression expression) {
  return switch (expression) {
    SimpleIdentifier(:final element) => element?.baseElement,
    PrefixedIdentifier(:final identifier) => identifier.element?.baseElement,
    PropertyAccess(:final propertyName) => propertyName.element?.baseElement,
    ParenthesizedExpression(:final expression) => _expressionElement(
      expression,
    ),
    _ => null,
  };
}

bool _sameElement(Element? first, Element? second) =>
    first != null &&
    second != null &&
    _identityElement(first)?.id == _identityElement(second)?.id;

Element? _identityElement(Element? element) {
  final base = element?.baseElement;
  return switch (base) {
    PropertyAccessorElement(:final variable) => variable.baseElement,
    _ => base,
  };
}

String? _elementMemberKey(Element? element) {
  final base = element?.baseElement;
  if (base == null) return null;
  final enclosing = base.enclosingElement;
  if (enclosing is! InterfaceElement) return null;
  return '${enclosing.displayName}.${base.displayName}';
}

String? _interfaceName(NamedType type) {
  final element = type.element?.baseElement;
  if (element is InterfaceElement) return element.displayName;
  final staticType = type.type;
  return staticType is InterfaceType
      ? staticType.element.baseElement.displayName
      : null;
}

final class _InvocationCollector extends RecursiveAstVisitor<void> {
  _InvocationCollector(this.ownerName, this.memberName);

  final String ownerName;
  final String memberName;
  final List<MethodInvocation> nodes = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_elementMemberKey(node.methodName.element) ==
        '$ownerName.$memberName') {
      nodes.add(node);
    }
    super.visitMethodInvocation(node);
  }
}

final class _InstanceCreationCollector extends RecursiveAstVisitor<void> {
  _InstanceCreationCollector(this.typeName, {this.constructorName});

  final String typeName;
  final String? constructorName;
  final List<InstanceCreationExpression> nodes = [];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final actualTypeName = _interfaceName(node.constructorName.type);
    final actualConstructorName = node.constructorName.name?.name;
    if (actualTypeName == typeName &&
        actualConstructorName == constructorName) {
      nodes.add(node);
    }
    super.visitInstanceCreationExpression(node);
  }
}

final class _FinalLocalInitializerCollector extends RecursiveAstVisitor<void> {
  final Map<int, Expression> byElementId = {};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final declarationList = node.parent;
    final element = node.declaredFragment?.element.baseElement;
    final initializer = node.initializer;
    if (declarationList is VariableDeclarationList &&
        (declarationList.isFinal || declarationList.isConst) &&
        element != null &&
        initializer != null) {
      byElementId[element.id] = initializer;
    }
    super.visitVariableDeclaration(node);
  }
}

Element? _parameterElement(MethodDeclaration method, String name) {
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    final normalized = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;
    if (normalized.name?.lexeme == name) {
      return normalized.declaredFragment?.element.baseElement;
    }
  }
  return null;
}

String _site(String path, AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current case MethodDeclaration(:final name)) {
      return '$path::${_containerName(current)}.${name.lexeme}';
    }
    if (current case ConstructorDeclaration(:final name)) {
      final constructorName = name?.lexeme ?? 'new';
      return '$path::${_containerName(current)}.$constructorName';
    }
    if (current case FunctionDeclaration(:final name)) {
      return '$path::${name.lexeme}';
    }
    current = current.parent;
  }
  return '$path::<top-level>';
}

String _containerName(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    switch (current) {
      case ClassDeclaration():
        return current.namePart.typeName.lexeme;
      case ExtensionDeclaration():
        return current.name?.lexeme ?? '<extension>';
      case ExtensionTypeDeclaration():
        return current.primaryConstructor.typeName.lexeme;
      case EnumDeclaration():
        return current.namePart.typeName.lexeme;
      case MixinDeclaration():
        return current.name.lexeme;
    }
    current = current.parent;
  }
  return '<top-level>';
}
