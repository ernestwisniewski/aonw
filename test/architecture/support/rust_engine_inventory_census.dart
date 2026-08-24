part of '../rust_engine_migration_inventory_test.dart';

const _requiresFullStateParity = {
  'engine-parity',
  'runtime-ready',
  'client-ready',
  'shadow-ready',
  'cutover',
};

Map<String, int> _familyCounts(List<_InventoryEntry> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    counts.update(entry.family, (value) => value + 1, ifAbsent: () => 1);
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

Map<String, String> _concreteSubtypeSources({
  required String rootPath,
  required String baseType,
}) {
  final rootSource = File(rootPath).readAsStringSync();
  final rootUnit = parseString(
    content: rootSource,
    path: rootPath,
    throwIfDiagnostics: false,
  ).unit;
  final rootDirectory = rootPath.substring(0, rootPath.lastIndexOf('/'));
  final sourcePaths = <String>[
    rootPath,
    for (final part in rootUnit.directives.whereType<PartDirective>())
      '$rootDirectory/${part.uri.stringValue}',
  ];

  final declarations = <String, _DartDeclaration>{};
  for (final sourcePath in sourcePaths) {
    final unit = parseString(
      content: File(sourcePath).readAsStringSync(),
      path: sourcePath,
      throwIfDiagnostics: false,
    ).unit;
    for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
      final name = declaration.namePart.typeName.lexeme;
      declarations[name] = _DartDeclaration(
        parent: declaration.extendsClause?.superclass.name.lexeme,
        source: sourcePath,
        isAbstract:
            declaration.abstractKeyword != null ||
            declaration.sealedKeyword != null,
      );
    }
  }

  return {
    for (final declaration in declarations.entries)
      if (!declaration.value.isAbstract &&
          _inheritsFrom(declaration.key, baseType, declarations))
        declaration.key: declaration.value.source,
  };
}

bool _inheritsFrom(
  String type,
  String baseType,
  Map<String, _DartDeclaration> declarations,
) {
  final visited = <String>{};
  String? current = type;
  while (current != null && visited.add(current)) {
    final parent = declarations[current]?.parent;
    if (parent == baseType) return true;
    current = parent;
  }
  return false;
}

Set<String> _rustEnumVariants(String sourcePath, String enumName) {
  final source = File(sourcePath).readAsStringSync();
  final header = RegExp(
    'pub enum $enumName(?:<[^>]+>)?\\s*\\{',
  ).firstMatch(source);
  expect(header, isNotNull, reason: '$enumName missing from $sourcePath');
  final bodyEnd = source.indexOf('\n}', header!.end);
  expect(bodyEnd, greaterThan(header.end));
  final body = source.substring(header.end, bodyEnd);
  return {
    for (final match in RegExp(
      r'^\s*([A-Z][A-Za-z0-9_]*)\s*(?:\(|\{|,)',
      multiLine: true,
    ).allMatches(body))
      match.group(1)!,
  };
}

Set<String> _dartClassNames(String sourcePath) {
  final unit = parseString(
    content: File(sourcePath).readAsStringSync(),
    path: sourcePath,
    throwIfDiagnostics: false,
  ).unit;
  return {
    for (final declaration in unit.declarations.whereType<ClassDeclaration>())
      declaration.namePart.typeName.lexeme,
  };
}

Set<String> _rustStructNames(String sourcePath) => {
  for (final match in RegExp(
    r'^\s*pub struct\s+([A-Z][A-Za-z0-9_]*)',
    multiLine: true,
  ).allMatches(File(sourcePath).readAsStringSync()))
    match.group(1)!,
};

Set<String> _rustDataTypeNames(String sourcePath) => {
  for (final match in RegExp(
    r'^\s*pub (?:enum|struct)\s+([A-Z][A-Za-z0-9_]*)',
    multiLine: true,
  ).allMatches(File(sourcePath).readAsStringSync()))
    match.group(1)!,
};

Set<String> _dartPublicFinalFields(String sourcePath, String className) {
  final unit = parseString(
    content: File(sourcePath).readAsStringSync(),
    path: sourcePath,
    throwIfDiagnostics: false,
  ).unit;
  final declaration = unit.declarations
      .whereType<ClassDeclaration>()
      .singleWhere(
        (candidate) => candidate.namePart.typeName.lexeme == className,
      );
  return {
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      if (!field.isStatic && field.fields.isFinal)
        for (final variable in field.fields.variables)
          if (!variable.name.lexeme.startsWith('_')) variable.name.lexeme,
  };
}

Set<String> _rustStructFields(String sourcePath, String structName) {
  final source = File(sourcePath).readAsStringSync();
  final header = RegExp('pub struct $structName\\s*\\{').firstMatch(source);
  expect(header, isNotNull, reason: '$structName missing from $sourcePath');
  final bodyEnd = source.indexOf('\n}', header!.end);
  expect(bodyEnd, greaterThan(header.end));
  final body = source.substring(header.end, bodyEnd);
  return {
    for (final match in RegExp(
      r'^\s*pub\s+([a-z][a-z0-9_]*)\s*:',
      multiLine: true,
    ).allMatches(body))
      _snakeToCamel(match.group(1)!),
  };
}

String _snakeToCamel(String value) => value.replaceAllMapped(
  RegExp(r'_([a-z0-9])'),
  (match) => match.group(1)!.toUpperCase(),
);

Set<String> _functionMapKeys(String source, String functionName) {
  final declaration = RegExp(
    '(?:static )?Map<String, dynamic> ${RegExp.escape(functionName)}\\s*\\(',
  ).firstMatch(source);
  expect(declaration, isNotNull, reason: '$functionName missing');
  final start = declaration!.start;
  final end = source.indexOf('\n}', start);
  expect(end, greaterThan(start), reason: '$functionName body is not closed');
  return {
    for (final match in RegExp(
      r"'([A-Za-z][A-Za-z0-9]*)'\s*:",
    ).allMatches(source.substring(start, end)))
      match.group(1)!,
  };
}

final class _DartDeclaration {
  const _DartDeclaration({
    required this.parent,
    required this.source,
    required this.isAbstract,
  });

  final String? parent;
  final String source;
  final bool isAbstract;
}
