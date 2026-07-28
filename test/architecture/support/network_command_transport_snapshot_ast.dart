part of '../network_command_transport_snapshot_boundary_test.dart';

ClassDeclaration? _classNamed(CompilationUnit unit, String name) {
  return unit.declarations
      .whereType<ClassDeclaration>()
      .where((declaration) => declaration.namePart.typeName.lexeme == name)
      .singleOrNull;
}

MethodDeclaration? _methodNamed(ClassDeclaration owner, String name) {
  return owner.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == name)
      .singleOrNull;
}

FormalParameter _normalizedParameter(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

bool _isOptionalNamedFalse(FormalParameter parameter) {
  final defaultValue = parameter is DefaultFormalParameter
      ? parameter.defaultValue
      : null;
  return parameter is DefaultFormalParameter &&
      parameter.isNamed &&
      !parameter.isRequiredNamed &&
      defaultValue is BooleanLiteral &&
      !defaultValue.value;
}

final class _ResultConstruction {
  const _ResultConstruction({required this.node, required this.arguments});

  final AstNode node;
  final ArgumentList arguments;
}

final class _ResultConstructionCollector extends RecursiveAstVisitor<void> {
  _ResultConstructionCollector(this.type);

  final String type;
  final List<_ResultConstruction> nodes = [];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == type) {
      nodes.add(_ResultConstruction(node: node, arguments: node.argumentList));
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == type) {
      nodes.add(_ResultConstruction(node: node, arguments: node.argumentList));
    }
    super.visitMethodInvocation(node);
  }
}

final class _MethodInvocationCollector extends RecursiveAstVisitor<void> {
  _MethodInvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> nodes = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) nodes.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _NamedReferenceCollector extends RecursiveAstVisitor<void> {
  _NamedReferenceCollector(this.name);

  final String name;
  final List<SimpleIdentifier> nodes = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) nodes.add(node);
    super.visitSimpleIdentifier(node);
  }
}
