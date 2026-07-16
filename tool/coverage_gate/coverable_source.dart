import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Retains only source paths that contain coverable code.
///
/// Export-only barrels, pure abstract interfaces, and compile-time constant
/// holders have no executable lines, so LCOV never records them. They are not
/// missing coverage; they have nothing to instrument. A path already present
/// in [recorded] is coverable by definition and is kept without parsing.
Set<String> retainCoverable(
  Iterable<String> paths, {
  required Set<String> recorded,
  required String Function(String path) resolve,
}) {
  return paths
      .where(
        (path) => recorded.contains(path) || hasCoverableCode(resolve(path)),
      )
      .toSet();
}

/// Whether the Dart source at [absolutePath] contains any instrumentable code.
bool hasCoverableCode(String absolutePath) {
  final unit = parseString(
    content: File(absolutePath).readAsStringSync(),
    path: absolutePath,
  ).unit;
  final visitor = _CoverableCodeVisitor();
  unit.accept(visitor);
  return visitor.hasCoverableCode;
}

final class _CoverableCodeVisitor extends RecursiveAstVisitor<void> {
  bool hasCoverableCode = false;

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) => _flag();

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) => _flag();

  @override
  void visitEnumDeclaration(EnumDeclaration node) => _flag();

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      _flag();

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.factoryKeyword != null || node.redirectedConstructor != null) {
      _flag();
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.initializer != null && !node.isConst) {
      _flag();
    }
    super.visitVariableDeclaration(node);
  }

  void _flag() => hasCoverableCode = true;
}
