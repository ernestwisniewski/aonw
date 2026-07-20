part of '../game_outcome_boundary_test.dart';

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  void collect(AstNode node) => node.accept(this);

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

final class _NamedMethodCollector extends RecursiveAstVisitor<void> {
  _NamedMethodCollector(this.name);

  final String name;
  final List<MethodDeclaration> methods = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }
}

final class _NamedVariableCollector extends RecursiveAstVisitor<void> {
  _NamedVariableCollector(this.name);

  final String name;
  final List<VariableDeclaration> variables = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitVariableDeclaration(node);
  }
}

final class _SymbolReferenceCollector extends RecursiveAstVisitor<void> {
  _SymbolReferenceCollector(this.name);

  final String name;
  final List<SimpleIdentifier> references = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && node.parent is! Label) references.add(node);
    super.visitSimpleIdentifier(node);
  }
}

final class _NamedArgumentCollector extends RecursiveAstVisitor<void> {
  _NamedArgumentCollector(this.name);

  final String name;
  final List<NamedExpression> arguments = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.label.name == name) arguments.add(node);
    super.visitNamedExpression(node);
  }
}

final class _NamedDeclarationCollector extends RecursiveAstVisitor<void> {
  _NamedDeclarationCollector(this.name);

  final String name;
  final List<FunctionDeclaration> functions = [];
  final List<MethodDeclaration> methods = [];
  final List<AstNode> variables = [];
  final List<FormalParameter> parameters = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == name) functions.add(node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (final parameter in node.parameters) {
      final normalized = parameter is DefaultFormalParameter
          ? parameter.parameter
          : parameter;
      if (normalized.name?.lexeme == name) parameters.add(normalized);
    }
    super.visitFormalParameterList(node);
  }
}

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
