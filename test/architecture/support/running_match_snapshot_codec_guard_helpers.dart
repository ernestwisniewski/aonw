part of '../running_match_snapshot_codec_boundary_test.dart';

FieldDeclaration? _singleField(ClassDeclaration? declaration, String name) {
  if (declaration == null) return null;
  final fields = declaration.body.members.whereType<FieldDeclaration>().where(
    (field) =>
        field.fields.variables.any((variable) => variable.name.lexeme == name),
  );
  if (fields.length != 1 || fields.single.fields.variables.length != 1) {
    return null;
  }
  return fields.single;
}

ClassDeclaration? _singleClass(CompilationUnit unit, String name) {
  final declarations = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
  return declarations.length == 1 ? declarations.single : null;
}

MethodDeclaration? _singleMethod(ClassDeclaration? declaration, String name) {
  if (declaration == null) return null;
  final methods = declaration.body.members.whereType<MethodDeclaration>().where(
    (method) => method.name.lexeme == name && !method.isStatic,
  );
  return methods.length == 1 ? methods.single : null;
}

List<MethodInvocation> _targetedInvocations(
  AstNode node, {
  required String target,
  required String method,
}) {
  return _methodInvocations(
    node,
    method,
  ).where((call) => call.target?.toSource() == target).toList();
}

List<MethodInvocation> _methodInvocations(AstNode node, String name) {
  final collector = _MethodInvocationCollector(name)..collect(node);
  return collector.invocations;
}

List<_ConstructionReference> _constructions(AstNode node, String type) {
  final collector = _ConstructionCollector(type)..collect(node);
  return collector.references;
}

bool _hasSingleArgument(List<MethodInvocation> calls, String expected) {
  return calls.length == 1 &&
      calls.single.argumentList.arguments.length == 1 &&
      calls.single.argumentList.arguments.single.toSource() == expected;
}

Expression? _lastReturnedExpression(FunctionBody body) {
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is! BlockFunctionBody || body.block.statements.isEmpty) return null;
  final statement = body.block.statements.last;
  return statement is ReturnStatement ? statement.expression : null;
}

Map<String, String> _namedArgumentSources(ArgumentList arguments) {
  return {
    for (final argument in arguments.arguments.whereType<NamedExpression>())
      argument.name.label.name: argument.expression.toSource(),
  };
}

bool _sameStringMap(Map<String, String> actual, Map<String, String> expected) {
  if (actual.length != expected.length) return false;
  return expected.entries.every((entry) => actual[entry.key] == entry.value);
}
