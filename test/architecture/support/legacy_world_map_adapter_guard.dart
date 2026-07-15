import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

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
      final path = _relativePath(entry.path);
      final source = entry.readAsStringSync();
      if (containing == null || source.contains(containing)) {
        sources[path] = source;
      }
    }
  }
  return sources;
}

Set<String> mapDataBackedTypeNames(Map<String, String> sources) {
  final units = [
    for (final entry in sources.entries)
      parseString(content: entry.value, path: entry.key).unit,
  ];
  final names = <String>{'MapData'};
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

Map<String, List<int>> legacyWorldMapAdapterMethodSites(
  Map<String, String> sources, {
  required String methodName,
}) {
  final sites = <String, List<int>>{};
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    unit.accept(
      _AdapterMethodSiteVisitor(
        path: entry.key,
        lineInfo: unit.lineInfo,
        sites: sites,
        adapterTypeNames: legacyWorldMapAdapterTypeNames(unit),
        methodName: methodName,
      ),
    );
  }
  return sites;
}

Map<String, List<int>> legacyWorldMapAdapterTypedefSites(
  Map<String, String> sources,
) {
  final sites = <String, List<int>>{};
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final adapterTypeNames = legacyWorldMapAdapterTypeNames(unit);
    for (final alias in unit.declarations.whereType<GenericTypeAlias>()) {
      final type = alias.type;
      if (type is! NamedType || !adapterTypeNames.contains(type.name.lexeme)) {
        continue;
      }
      final key = '${entry.key}::typedef:${alias.name.lexeme}';
      sites
          .putIfAbsent(key, () => [])
          .add(unit.lineInfo.getLocation(alias.offset).lineNumber);
    }
  }
  return sites;
}

Set<String> legacyWorldMapAdapterTypeNames(CompilationUnit unit) {
  final names = <String>{'LegacyWorldMapAdapter'};
  var changed = true;
  while (changed) {
    changed = false;
    for (final alias in unit.declarations.whereType<GenericTypeAlias>()) {
      final type = alias.type;
      if (type is NamedType &&
          names.contains(type.name.lexeme) &&
          names.add(alias.name.lexeme)) {
        changed = true;
      }
    }
  }
  return names;
}

bool isLegacyWorldMapAdapterMethodReference(
  SimpleIdentifier node, {
  required String methodName,
  required Set<String> adapterTypeNames,
  bool rejectAnyTarget = false,
}) {
  if (node.name != methodName) return false;
  if (rejectAnyTarget) return true;
  final parent = node.parent;
  final target = switch (parent) {
    MethodInvocation(:final methodName, :final realTarget)
        when identical(methodName, node) =>
      realTarget?.toSource(),
    PrefixedIdentifier(:final identifier, :final prefix)
        when identical(identifier, node) =>
      prefix.toSource(),
    PropertyAccess(:final propertyName, :final realTarget)
        when identical(propertyName, node) =>
      realTarget.toSource(),
    _ => null,
  };
  final targetType = target?.split('.').last;
  return targetType != null && adapterTypeNames.contains(targetType);
}

bool isUnqualifiedMethodReference(SimpleIdentifier node) {
  final parent = node.parent;
  if (parent is MethodInvocation && identical(parent.methodName, node)) {
    return parent.realTarget == null;
  }
  if (parent is PrefixedIdentifier || parent is PropertyAccess) return false;
  if (parent is MethodDeclaration && identical(parent.name, node)) return false;
  if (parent is FunctionDeclaration && identical(parent.name, node)) {
    return false;
  }
  if (parent is VariableDeclaration && identical(parent.name, node)) {
    return false;
  }
  if (parent is NamedType) return false;
  return true;
}

final class _AdapterMethodSiteVisitor extends RecursiveAstVisitor<void> {
  _AdapterMethodSiteVisitor({
    required this.path,
    required this.lineInfo,
    required this.sites,
    required this.adapterTypeNames,
    required this.methodName,
  });

  final String path;
  final LineInfo lineInfo;
  final Map<String, List<int>> sites;
  final Set<String> adapterTypeNames;
  final String methodName;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (isLegacyWorldMapAdapterMethodReference(
      node,
      methodName: methodName,
      adapterTypeNames: adapterTypeNames,
    )) {
      final kind = node.parent is MethodInvocation ? 'call' : 'tearOff';
      final key = '$path::${_declarationOwner(node)}::$kind';
      sites
          .putIfAbsent(key, () => [])
          .add(lineInfo.getLocation(node.offset).lineNumber);
    }
    super.visitSimpleIdentifier(node);
  }
}

String _declarationOwner(AstNode node) {
  String? className;
  String? member;
  for (var parent = node.parent; parent != null; parent = parent.parent) {
    member ??= switch (parent) {
      MethodDeclaration(:final name) => 'method:${name.lexeme}',
      ConstructorDeclaration(:final name) =>
        'constructor:${name?.lexeme ?? '<unnamed>'}',
      FunctionDeclaration(:final name) => 'function:${name.lexeme}',
      VariableDeclaration(:final name) when _isOwnerVariable(parent) =>
        'field:${name.lexeme}',
      _ => null,
    };
    if (parent is ClassDeclaration) {
      className = parent.namePart.typeName.lexeme;
      break;
    }
  }
  return '${className == null ? '' : 'class:$className/'}'
      '${member ?? '<unit>'}';
}

bool _isOwnerVariable(VariableDeclaration node) {
  final declaration = node.parent;
  if (declaration is! VariableDeclarationList) return false;
  return declaration.parent is FieldDeclaration ||
      declaration.parent is TopLevelVariableDeclaration;
}

String _relativePath(String path) {
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
