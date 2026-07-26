part of 'authoritative_turn_movement_transport_guard.dart';

final class _TransportFacts {
  final Map<String, Map<String, int>> constructorCounts = {};
  final Map<String, Map<String, int>> referenceCounts = {};
  final List<String> boundaryViolations = [];

  void addConstructor(String typeName, String site) {
    constructorCounts
        .putIfAbsent(typeName, () => {})
        .update(site, (count) => count + 1, ifAbsent: () => 1);
  }

  void addReference(String member, String site) {
    referenceCounts
        .putIfAbsent(member, () => {})
        .update(site, (count) => count + 1, ifAbsent: () => 1);
  }
}

final class _TransportFactVisitor extends RecursiveAstVisitor<void> {
  _TransportFactVisitor({
    required this.path,
    required this.unit,
    required this.facts,
    required this.transportGraphPaths,
  });

  final String path;
  final CompilationUnit unit;
  final _TransportFacts facts;
  final Set<String> transportGraphPaths;

  @override
  void visitConstructorName(ConstructorName node) {
    final element = node.element?.baseElement;
    final typeName = element?.enclosingElement.displayName;
    if (typeName == 'MovementCommandExecution' ||
        typeName == 'TurnMovementDelta') {
      facts.addConstructor(typeName!, _site(path, node));
    }
    super.visitConstructorName(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    if (transportGraphPaths.contains(path)) {
      final semanticUri = node.libraryImport?.importedLibrary?.uri;
      final uri = semanticUri ?? Uri.tryParse(node.uri.stringValue ?? '');
      if (uri != null &&
          _forbiddenTransportLibraryNames.contains(
            uri.pathSegments.lastOrNull,
          )) {
        facts.boundaryViolations.add(
          '${_location(node)} imports forbidden movement producer $uri.',
        );
      }
    }
    super.visitImportDirective(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (transportGraphPaths.contains(path)) {
      final name = _interfaceName(node);
      if (name != null && _forbiddenTransportTypes.contains(name)) {
        facts.boundaryViolations.add(
          '${_location(node)} references forbidden movement producer $name.',
        );
      }
    }
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element?.baseElement;
    final memberKey = _elementMemberKey(element);
    if (memberKey != null && _expectedReferences.containsKey(memberKey)) {
      facts.addReference(memberKey, _site(path, node));
    }
    final site = _site(path, node);
    if ((transportGraphPaths.contains(path) ||
            _orderSensitiveOwners.contains(site)) &&
        element is ExecutableElement &&
        _forbiddenOrderMembers.contains(element.displayName) &&
        _usesExecutionCarrier(node)) {
      facts.boundaryViolations.add(
        '${_location(node)} must not reorder or rebuild authoritative '
        'movement with ${element.displayName}.',
      );
    }
    if (transportGraphPaths.contains(path) &&
        element is InterfaceElement &&
        _forbiddenTransportTypes.contains(element.displayName)) {
      facts.boundaryViolations.add(
        '${_location(node)} references forbidden movement producer '
        '${element.displayName}.',
      );
    }
    super.visitSimpleIdentifier(node);
  }

  String _location(AstNode node) {
    final line = unit.lineInfo.getLocation(node.offset).lineNumber;
    return '$path:$line';
  }
}

Iterable<String> _carrierDependencySourcePaths(CompilationUnit unit) {
  final visitor = _CarrierDependencyVisitor();
  unit.accept(visitor);
  return visitor.sourcePaths;
}

final class _CarrierDependencyVisitor extends RecursiveAstVisitor<void> {
  final Set<String> sourcePaths = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_invocationUsesExecutionCarrier(node)) {
      _record(node.methodName.element);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_typeContainsExecutionCarrier(node.staticType) ||
        _typeContainsExecutionCarrier(node.function.staticType) ||
        node.argumentList.arguments.any(
          (argument) => _typeContainsExecutionCarrier(argument.staticType),
        )) {
      _record(_expressionElement(node.function));
    }
    super.visitFunctionExpressionInvocation(node);
  }

  void _record(Element? element) {
    final source = element?.baseElement.firstFragment.libraryFragment?.source;
    if (source != null) sourcePaths.add(source.fullName);
  }
}

bool _usesExecutionCarrier(SimpleIdentifier node) {
  final parent = node.parent;
  return switch (parent) {
    MethodInvocation(:final methodName) when identical(methodName, node) =>
      _invocationUsesExecutionCarrier(parent),
    PrefixedIdentifier(:final identifier, :final prefix)
        when identical(identifier, node) =>
      _typeContainsExecutionCarrier(prefix.staticType),
    PropertyAccess(:final propertyName, :final realTarget)
        when identical(propertyName, node) =>
      _typeContainsExecutionCarrier(realTarget.staticType),
    _ => false,
  };
}

bool _invocationUsesExecutionCarrier(MethodInvocation node) {
  if (_typeContainsExecutionCarrier(node.staticType)) return true;
  final target = node.realTarget;
  if (_typeContainsExecutionCarrier(target?.staticType)) return true;
  final element = node.methodName.element?.baseElement;
  final acceptsStaticArguments =
      target == null ||
      target.staticType?.isDartCoreType == true ||
      (element is ExecutableElement && element.isStatic);
  return acceptsStaticArguments &&
      node.argumentList.arguments.any(
        (argument) => _typeContainsExecutionCarrier(argument.staticType),
      );
}

bool _typeContainsExecutionCarrier(
  DartType? type, [
  Set<int>? visitedElements,
]) {
  if (type == null) return false;
  final visited = visitedElements ?? <int>{};
  final element = type.element?.baseElement;
  if (element != null) {
    if (_executionCarrierNames.contains(element.displayName)) return true;
    if (!visited.add(element.id)) return false;
  }
  if (type.alias case final alias?) {
    if (_executionCarrierNames.contains(
      alias.element.baseElement.displayName,
    )) {
      return true;
    }
    if (alias.typeArguments.any(
      (argument) => _typeContainsExecutionCarrier(argument, visited),
    )) {
      return true;
    }
  }
  return switch (type) {
    ParameterizedType(:final typeArguments) => typeArguments.any(
      (argument) => _typeContainsExecutionCarrier(argument, visited),
    ),
    FunctionType(:final returnType, :final formalParameters) =>
      _typeContainsExecutionCarrier(returnType, visited) ||
          formalParameters.any(
            (parameter) =>
                _typeContainsExecutionCarrier(parameter.type, visited),
          ),
    RecordType(:final namedFields, :final positionalFields) =>
      namedFields.any(
            (field) => _typeContainsExecutionCarrier(field.type, visited),
          ) ||
          positionalFields.any(
            (field) => _typeContainsExecutionCarrier(field.type, visited),
          ),
    TypeParameterType(:final bound) => _typeContainsExecutionCarrier(
      bound,
      visited,
    ),
    _ => false,
  };
}
