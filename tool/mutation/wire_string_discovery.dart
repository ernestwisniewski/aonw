part of 'discoverer.dart';

bool _isWireString(SimpleStringLiteral node) {
  final parent = node.parent;
  if (parent is MapLiteralEntry) {
    if (identical(parent.key, node)) return true;
    if (identical(parent.value, node)) {
      final key = parent.key;
      if (key is SimpleStringLiteral) return key.value == 'type';
    }
  }
  if (parent is IndexExpression && identical(parent.index, node)) return true;
  if (_isTypeDiscriminatorSwitchResult(node)) return true;
  if (parent is ConstantPattern && identical(parent.expression, node)) {
    return true;
  }
  if (parent is SwitchCase && identical(parent.expression, node)) return true;
  return _isRequiredFieldArgument(node);
}

bool _isTypeDiscriminatorSwitchResult(SimpleStringLiteral node) {
  final switchCase = node.parent;
  if (switchCase is! SwitchExpressionCase ||
      !identical(switchCase.expression, node)) {
    return false;
  }
  AstNode expression = switchCase.parent!;
  if (expression is! SwitchExpression) return false;
  while (expression.parent is ParenthesizedExpression) {
    final parent = expression.parent! as ParenthesizedExpression;
    if (!identical(parent.expression, expression)) return false;
    expression = parent;
  }
  final entry = expression.parent;
  return entry is MapLiteralEntry &&
      identical(entry.value, expression) &&
      entry.key is SimpleStringLiteral &&
      (entry.key as SimpleStringLiteral).value == 'type';
}

bool _isRequiredFieldArgument(SimpleStringLiteral node) {
  AstNode argument = node;
  if (node.parent case final NamedExpression named) argument = named;
  final parent = argument.parent;
  if (parent is! ArgumentList ||
      parent.arguments.isEmpty ||
      !identical(parent.arguments.last, argument)) {
    return false;
  }
  final invocation = parent.parent;
  final name = switch (invocation) {
    final MethodInvocation method => method.methodName.name,
    FunctionExpressionInvocation(function: final SimpleIdentifier identifier) =>
      identifier.name,
    _ => null,
  };
  if (name == null) return false;
  return RegExp(r'^required[A-Za-z0-9_]*Field$').hasMatch(name);
}
