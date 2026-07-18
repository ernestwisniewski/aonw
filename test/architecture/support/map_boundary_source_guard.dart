import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Map<String, String> productionDartSources({String? containing}) {
  final sources = <String, String>{};
  // Scan first-party production and runnable tooling only. Dependency trees
  // under third_party/ and .dart_tool/ are intentionally out of scope.
  for (final root in const [
    'packages/aonw_core/lib',
    'packages/aonw_core/tool',
    'packages/aonw_server_client/lib',
    'lib',
    'server/bin',
    'server/lib',
    'server/tool',
    'tool',
  ]) {
    final directory = Directory(root);
    if (!directory.existsSync()) continue;
    for (final entry in directory.listSync(recursive: true)) {
      if (entry is! File ||
          !entry.path.endsWith('.dart') ||
          entry.path.endsWith('.g.dart') ||
          entry.path.endsWith('.freezed.dart')) {
        continue;
      }
      final path = _workspaceRelativeSourcePath(entry.path);
      final source = entry.readAsStringSync();
      if (containing == null || source.contains(containing)) {
        sources[path] = source;
      }
    }
  }
  return sources;
}

Set<String> mapDataBackedTypeNames(Map<String, String> sources) {
  return typeNamesBackedBy(sources, const {'MapData'});
}

Set<String> namedTypeReferencesInSource(
  String source, {
  String path = 'source.dart',
}) {
  final names = <String>{};
  parseString(
    content: source,
    path: path,
  ).unit.accept(_NamedTypeNameVisitor(names));
  return names;
}

Set<String> typeNamesBackedBy(
  Map<String, String> sources,
  Set<String> rootNames,
) {
  final units = [
    for (final entry in sources.entries)
      parseString(content: entry.value, path: entry.key).unit,
  ];
  final names = <String>{...rootNames};
  var changed = true;
  while (changed) {
    changed = false;
    for (final unit in units) {
      for (final alias in unit.declarations.whereType<GenericTypeAlias>()) {
        final referencedNames = <String>{};
        alias.type.accept(_NamedTypeNameVisitor(referencedNames));
        if (referencedNames.any(names.contains) &&
            names.add(alias.name.lexeme)) {
          changed = true;
        }
      }
    }
  }
  return names;
}

List<String> removedProductionSymbolViolations(
  Map<String, String> sources, {
  required String symbol,
  required String uriSuffix,
}) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final visitor = _SymbolReferenceVisitor(symbol);
    unit.accept(visitor);
    for (final line in visitor.lines(unit)) {
      violations.add('${entry.key}:$line must not reference $symbol');
    }
    for (final directive in unit.directives.whereType<UriBasedDirective>()) {
      final uri = directive.uri.stringValue;
      if (uri != null && uri.endsWith(uriSuffix)) {
        final line = unit.lineInfo.getLocation(directive.offset).lineNumber;
        violations.add('${entry.key}:$line must not import or export $uri');
      }
    }
  }
  return violations;
}

List<String> sourceSymbolReferenceViolations(
  String source,
  String path, {
  required String symbol,
}) {
  final unit = parseString(content: source, path: path).unit;
  final visitor = _SymbolReferenceVisitor(symbol);
  unit.accept(visitor);
  return [
    for (final line in visitor.lines(unit))
      '$path:$line must not reference $symbol',
  ];
}

List<String> constructedTypeViolations(
  Map<String, String> sources, {
  required String type,
}) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final visitor = _ConstructedTypeVisitor(type);
    unit.accept(visitor);
    for (final line in visitor.lines(unit)) {
      violations.add('${entry.key}:$line must not construct $type');
    }
  }
  return violations;
}

String _workspaceRelativeSourcePath(String path) {
  final prefix = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}

final class _NamedTypeNameVisitor extends RecursiveAstVisitor<void> {
  _NamedTypeNameVisitor(this.names);

  final Set<String> names;

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

final class _SymbolReferenceVisitor extends RecursiveAstVisitor<void> {
  _SymbolReferenceVisitor(this.symbol);

  final String symbol;
  final Set<int> offsets = {};

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == symbol) offsets.add(node.offset);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == symbol && node.parent is! NamedType) {
      offsets.add(node.offset);
    }
    super.visitSimpleIdentifier(node);
  }

  Iterable<int> lines(CompilationUnit unit) sync* {
    final sorted = offsets.toList()..sort();
    for (final offset in sorted) {
      yield unit.lineInfo.getLocation(offset).lineNumber;
    }
  }
}

final class _ConstructedTypeVisitor extends RecursiveAstVisitor<void> {
  _ConstructedTypeVisitor(this.type);

  final String type;
  final Set<int> offsets = {};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == type) {
      offsets.add(node.offset);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target?.toSource();
    if (node.methodName.name == type ||
        target == type ||
        target?.endsWith('.$type') == true) {
      offsets.add(node.offset);
    }
    super.visitMethodInvocation(node);
  }

  Iterable<int> lines(CompilationUnit unit) sync* {
    final sorted = offsets.toList()..sort();
    for (final offset in sorted) {
      yield unit.lineInfo.getLocation(offset).lineNumber;
    }
  }
}
