import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _benchmarkPath = 'tool/run_save_ai_benchmark.dart';

void main() {
  test('save AI benchmark preparation uses canonical snapshot state', () {
    final unit = parseString(
      content: File(_benchmarkPath).readAsStringSync(),
      path: _benchmarkPath,
    ).unit;

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'runtimeState'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
  });
}

int _propertyReadCount(AstNode node, String propertyName) {
  final collector = _PropertyReadCollector(propertyName);
  node.accept(collector);
  return collector.count;
}

final class _PropertyReadCollector extends RecursiveAstVisitor<void> {
  _PropertyReadCollector(this.propertyName);

  final String propertyName;
  var count = 0;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != propertyName) {
      super.visitSimpleIdentifier(node);
      return;
    }
    final parent = node.parent;
    if (parent is PrefixedIdentifier && identical(parent.identifier, node) ||
        parent is PropertyAccess && identical(parent.propertyName, node)) {
      count += 1;
    }
    super.visitSimpleIdentifier(node);
  }
}
