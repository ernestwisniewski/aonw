part of '../participant_resignation_integration_test.dart';

MethodDeclaration? _runningResignationMethod(CompilationUnit unit) {
  return _methodNamed(unit, '_runningStateAfterParticipantResigned');
}

MethodDeclaration? _methodNamed(CompilationUnit unit, String name) {
  final collector = _MethodCollector(name)..collect(unit);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

List<MethodInvocation> _methodInvocations(AstNode node, String name) {
  final collector = _InvocationCollector(name)..collect(node);
  return collector.invocations;
}

Expression? _variableInitializer(AstNode node, String name) {
  final collector = _VariableCollector(name)..collect(node);
  return collector.variables.length == 1
      ? collector.variables.single.initializer
      : null;
}

Map<String, String> _namedArguments(ArgumentList arguments) => {
  for (final argument in arguments.arguments.whereType<NamedExpression>())
    argument.name.label.name: argument.expression.toSource(),
};

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      right.entries.every((entry) => left[entry.key] == entry.value);
}

Expression? _namedExpression(ArgumentList arguments, String name) {
  final matches = arguments.arguments.whereType<NamedExpression>().where(
    (argument) => argument.name.label.name == name,
  );
  return matches.length == 1 ? matches.single.expression : null;
}

int _targetMemberReferenceCount(
  AstNode node, {
  required String target,
  required String member,
}) {
  final collector = _TargetMemberCollector(target: target, member: member)
    ..collect(node);
  return collector.count;
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

final class _TargetMemberCollector extends RecursiveAstVisitor<void> {
  _TargetMemberCollector({required this.target, required this.member});

  final String target;
  final String member;
  int count = 0;

  void collect(AstNode node) => node.accept(this);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.toSource() == target && node.identifier.name == member) {
      count++;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target?.toSource() == target && node.propertyName.name == member) {
      count++;
    }
    super.visitPropertyAccess(node);
  }
}
