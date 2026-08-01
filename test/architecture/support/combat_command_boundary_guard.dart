import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'map_boundary_source_guard.dart';

const combatLibraryPath = 'packages/aonw_core/lib/game/domain/combat/';
const combatCommandResolverPath =
    '${combatLibraryPath}combat_command_resolver.dart';
const combatCommandStatePath = '${combatLibraryPath}combat_command_state.dart';
const combatCommandResultPath =
    '${combatLibraryPath}combat_command_result.dart';
const combatDomainAdapterPath =
    '${combatLibraryPath}domain_combat_command_resolver.dart';
const combatEngineHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'combat_engine_handler.dart';
const combatLocalCallSite =
    'lib/game/application/services/local_combat_command_resolver.dart';
const combatServerCallSite =
    'server/lib/src/multiplayer/server_command_reducer_unit_action.dart';
const combatPerformanceWorkloadPath =
    'tool/performance/combat_command_workload.dart';
const combatAnimationFactCodecPath =
    'packages/aonw_core/lib/game/application/engine/'
    'combat_animation_fact_codec.dart';
const combatEventCodecPath = 'lib/api/protocol/codecs.dart';
const combatDomainEventProjectorPath =
    'lib/game/presentation/engine/domain_event_presentation_projector.dart';
const combatReplayEffectPlannerPath =
    'lib/game/presentation/replay/replay_renderer_effect_planner.dart';
const combatGameActionsProviderPath =
    'lib/game/presentation/engine/command_dispatch_presentation_projector.dart';
const combatHiddenAiPlaybackPath =
    'lib/game/presentation/services/hidden_ai_renderer_playback.dart';
const combatGameStateRendererEffectsPath =
    'lib/game/presentation/providers/game/'
    'game_state_provider_renderer_effects.dart';
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

const combatCommandRuntimeCallSites = {combatDomainAdapterPath};

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
  'GameClientState',
  'PersistentGameState',
  'DomainState',
  'WorldMap',
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

List<String> staticCallNamedArgumentViolations(
  Map<String, String> sources, {
  required String targetType,
  required String methodName,
  required String argumentName,
  required Map<String, int> expectedCalls,
}) {
  final violations = <String>[];
  final actualCalls = <String, int>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _StaticMethodInvocationCollector(targetTypes, methodName);
    unit.accept(collector);
    if (collector.invocations.isNotEmpty) {
      actualCalls[entry.key] = collector.invocations.length;
    }
    for (final invocation in collector.invocations) {
      final namedArguments = invocation.argumentList.arguments
          .whereType<NamedExpression>()
          .where((argument) => argument.name.label.name == argumentName)
          .length;
      if (namedArguments == 1) continue;
      final line = unit.lineInfo
          .getLocation(invocation.methodName.offset)
          .lineNumber;
      violations.add(
        '${entry.key}:$line $targetType.$methodName must pass exactly one '
        '$argumentName named argument',
      );
    }
  }
  if (!_sameCounts(actualCalls, expectedCalls)) {
    violations.add(
      '$targetType.$methodName call inventory changed: '
      'expected $expectedCalls, found $actualCalls',
    );
  }
  return violations..sort();
}

bool _sameCounts(Map<String, int> actual, Map<String, int> expected) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) return false;
  }
  return true;
}

final class _StaticMethodInvocationCollector extends RecursiveAstVisitor<void> {
  _StaticMethodInvocationCollector(this.targetTypes, this.methodName);

  final Set<String> targetTypes;
  final String methodName;
  final List<MethodInvocation> invocations = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target?.toSource();
    if (node.methodName.name == methodName &&
        target != null &&
        targetTypes.any(
          (type) => target == type || target.endsWith('.$type'),
        )) {
      invocations.add(node);
    }
    super.visitMethodInvocation(node);
  }
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
