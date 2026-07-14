part of 'discoverer.dart';

String _structuralPath(AstNode node) {
  final anchor = _identityContext(node);
  if (identical(anchor, node)) return 'self';
  final segments = <String>[];
  for (AstNode current = node; !identical(current, anchor);) {
    final parent = current.parent;
    if (parent == null) break;
    final children = parent.childEntities.whereType<AstNode>().toList();
    final index = children.indexWhere((child) => identical(child, current));
    if (index < 0) {
      throw StateError('AST child is missing from its parent.');
    }
    segments.add('${parent.runtimeType}:$index');
    current = parent;
  }
  return segments.reversed.join('/');
}

String _semanticContext(AstNode node) {
  final context = _identityContext(node);
  final lexemes = <String>[];
  for (var token = context.beginToken; ; token = token.next!) {
    lexemes.add(token.lexeme);
    if (identical(token, context.endToken)) break;
    if (token.next == null) {
      throw StateError('AST context has an unterminated token range.');
    }
  }
  return lexemes.join('\u001f');
}

AstNode _identityContext(AstNode node) {
  AstNode? declarationContext;
  for (
    AstNode? current = node.parent;
    current != null;
    current = current.parent
  ) {
    if (current is MapLiteralEntry ||
        current is SwitchExpressionCase ||
        current is DefaultFormalParameter ||
        current is ConstructorInitializer) {
      return current;
    }
    if (current is Statement ||
        current is VariableDeclaration ||
        current is ExpressionFunctionBody) {
      return current;
    }
    if (declarationContext == null && _isDeclarationIdentityContext(current)) {
      declarationContext = current;
    }
    if (current is CompilationUnit) return declarationContext ?? current;
  }
  return declarationContext ?? node;
}

bool _isDeclarationIdentityContext(AstNode node) =>
    node is VariableDeclaration ||
    node is EnumConstantDeclaration ||
    node is ConstructorDeclaration ||
    node is MethodDeclaration ||
    node is FunctionDeclaration ||
    node is ClassDeclaration ||
    node is EnumDeclaration ||
    node is MixinDeclaration ||
    node is ExtensionDeclaration ||
    node is ExtensionTypeDeclaration;

String _qualifiedDeclaration(AstNode node) {
  final segments = <String>[];
  for (AstNode? current = node; current != null; current = current.parent) {
    final segment = switch (current) {
      final ClassDeclaration declaration =>
        'class:${declaration.namePart.typeName.lexeme}',
      final EnumDeclaration declaration =>
        'enum:${declaration.namePart.typeName.lexeme}',
      final MixinDeclaration declaration => 'mixin:${declaration.name.lexeme}',
      final ExtensionDeclaration declaration =>
        'extension:${declaration.name?.lexeme ?? _anonymousExtensionName(declaration)}',
      final ExtensionTypeDeclaration declaration =>
        'extension_type:${declaration.primaryConstructor.typeName.lexeme}',
      final ConstructorDeclaration declaration =>
        'constructor:${declaration.name?.lexeme ?? '<unnamed>'}',
      final MethodDeclaration declaration =>
        '${_methodKind(declaration)}:${declaration.name.lexeme}',
      final FunctionDeclaration declaration =>
        '${_functionKind(declaration)}:${declaration.name.lexeme}',
      final EnumConstantDeclaration declaration =>
        'enum_constant:${declaration.name.lexeme}',
      final VariableDeclaration declaration =>
        'variable:${declaration.name.lexeme}',
      _ => null,
    };
    if (segment != null) segments.add(segment);
  }
  return segments.isEmpty ? '<unit>' : segments.reversed.join('/');
}

String _anonymousExtensionName(ExtensionDeclaration declaration) {
  final unit = declaration.thisOrAncestorOfType<CompilationUnit>();
  if (unit == null) return '<anonymous#1>';
  var ordinal = 0;
  for (final candidate in unit.declarations.whereType<ExtensionDeclaration>()) {
    if (candidate.name != null) continue;
    ordinal += 1;
    if (identical(candidate, declaration)) return '<anonymous#$ordinal>';
  }
  return '<anonymous#1>';
}

String _methodKind(MethodDeclaration declaration) {
  if (declaration.isGetter) return 'getter';
  if (declaration.isSetter) return 'setter';
  if (declaration.isOperator) return 'operator';
  return 'method';
}

String _functionKind(FunctionDeclaration declaration) {
  if (declaration.isGetter) return 'getter';
  if (declaration.isSetter) return 'setter';
  return 'function';
}

String _normalizePath(String path) {
  var result = path.replaceAll('\\', '/');
  while (result.startsWith('./')) {
    result = result.substring(2);
  }
  if (result.isEmpty) throw ArgumentError.value(path, 'path', 'is empty');
  return result;
}

String _identityText(_Candidate candidate, String value) =>
    candidate.operator == MutationOperators.wireString
    ? value
    : value.replaceAll(RegExp(r'\s+'), '');

int _compareCandidates(_Candidate left, _Candidate right) {
  var result = left.offset.compareTo(right.offset);
  if (result != 0) return result;
  result = left.length.compareTo(right.length);
  if (result != 0) return result;
  result = left.operator.compareTo(right.operator);
  if (result != 0) return result;
  result = left.original.compareTo(right.original);
  if (result != 0) return result;
  return left.replacement.compareTo(right.replacement);
}

final class _Candidate {
  const _Candidate({
    required this.declaration,
    required this.structuralPath,
    required this.semanticContext,
    required this.operator,
    required this.offset,
    required this.length,
    required this.original,
    required this.replacement,
  });

  final String declaration;
  final String structuralPath;
  final String semanticContext;
  final String operator;
  final int offset;
  final int length;
  final String original;
  final String replacement;
}
