import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'mutant.dart';

part 'discovery_identity.dart';
part 'wire_string_discovery.dart';

const _wireMutationSuffix = '__mutant';

List<Mutant> discoverMutants({required String path, required String content}) =>
    const MutationDiscoverer().discover(path: path, content: content);

final class MutationDiscoverer {
  const MutationDiscoverer();

  List<Mutant> discover({required String path, required String content}) {
    final normalizedPath = _normalizePath(path);
    final result = parseString(
      content: content,
      path: normalizedPath,
      throwIfDiagnostics: false,
    );
    if (result.errors.isNotEmpty) {
      final diagnostics = result.errors
          .map((diagnostic) => diagnostic.toString())
          .join('\n');
      throw FormatException(
        '$normalizedPath has parser diagnostics:\n$diagnostics',
      );
    }

    final visitor = _MutationVisitor(content);
    result.unit.accept(visitor);
    return _materialize(normalizedPath, visitor.candidates);
  }
}

List<Mutant> _materialize(String path, List<_Candidate> candidates) {
  candidates.sort(_compareCandidates);
  final ordinals = <String, int>{};
  final mutants = <Mutant>[];
  for (final candidate in candidates) {
    final normalizedOriginal = _identityText(candidate, candidate.original);
    final normalizedReplacement = _identityText(
      candidate,
      candidate.replacement,
    );
    final siteIdentity = <String>[
      candidate.declaration,
      candidate.structuralPath,
      candidate.semanticContext,
      candidate.operator,
      normalizedOriginal,
      normalizedReplacement,
    ].join('\u0000');
    final ordinal = (ordinals[siteIdentity] ?? 0) + 1;
    ordinals[siteIdentity] = ordinal;
    final id = <String>[
      'mutation-v1',
      path,
      candidate.declaration,
      candidate.structuralPath,
      candidate.semanticContext,
      candidate.operator,
      normalizedOriginal,
      normalizedReplacement,
      'site-$ordinal',
    ].map(Uri.encodeComponent).join('|');
    mutants.add(
      Mutant(
        id: id,
        path: path,
        operator: candidate.operator,
        declaration: candidate.declaration,
        offset: candidate.offset,
        length: candidate.length,
        original: candidate.original,
        replacement: candidate.replacement,
      ),
    );
  }
  mutants.sort();
  return List.unmodifiable(mutants);
}

final class _MutationVisitor extends RecursiveAstVisitor<void> {
  _MutationVisitor(this.content);

  final String content;
  final List<_Candidate> candidates = [];

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    _record(
      node,
      offset: node.offset,
      length: node.length,
      operator: MutationOperators.booleanLiteral,
      replacement: node.value ? 'false' : 'true',
    );
    super.visitBooleanLiteral(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator;
    final isNullEquality =
        (operator.lexeme == '==' || operator.lexeme == '!=') &&
        (node.leftOperand is NullLiteral || node.rightOperand is NullLiteral);
    final promotionSensitiveConnector =
        (operator.lexeme == '&&' || operator.lexeme == '||') &&
        _containsPromotionTest(node);
    final mutation = switch (operator.lexeme) {
      '==' when !isNullEquality => (MutationOperators.equality, '!='),
      '!=' when !isNullEquality => (MutationOperators.equality, '=='),
      '&&' when !promotionSensitiveConnector => (
        MutationOperators.logical,
        '||',
      ),
      '||' when !promotionSensitiveConnector => (
        MutationOperators.logical,
        '&&',
      ),
      '<' => (MutationOperators.conditionalBoundary, '<='),
      '<=' => (MutationOperators.conditionalBoundary, '<'),
      '>' => (MutationOperators.conditionalBoundary, '>='),
      '>=' => (MutationOperators.conditionalBoundary, '>'),
      _ => null,
    };
    if (mutation case (final operatorId, final replacement)) {
      _record(
        node,
        offset: operator.offset,
        length: operator.length,
        operator: operatorId,
        replacement: replacement,
      );
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (_isControlFlowPromotionTest(node)) {
      super.visitIsExpression(node);
      return;
    }
    final isOperator = node.isOperator;
    final notOperator = node.notOperator;
    if (notOperator == null) {
      _record(
        node,
        offset: isOperator.offset,
        length: isOperator.length,
        operator: MutationOperators.typeCheck,
        replacement: 'is!',
      );
    } else {
      _record(
        node,
        offset: isOperator.offset,
        length: notOperator.end - isOperator.offset,
        operator: MutationOperators.typeCheck,
        replacement: 'is',
      );
    }
    super.visitIsExpression(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    final condition = node.expression;
    if (_isDirectBooleanCondition(condition)) {
      final original = _slice(condition.offset, condition.length);
      _record(
        condition,
        offset: condition.offset,
        length: condition.length,
        operator: MutationOperators.negation,
        replacement: '!($original)',
      );
    }
    super.visitIfStatement(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.lexeme == '!') {
      _record(
        node,
        offset: node.operator.offset,
        length: node.operator.length,
        operator: MutationOperators.negation,
        replacement: '',
      );
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (_isWireString(node)) {
      final original = _slice(node.offset, node.length);
      final insertionOffset = node.contentsEnd - node.offset;
      final replacement = original.replaceRange(
        insertionOffset,
        insertionOffset,
        _wireMutationSuffix,
      );
      _record(
        node,
        offset: node.offset,
        length: node.length,
        operator: MutationOperators.wireString,
        replacement: replacement,
      );
    }
    super.visitSimpleStringLiteral(node);
  }

  void _record(
    AstNode node, {
    required int offset,
    required int length,
    required String operator,
    required String replacement,
  }) {
    final original = _slice(offset, length);
    if (original == replacement) return;
    candidates.add(
      _Candidate(
        declaration: _qualifiedDeclaration(node),
        structuralPath: _structuralPath(node),
        semanticContext: _semanticContext(node),
        operator: operator,
        offset: offset,
        length: length,
        original: original,
        replacement: replacement,
      ),
    );
  }

  String _slice(int offset, int length) {
    final end = offset + length;
    if (offset < 0 || end > content.length) {
      throw StateError(
        'Analyzer returned invalid source span [$offset, $end) for '
        '${content.length} code units.',
      );
    }
    return content.substring(offset, end);
  }
}

bool _isDirectBooleanCondition(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current is SimpleIdentifier ||
      current is PrefixedIdentifier ||
      current is PropertyAccess ||
      current is MethodInvocation ||
      current is FunctionExpressionInvocation;
}

bool _containsPromotionTest(AstNode node) {
  final visitor = _PromotionTestVisitor(node);
  node.accept(visitor);
  return visitor.found;
}

bool _isControlFlowPromotionTest(IsExpression node) {
  for (
    AstNode? current = node.parent;
    current != null;
    current = current.parent
  ) {
    if (current is IfStatement ||
        current is WhileStatement ||
        current is DoStatement ||
        current is ForStatement ||
        current is ConditionalExpression) {
      return true;
    }
    if (current is Statement ||
        current is VariableDeclaration ||
        current is ArgumentList) {
      return false;
    }
  }
  return false;
}

final class _PromotionTestVisitor extends RecursiveAstVisitor<void> {
  _PromotionTestVisitor(this.root);

  final AstNode root;
  bool found = false;

  @override
  void visitIsExpression(IsExpression node) {
    if (!identical(node, root)) found = true;
    if (!found) super.visitIsExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (!identical(node, root) &&
        (node.operator.lexeme == '==' || node.operator.lexeme == '!=') &&
        (node.leftOperand is NullLiteral || node.rightOperand is NullLiteral)) {
      found = true;
    }
    if (!found) super.visitBinaryExpression(node);
  }
}
