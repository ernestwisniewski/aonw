part of '../game_command_contract_test.dart';

/// Collects command types that influence a branch, not lexical references.
final class _DispatchTypeNameCollector extends RecursiveAstVisitor<void> {
  _DispatchTypeNameCollector(this.typeNames);

  final Set<String> typeNames;

  @override
  void visitObjectPattern(ObjectPattern node) {
    typeNames.add(node.type.name.lexeme);
    super.visitObjectPattern(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (node.type case NamedType(:final name)) typeNames.add(name.lexeme);
    super.visitIsExpression(node);
  }
}

final class _ObjectPatternTypeCountCollector extends RecursiveAstVisitor<void> {
  _ObjectPatternTypeCountCollector(this.typeNameCounts);

  final Map<String, int> typeNameCounts;

  @override
  void visitObjectPattern(ObjectPattern node) {
    final name = node.type.name.lexeme;
    typeNameCounts.update(name, (count) => count + 1, ifAbsent: () => 1);
    super.visitObjectPattern(node);
  }
}

final class _ConstructedTypeCountCollector extends RecursiveAstVisitor<void> {
  _ConstructedTypeCountCollector(this.typeNameCounts);

  final Map<String, int> typeNameCounts;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.type.name.lexeme;
    _record(name);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) _record(node.methodName.name);
    super.visitMethodInvocation(node);
  }

  void _record(String name) {
    typeNameCounts.update(name, (count) => count + 1, ifAbsent: () => 1);
  }
}
