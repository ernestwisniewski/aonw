import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'map_boundary_source_guard.dart';

const combatLibraryPath = 'packages/aonw_core/lib/game/domain/combat/';
const combatCommandResolverPath =
    '${combatLibraryPath}combat_command_resolver.dart';
const combatCommandStatePath = '${combatLibraryPath}combat_command_state.dart';
const combatCommandResultPath =
    '${combatLibraryPath}combat_command_result.dart';
const combatPersistentAdapterPath =
    '${combatLibraryPath}persistent_combat_command_resolver.dart';
const combatDomainAdapterPath =
    '${combatLibraryPath}domain_combat_command_resolver.dart';
const combatLocalCallSite =
    'lib/game/domain/reducer/combat/combat_reducer.dart';
const combatServerCallSite =
    'server/lib/src/multiplayer/server_command_reducer_combat.dart';
const combatPerformanceWorkloadPath =
    'tool/performance/combat_command_workload.dart';
const persistentTurnCombatResolverPath =
    'packages/aonw_core/lib/game/domain/turn/'
    'persistent_turn_combat_resolver.dart';
const domainTurnCombatResolverPath =
    'packages/aonw_core/lib/game/domain/turn/'
    'domain_turn_combat_resolver.dart';

const combatCommandKernelPaths = {
  combatCommandResolverPath,
  combatCommandStatePath,
  combatCommandResultPath,
};

const combatCommandRuntimeCallSites = {
  combatPersistentAdapterPath,
  combatDomainAdapterPath,
  combatLocalCallSite,
  combatServerCallSite,
};

const combatCommandAllCallSites = {
  ...combatCommandRuntimeCallSites,
  combatPerformanceWorkloadPath,
};

const turnCombatOrchestratorCallSites = {
  persistentTurnCombatResolverPath,
  domainTurnCombatResolverPath,
  combatCommandResolverPath,
};

const combatCommandForbiddenStateTypes = {
  'GameState',
  'PersistentGameState',
  'DomainState',
  'MapData',
};

Map<String, String> combatCommandRuntimeSources(Map<String, String> sources) =>
    {
      for (final entry in sources.entries)
        if (entry.key != combatPerformanceWorkloadPath) entry.key: entry.value,
    };

List<String> combatCommandResolverShapeViolations(String? source) {
  if (source == null) {
    return const ['$combatCommandResolverPath must exist'];
  }
  final unit = parseString(
    content: source,
    path: combatCommandResolverPath,
  ).unit;
  final declarations = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) =>
        declaration.namePart.typeName.lexeme == 'CombatCommandResolver',
  );
  if (declarations.length != 1) {
    return const [
      'CombatCommandResolver must be declared exactly once in its kernel file',
    ];
  }
  final declaration = declarations.single;
  return [
    if (declaration.finalKeyword == null ||
        declaration.abstractKeyword != null ||
        declaration.baseKeyword != null ||
        declaration.interfaceKeyword != null ||
        declaration.mixinKeyword != null ||
        declaration.sealedKeyword != null)
      'CombatCommandResolver must remain a final class',
  ];
}

List<String> combatCommandKernelBoundaryViolations(
  Map<String, String> sources,
) {
  final violations = <String>[];
  final forbiddenTypes = typeNamesBackedBy(
    sources,
    combatCommandForbiddenStateTypes,
  );
  for (final path in combatCommandKernelPaths) {
    final source = sources[path];
    if (source == null) {
      violations.add('$path must exist');
      continue;
    }
    for (final forbiddenType in forbiddenTypes) {
      violations.addAll(
        sourceSymbolReferenceViolations(
          source,
          path,
          symbol: forbiddenType,
        ).map(
          (violation) =>
              '$violation inside the state-container-neutral combat kernel',
        ),
      );
    }
    final unit = parseString(content: source, path: path).unit;
    for (final directive in unit.directives.whereType<UriBasedDirective>()) {
      for (final uri in _directiveUris(directive)) {
        if (_isForbiddenCombatKernelUri(path, uri)) {
          final line = unit.lineInfo.getLocation(directive.offset).lineNumber;
          violations.add(
            '$path:$line imports forbidden boundary dependency $uri',
          );
        }
      }
    }
  }
  return violations..sort();
}

List<String> removedPersistentCombatBridgeViolations(
  Map<String, String> sources,
) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    violations
      ..addAll(
        sourceSymbolReferenceViolations(
          entry.value,
          entry.key,
          symbol: '_fromPersistentCombatResult',
        ),
      )
      ..addAll(_persistentCombatBridgeDeclarationViolations(unit, entry.key));
  }
  return violations..sort();
}

Iterable<String> _persistentCombatBridgeDeclarationViolations(
  CompilationUnit unit,
  String path,
) sync* {
  final functions = unit.declarations.whereType<FunctionDeclaration>();
  for (final function in functions) {
    if (function.name.lexeme != '_fromPersistentCombatResult') continue;
    yield _persistentCombatBridgeDeclarationViolation(
      unit,
      path,
      function.name.offset,
    );
  }

  final methods = unit.declarations
      .whereType<ClassDeclaration>()
      .expand((declaration) => declaration.body.members)
      .whereType<MethodDeclaration>();
  for (final method in methods) {
    if (method.name.lexeme != '_fromPersistentCombatResult') continue;
    yield _persistentCombatBridgeDeclarationViolation(
      unit,
      path,
      method.name.offset,
    );
  }
}

String _persistentCombatBridgeDeclarationViolation(
  CompilationUnit unit,
  String path,
  int nameOffset,
) {
  final line = unit.lineInfo.getLocation(nameOffset).lineNumber;
  return '$path:$line must not declare _fromPersistentCombatResult';
}

Iterable<String> _directiveUris(UriBasedDirective directive) sync* {
  final primary = directive.uri.stringValue;
  if (primary != null) yield primary;
  if (directive is NamespaceDirective) {
    for (final configuration in directive.configurations) {
      final conditional = configuration.uri.stringValue;
      if (conditional != null) yield conditional;
    }
  }
}

bool _isForbiddenCombatKernelUri(String importerPath, String uri) {
  if (uri.startsWith('package:aonw/') ||
      uri.startsWith('package:aonw_server/') ||
      uri.startsWith('package:aonw_server_client/')) {
    return true;
  }
  if (uri.startsWith('package:aonw_core/')) {
    return uri == 'package:aonw_core/game/domain/state.dart' ||
        uri.startsWith('package:aonw_core/game/domain/state/') ||
        uri.startsWith('package:aonw_core/game/domain/runtime/') ||
        uri.endsWith('/map_data.dart') ||
        uri.endsWith('/persistent_combat_command_resolver.dart') ||
        uri.endsWith('/domain_combat_command_resolver.dart');
  }
  final parsed = Uri.tryParse(uri);
  if (parsed == null || parsed.hasScheme) return false;
  final resolved = Uri.parse(importerPath).resolve(uri).path;
  return !resolved.startsWith('packages/aonw_core/lib/');
}
