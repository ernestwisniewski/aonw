import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'map_boundary_source_guard.dart';

/// Counts instance calls and tear-offs without resolved AST elements.
///
/// Movement additionally needs to recognize non-const constructor syntax such
/// as `MovementCommandResolver(service: value).resolve()`, which the parser
/// represents as an unresolved method invocation during a source-only scan.
Map<String, int> movementInstanceMemberReferenceCountsByPath(
  Map<String, String> sources,
  String targetType,
  String memberName,
) {
  final counts = <String, int>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final bindings = _MovementTargetBindings(targetTypes)
      ..collect(unit)
      ..infer();
    final references = _MovementInstanceReferences(
      targetTypes: targetTypes,
      bindings: bindings.instances,
      factories: bindings.factories,
      memberName: memberName,
    )..collect(unit);
    if (references.count > 0) counts[entry.key] = references.count;
  }
  return counts;
}

/// Counts every syntactic construction or constructor tear-off of [targetType].
///
/// This closes the source-only data-flow gap left by instance inference: an
/// untyped factory or collection holder can hide the receiver type at the
/// eventual member access, but it cannot create the resolver without leaving
/// one of these reviewed construction references.
Map<String, int> movementConstructionReferenceCountsByPath(
  Map<String, String> sources,
  String targetType,
) {
  final counts = <String, int>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final visitor = _MovementConstructionReferences(targetTypes);
    parseString(content: entry.value, path: entry.key).unit.accept(visitor);
    if (visitor.count > 0) counts[entry.key] = visitor.count;
  }
  return counts;
}

/// Counts all references to [memberName], independently of receiver typing.
///
/// Use this only inside the exact reviewed call-site files. It deliberately
/// fails closed when an untyped factory hides a second resolver receiver.
Map<String, int> movementNamedMemberReferenceCountsByPath(
  Map<String, String> sources,
  String memberName,
) {
  final counts = <String, int>{};
  for (final entry in sources.entries) {
    final visitor = _MovementNamedMemberReferences(memberName);
    parseString(content: entry.value, path: entry.key).unit.accept(visitor);
    if (visitor.count > 0) counts[entry.key] = visitor.count;
  }
  return counts;
}

final class _MovementTargetBindings extends RecursiveAstVisitor<void> {
  _MovementTargetBindings(this.targetTypes);

  final Set<String> targetTypes;
  final Set<String> instances = {};
  final Set<String> factories = {};
  final List<VariableDeclaration> inferredVariables = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (_isTargetType(node.type, targetTypes)) {
      instances.addAll(node.variables.map((variable) => variable.name.lexeme));
    } else {
      inferredVariables.addAll(node.variables);
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    final name = node.name?.lexeme;
    if (_isTargetType(node.type, targetTypes) && name != null) {
      instances.add(name);
    }
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (_isTargetType(node.type, targetTypes)) instances.add(node.name.lexeme);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isTargetType(node.returnType, targetTypes)) {
      (node.isGetter ? instances : factories).add(node.name.lexeme);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isTargetType(node.returnType, targetTypes)) {
      (node.isGetter ? instances : factories).add(node.name.lexeme);
    }
    super.visitMethodDeclaration(node);
  }

  void infer() {
    var changed = true;
    while (changed) {
      changed = false;
      for (final variable in inferredVariables) {
        final initializer = variable.initializer;
        if (initializer == null) continue;
        if (_isTargetFactory(
              initializer,
              targetTypes: targetTypes,
              factories: factories,
            ) &&
            factories.add(variable.name.lexeme)) {
          changed = true;
          continue;
        }
        if (_isTargetInstance(
              initializer,
              targetTypes: targetTypes,
              bindings: instances,
              factories: factories,
            ) &&
            instances.add(variable.name.lexeme)) {
          changed = true;
        }
      }
    }
  }
}

final class _MovementInstanceReferences extends RecursiveAstVisitor<void> {
  _MovementInstanceReferences({
    required this.targetTypes,
    required this.bindings,
    required this.factories,
    required this.memberName,
  });

  final Set<String> targetTypes;
  final Set<String> bindings;
  final Set<String> factories;
  final String memberName;
  int count = 0;

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName && _isReceiver(node.target)) {
      count++;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName && _isReceiver(node.prefix)) {
      count++;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName && _isReceiver(node.target)) {
      count++;
    }
    super.visitPropertyAccess(node);
  }

  bool _isReceiver(Expression? expression) {
    return expression != null &&
        _isTargetInstance(
          expression,
          targetTypes: targetTypes,
          bindings: bindings,
          factories: factories,
        );
  }
}

final class _MovementConstructionReferences extends RecursiveAstVisitor<void> {
  _MovementConstructionReferences(this.targetTypes);

  final Set<String> targetTypes;
  int count = 0;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (targetTypes.contains(node.constructorName.type.name.lexeme)) count++;
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target?.toSource();
    if (targetTypes.contains(node.methodName.name) ||
        target != null && _endsWithTargetType(target)) {
      count++;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'new' &&
        targetTypes.contains(node.prefix.name)) {
      count++;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'new' &&
        _endsWithTargetType(node.target?.toSource() ?? '')) {
      count++;
    }
    super.visitPropertyAccess(node);
  }

  bool _endsWithTargetType(String source) =>
      targetTypes.any((type) => source == type || source.endsWith('.$type'));
}

final class _MovementNamedMemberReferences extends RecursiveAstVisitor<void> {
  _MovementNamedMemberReferences(this.memberName);

  final String memberName;
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName) count++;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName) count++;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName) count++;
    super.visitPropertyAccess(node);
  }
}

bool _isTargetType(TypeAnnotation? type, Set<String> targetTypes) =>
    type is NamedType && targetTypes.contains(type.name.lexeme);

bool _isTargetInstance(
  Expression expression, {
  required Set<String> targetTypes,
  required Set<String> bindings,
  required Set<String> factories,
}) {
  return switch (expression) {
    InstanceCreationExpression(:final constructorName) => targetTypes.contains(
      constructorName.type.name.lexeme,
    ),
    SimpleIdentifier(:final name) => bindings.contains(name),
    PrefixedIdentifier(:final identifier) => bindings.contains(identifier.name),
    PropertyAccess(:final propertyName) => bindings.contains(propertyName.name),
    ParenthesizedExpression(:final expression) => _isTargetInstance(
      expression,
      targetTypes: targetTypes,
      bindings: bindings,
      factories: factories,
    ),
    AsExpression(:final type) => _isTargetType(type, targetTypes),
    MethodInvocation(:final methodName) =>
      targetTypes.contains(methodName.name) ||
          factories.contains(methodName.name),
    _ => false,
  };
}

bool _isTargetFactory(
  Expression expression, {
  required Set<String> targetTypes,
  required Set<String> factories,
}) {
  final source = expression.toSource();
  if (targetTypes.any(
    (type) => source == '$type.new' || source.endsWith('.$type.new'),
  )) {
    return true;
  }
  return switch (expression) {
    SimpleIdentifier(:final name) => factories.contains(name),
    PrefixedIdentifier(:final identifier) => factories.contains(
      identifier.name,
    ),
    PropertyAccess(:final propertyName) => factories.contains(
      propertyName.name,
    ),
    ParenthesizedExpression(:final expression) => _isTargetFactory(
      expression,
      targetTypes: targetTypes,
      factories: factories,
    ),
    _ => false,
  };
}
