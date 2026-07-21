part of '../timeout_actor_integration_test.dart';

MethodDeclaration? _singleMethod(CompilationUnit unit, String name) {
  final collector = _MethodCollector(name)..collect(unit);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

List<MethodInvocation> _methodInvocations(AstNode node, String name) {
  final collector = _InvocationCollector(name)..collect(node);
  return collector.invocations;
}

List<IfStatement> _ifStatements(AstNode node) {
  final collector = _IfStatementCollector()..collect(node);
  return collector.statements;
}

List<AstNode> _targetMemberReferences(
  AstNode node, {
  required String target,
  required String member,
}) {
  final collector = _TargetMemberReferenceCollector(
    target: target,
    member: member,
  )..collect(node);
  return collector.references;
}

Expression? _singleVariableInitializer(AstNode node, String name) {
  return _singleVariable(node, name)?.initializer;
}

VariableDeclaration? _singleVariable(AstNode node, String name) {
  final collector = _VariableCollector(name)..collect(node);
  return collector.variables.length == 1 ? collector.variables.single : null;
}

String? _namedArgumentSource(ArgumentList arguments, String name) {
  final matches = _namedArguments(arguments, name);
  return matches.length == 1 ? matches.single.expression.toSource() : null;
}

List<NamedExpression> _namedArguments(ArgumentList arguments, String name) =>
    arguments.arguments
        .whereType<NamedExpression>()
        .where((argument) => argument.name.label.name == name)
        .toList();

bool _hasExactRequiredNamedParameters(
  MethodDeclaration method,
  Map<String, String> expected,
) {
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != expected.length) return false;
  return expected.entries.every(
    (entry) => _hasRequiredNamedParameter(method, entry.key, entry.value),
  );
}

bool _hasRequiredNamedParameter(
  MethodDeclaration method,
  String name,
  String type,
) => _matchingParameter(method, name, type, required: true);

bool _hasParameterNamed(MethodDeclaration method, String name) =>
    method.parameters?.parameters.any(
      (parameter) => parameter.name?.lexeme == name,
    ) ??
    false;

bool _matchingParameter(
  MethodDeclaration method,
  String name,
  String type, {
  required bool required,
}) {
  final matches = <DefaultFormalParameter>[];
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) continue;
    final normalized = parameter.parameter;
    if (normalized.name?.lexeme == name) matches.add(parameter);
  }
  if (matches.length != 1) return false;
  final normalized = matches.single.parameter;
  final actualType = normalized is SimpleFormalParameter
      ? normalized.type?.toSource()
      : null;
  return actualType == type && (normalized.requiredKeyword != null) == required;
}

bool _isImmediateReturnGuard(IfStatement statement) {
  final thenStatement = statement.thenStatement;
  if (thenStatement is ReturnStatement) return true;
  return thenStatement is Block &&
      thenStatement.statements.length == 1 &&
      thenStatement.statements.single is ReturnStatement;
}

final class _MethodCollector extends RecursiveAstVisitor<void> {
  _MethodCollector(this.name);

  final String name;
  final List<MethodDeclaration> methods = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }
}

final class _InvocationCollector extends RecursiveAstVisitor<void> {
  _InvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> invocations = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _IfStatementCollector extends RecursiveAstVisitor<void> {
  final List<IfStatement> statements = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitIfStatement(IfStatement node) {
    statements.add(node);
    super.visitIfStatement(node);
  }
}

final class _TargetMemberReferenceCollector extends RecursiveAstVisitor<void> {
  _TargetMemberReferenceCollector({required this.target, required this.member});

  final String target;
  final String member;
  final List<AstNode> references = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target?.toSource() == target && node.methodName.name == member) {
      references.add(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.toSource() == target && node.identifier.name == member) {
      references.add(node);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target?.toSource() == target && node.propertyName.name == member) {
      references.add(node);
    }
    super.visitPropertyAccess(node);
  }
}

final class _VariableCollector extends RecursiveAstVisitor<void> {
  _VariableCollector(this.name);

  final String name;
  final List<VariableDeclaration> variables = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) variables.add(node);
    super.visitVariableDeclaration(node);
  }
}

final class _ReturnCollector extends RecursiveAstVisitor<void> {
  final List<ReturnStatement> statements = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitReturnStatement(ReturnStatement node) {
    statements.add(node);
    super.visitReturnStatement(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
