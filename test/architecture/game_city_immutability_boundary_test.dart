import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime production cities use immutable constructors', () {
    final violations = <String>[];
    for (final root in const [
      'lib',
      'packages/aonw_core/lib',
      'server/lib',
      'tool',
      'packages/aonw_core/tool',
    ]) {
      final directory = Directory(root);
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path.replaceAll('\\', '/');
        violations.addAll(
          _runtimeGameCityViolations(entity.readAsStringSync(), path),
        );
      }
    }

    expect(violations, isEmpty);
  });

  test('guard distinguishes runtime and constant city construction', () {
    final violations = _runtimeGameCityViolations('''
GameCity runtimeCity() => GameCity(id: '1');
GameCity snapshotCity() => GameCity.snapshot(id: '2');
const explicit = GameCity(id: '3');
const implicit = [GameCity(id: '4')];
''', 'fixture.dart');

    expect(violations, hasLength(1));
    expect(violations.single, contains('runtime GameCity'));
  });

  test('guard rejects aliases of the legacy city constructor', () {
    final directAlias = _runtimeGameCityViolations('''
typedef City = GameCity;
''', 'fixture.dart');
    final recordUsingCity = _runtimeGameCityViolations('''
typedef CityResult = ({GameCity city});
''', 'record_fixture.dart');

    expect(directAlias, hasLength(1));
    expect(directAlias.single, contains('alias GameCity'));
    expect(recordUsingCity, isEmpty);
  });

  test('guard rejects direct new and constructor tear-offs', () {
    final directNew = _runtimeGameCityViolations('''
GameCity runtimeCity() => GameCity.new(id: '1');
''', 'direct_new.dart');
    final tearOff = _runtimeGameCityViolations('''
final createCity = GameCity.new;
''', 'tear_off.dart');

    expect(directNew, isNotEmpty);
    expect(tearOff, isNotEmpty);
    expect(
      [...directNew, ...tearOff].join('\n'),
      contains('legacy GameCity.new'),
    );
  });
}

List<String> _runtimeGameCityViolations(String source, String path) {
  final visitor = _RuntimeGameCityVisitor(path);
  parseString(content: source, path: path).unit.accept(visitor);
  return visitor.violations.toList();
}

final class _RuntimeGameCityVisitor extends RecursiveAstVisitor<void> {
  _RuntimeGameCityVisitor(this.path);

  final String path;
  final Set<String> violations = {};

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    final aliasedType = node.type;
    if (aliasedType is NamedType && aliasedType.name.lexeme == 'GameCity') {
      _addViolation(node, 'alias GameCity is not allowed');
    }
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName;
    if (constructor.type.name.lexeme == 'GameCity' &&
        constructor.name == null &&
        !node.isConst) {
      _addViolation(node);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'GameCity' && !node.inConstantContext) {
      _addViolation(node);
    }
    if (node.methodName.name == 'new' &&
        _lastIdentifier(node.realTarget?.toSource()) == 'GameCity') {
      _addViolation(node, 'legacy GameCity.new is not allowed');
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'new' && node.prefix.name == 'GameCity') {
      _addViolation(node, 'legacy GameCity.new is not allowed');
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'new' &&
        _lastIdentifier(node.realTarget.toSource()) == 'GameCity') {
      _addViolation(node, 'legacy GameCity.new is not allowed');
    }
    super.visitPropertyAccess(node);
  }

  void _addViolation(
    AstNode node, [
    String message = 'runtime GameCity must use snapshot',
  ]) {
    violations.add('$path@${node.offset}: $message');
  }
}

String? _lastIdentifier(String? source) => source?.split('.').last;
