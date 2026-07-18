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
) => staticMemberReferenceCountsByPath(
  sources,
  targetType,
  memberName,
).keys.toSet();

/// Counts static-member references per source file.
///
/// Unlike [staticMemberReferencePaths], this also guards against duplicate
/// calls being hidden inside an already-allowed file.
Map<String, int> staticMemberReferenceCountsByPath(
  Map<String, String> sources,
  String targetType,
  String memberName,
) {
  final counts = <String, int>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _StaticMemberReferenceCollector(targetTypes, memberName);
    unit.accept(collector);
    if (collector.count > 0) counts[entry.key] = collector.count;
  }
  return counts;
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
) => instanceMemberReferenceCountsByPath(
  sources,
  targetType,
  memberName,
).keys.toSet();

/// Counts instance-member references per source file.
///
/// This makes exact call-site ratchets sensitive to a second invocation added
/// to a file that is already on the allowlist.
Map<String, int> instanceMemberReferenceCountsByPath(
  Map<String, String> sources,
  String targetType,
  String memberName,
) {
  final counts = <String, int>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final bindings = _TargetInstanceBindingCollector(targetTypes);
    unit.accept(bindings);
    bindings.inferInitializedBindings();

    final references = _InstanceMemberReferenceCollector(
      targetTypes: targetTypes,
      targetBindings: bindings.targetBindings,
      targetFactories: bindings.targetFactories,
      memberName: memberName,
    );
    unit.accept(references);
    if (references.count > 0) counts[entry.key] = references.count;
  }
  return counts;
}

final class _StaticMemberReferenceCollector extends RecursiveAstVisitor<void> {
  _StaticMemberReferenceCollector(this.targetTypes, this.memberName);

  final Set<String> targetTypes;
  final String memberName;
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName && _isTarget(node.target)) {
      count++;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName && _isTarget(node.prefix)) {
      count++;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName && _isTarget(node.target)) {
      count++;
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
  final Set<String> targetFactories = {};
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
      (node.isGetter ? targetBindings : targetFactories).add(node.name.lexeme);
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isTargetType(node.returnType, targetTypes)) {
      (node.isGetter ? targetBindings : targetFactories).add(node.name.lexeme);
    }
    super.visitMethodDeclaration(node);
  }

  void inferInitializedBindings() {
    var changed = true;
    while (changed) {
      changed = false;
      for (final variable in _inferredVariables) {
        final initializer = variable.initializer;
        if (initializer == null) continue;
        if (_isTargetFactoryExpression(
              initializer,
              targetTypes: targetTypes,
              targetFactories: targetFactories,
            ) &&
            targetFactories.add(variable.name.lexeme)) {
          changed = true;
          continue;
        }
        if (_isTargetExpression(
              initializer,
              targetTypes: targetTypes,
              targetBindings: targetBindings,
              targetFactories: targetFactories,
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
    required this.targetFactories,
    required this.memberName,
  });

  final Set<String> targetTypes;
  final Set<String> targetBindings;
  final Set<String> targetFactories;
  final String memberName;
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName && _isTarget(node.target)) {
      count++;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName && _isTarget(node.prefix)) {
      count++;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName && _isTarget(node.target)) {
      count++;
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
      count += members.count;
    }
    super.visitCascadeExpression(node);
  }

  bool _isTarget(Expression? target) {
    return target != null &&
        _isTargetExpression(
          target,
          targetTypes: targetTypes,
          targetBindings: targetBindings,
          targetFactories: targetFactories,
        );
  }
}

final class _NamedMemberCollector extends RecursiveAstVisitor<void> {
  _NamedMemberCollector(this.memberName);

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

bool _isTargetType(TypeAnnotation? type, Set<String> targetTypes) {
  return type is NamedType && targetTypes.contains(type.name.lexeme);
}

bool _isTargetExpression(
  Expression expression, {
  required Set<String> targetTypes,
  required Set<String> targetBindings,
  required Set<String> targetFactories,
}) {
  return switch (expression) {
    InstanceCreationExpression(:final constructorName) => targetTypes.contains(
      constructorName.type.name.lexeme,
    ),
    SimpleIdentifier(:final name) => targetBindings.contains(name),
    PrefixedIdentifier(:final identifier) => targetBindings.contains(
      identifier.name,
    ),
    PropertyAccess(:final propertyName) => targetBindings.contains(
      propertyName.name,
    ),
    ParenthesizedExpression(:final expression) => _isTargetExpression(
      expression,
      targetTypes: targetTypes,
      targetBindings: targetBindings,
      targetFactories: targetFactories,
    ),
    AsExpression(:final type) => _isTargetType(type, targetTypes),
    MethodInvocation(:final methodName) => targetFactories.contains(
      methodName.name,
    ),
    _ => false,
  };
}

bool _isTargetFactoryExpression(
  Expression expression, {
  required Set<String> targetTypes,
  required Set<String> targetFactories,
}) {
  final source = expression.toSource();
  final constructorTearOff = targetTypes.any(
    (type) => source == '$type.new' || source.endsWith('.$type.new'),
  );
  if (constructorTearOff) return true;
  return switch (expression) {
    SimpleIdentifier(:final name) => targetFactories.contains(name),
    PrefixedIdentifier(:final identifier) => targetFactories.contains(
      identifier.name,
    ),
    PropertyAccess(:final propertyName) => targetFactories.contains(
      propertyName.name,
    ),
    ParenthesizedExpression(:final expression) => _isTargetFactoryExpression(
      expression,
      targetTypes: targetTypes,
      targetFactories: targetFactories,
    ),
    _ => false,
  };
}
