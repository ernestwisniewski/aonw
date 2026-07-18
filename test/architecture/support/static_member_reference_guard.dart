import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'map_boundary_source_guard.dart';

/// Finds source files that reference a static member on [targetType],
/// including import prefixes, typedef aliases, calls, and tear-offs.
Set<String> staticMemberReferencePaths(
  Map<String, String> sources,
  String targetType,
  String memberName,
) {
  final paths = <String>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _StaticMemberReferenceCollector(targetTypes, memberName);
    unit.accept(collector);
    if (collector.found) paths.add(entry.key);
  }
  return paths;
}

/// Finds source files that reference an instance member on [targetType].
///
/// This deliberately handles the call shapes that a static-member scan cannot:
/// a freshly constructed receiver, typed fields/parameters/locals, inferred
/// locals initialized from the target type, getters/functions returning the
/// target type, cascades, and member tear-offs.
Set<String> instanceMemberReferencePaths(
  Map<String, String> sources,
  String targetType,
  String memberName,
) {
  final paths = <String>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final bindings = _TargetInstanceBindingCollector(targetTypes);
    unit.accept(bindings);
    bindings.inferInitializedBindings();

    final references = _InstanceMemberReferenceCollector(
      targetTypes: targetTypes,
      targetBindings: bindings.targetBindings,
      targetProducers: bindings.targetProducers,
      memberName: memberName,
    );
    unit.accept(references);
    if (references.found) paths.add(entry.key);
  }
  return paths;
}

final class _StaticMemberReferenceCollector extends RecursiveAstVisitor<void> {
  _StaticMemberReferenceCollector(this.targetTypes, this.memberName);

  final Set<String> targetTypes;
  final String memberName;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName && _isTarget(node.target)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName && _isTarget(node.prefix)) {
      found = true;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName && _isTarget(node.target)) {
      found = true;
    }
    super.visitPropertyAccess(node);
  }

  bool _isTarget(AstNode? target) {
    final source = target?.toSource();
    if (source == null) return false;
    return targetTypes.any(
      (type) => source == type || source.endsWith('.$type'),
    );
  }
}

final class _TargetInstanceBindingCollector extends RecursiveAstVisitor<void> {
  _TargetInstanceBindingCollector(this.targetTypes);

  final Set<String> targetTypes;
  final Set<String> targetBindings = {};
  final Set<String> targetProducers = {};
  final List<VariableDeclaration> _inferredVariables = [];

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (_isTargetType(node.type, targetTypes)) {
      targetBindings.addAll(
        node.variables.map((variable) => variable.name.lexeme),
      );
    } else {
      _inferredVariables.addAll(node.variables);
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (_isTargetType(node.type, targetTypes)) {
      final name = node.name?.lexeme;
      if (name != null) targetBindings.add(name);
    }
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (_isTargetType(node.type, targetTypes)) {
      targetBindings.add(node.name.lexeme);
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isTargetType(node.returnType, targetTypes)) {
      targetProducers.add(node.name.lexeme);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isTargetType(node.returnType, targetTypes)) {
      targetProducers.add(node.name.lexeme);
    }
    super.visitMethodDeclaration(node);
  }

  void inferInitializedBindings() {
    var changed = true;
    while (changed) {
      changed = false;
      for (final variable in _inferredVariables) {
        final initializer = variable.initializer;
        if (initializer != null &&
            _isTargetExpression(
              initializer,
              targetTypes: targetTypes,
              targetBindings: targetBindings,
              targetProducers: targetProducers,
            ) &&
            targetBindings.add(variable.name.lexeme)) {
          changed = true;
        }
      }
    }
  }
}

final class _InstanceMemberReferenceCollector
    extends RecursiveAstVisitor<void> {
  _InstanceMemberReferenceCollector({
    required this.targetTypes,
    required this.targetBindings,
    required this.targetProducers,
    required this.memberName,
  });

  final Set<String> targetTypes;
  final Set<String> targetBindings;
  final Set<String> targetProducers;
  final String memberName;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName && _isTarget(node.target)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName && _isTarget(node.prefix)) {
      found = true;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName && _isTarget(node.target)) {
      found = true;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    if (_isTarget(node.target)) {
      final members = _NamedMemberCollector(memberName);
      for (final section in node.cascadeSections) {
        section.accept(members);
      }
      if (members.found) found = true;
    }
    super.visitCascadeExpression(node);
  }

  bool _isTarget(Expression? target) {
    return target != null &&
        _isTargetExpression(
          target,
          targetTypes: targetTypes,
          targetBindings: targetBindings,
          targetProducers: targetProducers,
        );
  }
}

final class _NamedMemberCollector extends RecursiveAstVisitor<void> {
  _NamedMemberCollector(this.memberName);

  final String memberName;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName) found = true;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName) found = true;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName) found = true;
    super.visitPropertyAccess(node);
  }
}

bool _isTargetType(TypeAnnotation? type, Set<String> targetTypes) {
  return type is NamedType && targetTypes.contains(type.name.lexeme);
}

bool _isTargetExpression(
  Expression expression, {
  required Set<String> targetTypes,
  required Set<String> targetBindings,
  required Set<String> targetProducers,
}) {
  return switch (expression) {
    InstanceCreationExpression(:final constructorName) => targetTypes.contains(
      constructorName.type.name.lexeme,
    ),
    SimpleIdentifier(:final name) =>
      targetBindings.contains(name) || targetProducers.contains(name),
    PrefixedIdentifier(:final identifier) =>
      targetBindings.contains(identifier.name) ||
          targetProducers.contains(identifier.name),
    PropertyAccess(:final propertyName) =>
      targetBindings.contains(propertyName.name) ||
          targetProducers.contains(propertyName.name),
    ParenthesizedExpression(:final expression) => _isTargetExpression(
      expression,
      targetTypes: targetTypes,
      targetBindings: targetBindings,
      targetProducers: targetProducers,
    ),
    AsExpression(:final type) => _isTargetType(type, targetTypes),
    MethodInvocation(:final methodName) => targetProducers.contains(
      methodName.name,
    ),
    _ => false,
  };
}
