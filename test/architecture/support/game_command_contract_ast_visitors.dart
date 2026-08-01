part of '../game_command_contract_test.dart';

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.identifiers);

  final Set<String> identifiers;

  @override
  void visitNamedType(NamedType node) {
    identifiers.add(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

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
