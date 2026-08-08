import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'map_boundary_source_guard.dart';
import 'resolved_dart_workspace.dart';

const lifecycleCoreWireAdapterPath =
    'packages/aonw_core/lib/game/application/lifecycle/'
    'match_lifecycle_wire_adapter.dart';
const lifecycleServerAdapterPath =
    'server/lib/src/multiplayer/match_lifecycle_state_adapter.dart';
const lifecycleServicePath =
    'server/lib/src/multiplayer/match_lifecycle_service.dart';
const _commandServicePath =
    'server/lib/src/multiplayer/match_command_service.dart';
const _commandHandlingPath =
    'server/lib/src/multiplayer/match_command_service_handling.dart';
const _commandTimeoutPath =
    'server/lib/src/multiplayer/match_command_service_timeout.dart';
const _serverStorePath =
    'server/lib/src/multiplayer/multiplayer_match_store.dart';
const _lockedMatchReadMethods = {'requireMatch', 'requireStoredMatch'};

const _lifecycleValues = {
  'open',
  'loading',
  'running',
  'finished',
  'abandoned',
};

const _expectedRawLifecycleValues = <String, Map<String, int>>{
  lifecycleCoreWireAdapterPath: {
    'open': 3,
    'loading': 1,
    'running': 3,
    'finished': 3,
    'abandoned': 3,
  },
  lifecycleServerAdapterPath: {'running': 1, 'finished': 2, 'abandoned': 2},
  'server/lib/src/multiplayer/game_match_row_mapper.dart': {'running': 1},
  'server/lib/src/multiplayer/multiplayer_match_store_persistence.dart': {
    'running': 1,
  },
  'server/lib/src/multiplayer/multiplayer_match_store_queries.dart': {
    'open': 3,
    'running': 2,
  },
  'server/lib/src/multiplayer/running_match_snapshot_codec.dart': {
    'running': 3,
  },
};

final class MatchLifecycleBoundaryAudit {
  const MatchLifecycleBoundaryAudit(this.violations);

  final List<String> violations;
}

Future<MatchLifecycleBoundaryAudit> auditMatchLifecycleBoundaries({
  Map<String, String> sourceOverrides = const {},
}) async {
  final production = productionDartSources();
  final paths = <String>{
    for (final entry in production.entries)
      if ((entry.key.startsWith('packages/aonw_core/lib/') ||
              entry.key.startsWith('lib/') ||
              entry.key.startsWith('server/lib/src/multiplayer/')) &&
          _lifecycleValues.any(
            (value) =>
                entry.value.contains("'$value'") ||
                entry.value.contains('"$value"'),
          ))
        entry.key,
    ...sourceOverrides.keys,
    lifecycleServicePath,
    _commandServicePath,
    _commandHandlingPath,
    _commandTimeoutPath,
    _serverStorePath,
  };
  final workspace = ResolvedDartWorkspace(
    rootPath: '.',
    sourceOverrides: sourceOverrides,
  );
  try {
    final counts = <String, Map<String, int>>{};
    final methodCalls = <String, Map<String, int>>{};
    final storeLockMembers = <String, int>{};
    final units = await workspace.resolveAll(paths);
    for (final entry in units.entries) {
      entry.value.unit.accept(_LifecycleLiteralVisitor(entry.key, counts));
      entry.value.unit.accept(
        _LifecycleMutationVisitor(entry.key, methodCalls, storeLockMembers),
      );
    }
    return MatchLifecycleBoundaryAudit([
      if (!_sameNestedCounts(counts, _expectedRawLifecycleValues))
        'Raw lifecycle value inventory changed: $counts',
      ..._mutationBoundaryViolations(methodCalls, storeLockMembers),
    ]);
  } finally {
    await workspace.dispose();
  }
}

List<String> _mutationBoundaryViolations(
  Map<String, Map<String, int>> calls,
  Map<String, int> storeLockMembers,
) {
  const lifecycleMethods = {
    'loadMatch',
    'startMatch',
    'resignMatch',
    'leaveMatch',
    'setParticipantConnectionState',
  };
  final violations = <String>[];
  for (final method in lifecycleMethods) {
    final counts = calls['$lifecycleServicePath::$method'] ?? const {};
    if (counts['transaction'] != 1 || counts['lockedRequireMatch'] != 1) {
      violations.add(
        '$method must own one transaction and one locked match read: '
        '$counts',
      );
    }
  }
  if (calls['$_commandServicePath::handleClientMessage']?['transaction'] != 1) {
    violations.add('handleClientMessage must own its command transaction.');
  }
  if (calls['$_commandHandlingPath::_handleCommand']?['lockedRequireMatch'] !=
      1) {
    violations.add('_handleCommand must lock the authoritative match row.');
  }
  final timeout =
      calls['$_commandTimeoutPath::advanceTimedOutTurn'] ?? const {};
  if (timeout['transaction'] != 1 || timeout['lockedRequireMatch'] != 1) {
    violations.add(
      'advanceTimedOutTurn must transact and lock the match row: $timeout',
    );
  }
  if (storeLockMembers['LockMode.forUpdate'] != 2 ||
      storeLockMembers['LockBehavior.wait'] != 2) {
    violations.add('Server store lock mapping changed: $storeLockMembers');
  }
  return violations;
}

bool _sameNestedCounts(
  Map<String, Map<String, int>> actual,
  Map<String, Map<String, int>> expected,
) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    final actualCounts = actual[entry.key];
    if (actualCounts == null || actualCounts.length != entry.value.length) {
      return false;
    }
    for (final count in entry.value.entries) {
      if (actualCounts[count.key] != count.value) return false;
    }
  }
  return true;
}

final class _LifecycleLiteralVisitor extends RecursiveAstVisitor<void> {
  _LifecycleLiteralVisitor(this.path, this.counts);

  final String path;
  final Map<String, Map<String, int>> counts;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final value = node.value;
    if (_lifecycleValues.contains(value)) {
      counts
          .putIfAbsent(path, () => <String, int>{})
          .update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    super.visitSimpleStringLiteral(node);
  }
}

final class _LifecycleMutationVisitor extends RecursiveAstVisitor<void> {
  _LifecycleMutationVisitor(this.path, this.calls, this.storeLockMembers);

  final String path;
  final Map<String, Map<String, int>> calls;
  final Map<String, int> storeLockMembers;
  String? _methodName;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final previous = _methodName;
    _methodName = node.name.lexeme;
    super.visitMethodDeclaration(node);
    _methodName = previous;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = _methodName;
    if (methodName != null && node.methodName.name == 'transaction') {
      _increment('$path::$methodName', 'transaction');
    }
    if (methodName != null &&
        _lockedMatchReadMethods.contains(node.methodName.name) &&
        node.argumentList.arguments.whereType<NamedExpression>().any(
          (argument) =>
              argument.name.label.name == 'lock' &&
              argument.expression is BooleanLiteral &&
              (argument.expression as BooleanLiteral).value,
        )) {
      _increment('$path::$methodName', 'lockedRequireMatch');
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (path == _serverStorePath) {
      final value = node.toSource();
      if (value == 'LockMode.forUpdate' || value == 'LockBehavior.wait') {
        storeLockMembers.update(value, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  void _increment(String method, String kind) {
    calls
        .putIfAbsent(method, () => <String, int>{})
        .update(kind, (count) => count + 1, ifAbsent: () => 1);
  }
}
