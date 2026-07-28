import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _benchmarkPath = 'tool/run_save_ai_benchmark.dart';
const _reportModelsPath = 'tool/run_save_ai_benchmark/report_models.dart';
const _runtimeSmokePath = 'tool/run_save_ai_benchmark/runtime_smoke.dart';

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

  test('benchmark report models use canonical snapshot state', () {
    final unit = _unitAt(_reportModelsPath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'runtimeState'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
    expect(_propertyReadCount(unit, 'persistedPlayers'), greaterThan(0));
  });

  test('runtime smoke setup uses canonical snapshot state', () {
    final runMethod = _methodAt(
      _unitAt(_runtimeSmokePath),
      className: '_RuntimeUseCaseSmokeRunner',
      methodName: 'run',
    );

    expect(_propertyReadCount(runMethod, 'save'), 0);
    expect(_propertyReadCount(runMethod, 'persistentState'), 0);
    expect(_propertyReadCount(runMethod, 'runtimeState'), 0);
    expect(_propertyReadCount(runMethod, 'domain'), greaterThan(0));
    expect(_propertyReadCount(runMethod, 'metadata'), greaterThan(0));
  });
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

MethodDeclaration _methodAt(
  CompilationUnit unit, {
  required String className,
  required String methodName,
}) {
  final declaration = unit.declarations
      .whereType<ClassDeclaration>()
      .singleWhere(
        (declaration) => declaration.namePart.typeName.lexeme == className,
      );
  return declaration.body.members.whereType<MethodDeclaration>().singleWhere(
    (declaration) => declaration.name.lexeme == methodName,
  );
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
