import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

const productionDartRoots = [
  'lib',
  'packages/aonw_core/lib',
  'server/bin',
  'server/lib',
  'tool',
  'packages/aonw_core/tool',
];

List<String> scanRuntimeLegacyConstructors(Set<String> typeNames) {
  final violations = <String>[];
  for (final root in productionDartRoots) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      violations.addAll(
        runtimeLegacyConstructorViolations(
          entity.readAsStringSync(),
          path,
          typeNames,
        ),
      );
    }
  }
  return violations;
}

List<String> runtimeLegacyConstructorViolations(
  String source,
  String path,
  Set<String> typeNames,
) {
  final visitor = _RuntimeLegacyConstructorVisitor(path, typeNames);
  parseString(content: source, path: path).unit.accept(visitor);
  return visitor.violations.toList();
}

final class _RuntimeLegacyConstructorVisitor extends RecursiveAstVisitor<void> {
  _RuntimeLegacyConstructorVisitor(this.path, this.typeNames);

  final String path;
  final Set<String> typeNames;
  final Set<String> violations = {};

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    final aliasedType = node.type;
    if (aliasedType is NamedType &&
        typeNames.contains(aliasedType.name.lexeme)) {
      _addViolation(node, aliasedType.name.lexeme, 'type alias is not allowed');
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName;
    final typeName = constructor.type.name.lexeme;
    if (typeNames.contains(typeName) &&
        constructor.name == null &&
        !node.isConst) {
      _addViolation(node, typeName, 'runtime construction must use snapshot');
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final invokedName = node.methodName.name;
    if (typeNames.contains(invokedName) && !node.inConstantContext) {
      _addViolation(
        node,
        invokedName,
        'runtime construction must use snapshot',
      );
    }
    final targetName = _lastIdentifier(node.realTarget?.toSource());
    if (invokedName == 'new' && typeNames.contains(targetName)) {
      _addViolation(
        node,
        targetName!,
        'legacy constructor tear-off is not allowed',
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final targetName = node.prefix.name;
    if (node.identifier.name == 'new' && typeNames.contains(targetName)) {
      _addViolation(
        node,
        targetName,
        'legacy constructor tear-off is not allowed',
      );
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final targetName = _lastIdentifier(node.realTarget.toSource());
    if (node.propertyName.name == 'new' && typeNames.contains(targetName)) {
      _addViolation(
        node,
        targetName!,
        'legacy constructor tear-off is not allowed',
      );
    }
    super.visitPropertyAccess(node);
  }

  void _addViolation(AstNode node, String typeName, String message) {
    violations.add('$path@${node.offset}: $typeName $message');
  }
}

String? _lastIdentifier(String? source) => source?.split('.').last;
