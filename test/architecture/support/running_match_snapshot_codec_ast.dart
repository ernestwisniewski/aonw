part of '../running_match_snapshot_codec_boundary_test.dart';

final class _MethodInvocationCollector extends RecursiveAstVisitor<void> {
  _MethodInvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> invocations = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _ConstructionReference {
  const _ConstructionReference({required this.node, required this.arguments});

  final AstNode node;
  final ArgumentList arguments;
}

final class _ConstructionCollector extends RecursiveAstVisitor<void> {
  _ConstructionCollector(this.type);

  final String type;
  final List<_ConstructionReference> references = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == type) {
      references.add(
        _ConstructionReference(node: node, arguments: node.argumentList),
      );
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target?.toSource();
    final isUnnamed = target == null && node.methodName.name == type;
    final isNamed = target == type;
    if (isUnnamed || isNamed) {
      references.add(
        _ConstructionReference(node: node, arguments: node.argumentList),
      );
    }
    super.visitMethodInvocation(node);
  }
}

final class _PhaseHeuristicCollector extends RecursiveAstVisitor<void> {
  bool found = false;

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'phase') found = true;
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.value == 'phase') found = true;
    super.visitSimpleStringLiteral(node);
  }
}

final class _CanonicalReferenceCollector extends RecursiveAstVisitor<void> {
  bool found = false;

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name.toLowerCase().contains('canonical')) found = true;
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme.toLowerCase().contains('canonical')) found = true;
    super.visitNamedType(node);
  }
}

final class _ConversionReferenceCollector extends RecursiveAstVisitor<void> {
  bool found = false;

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'toLegacy' || node.name == 'toCanonical') found = true;
    super.visitSimpleIdentifier(node);
  }
}
