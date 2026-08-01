import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _benchmarkPath = 'tool/run_save_ai_benchmark.dart';
const _reportModelsPath = 'tool/run_save_ai_benchmark/report_models.dart';
const _runtimeSmokePath = 'tool/run_save_ai_benchmark/runtime_smoke.dart';
const _multiTurnReplayPath =
    'tool/run_save_ai_benchmark/multi_turn_replay.dart';
const _syntheticHelpersPath =
    'tool/run_save_ai_benchmark/benchmark_synthetic_helpers.dart';
const _cliHelpersPath = 'tool/run_save_ai_benchmark/cli_helpers.dart';
const _targetHelpersPath =
    'tool/run_save_ai_benchmark/benchmark_target_helpers.dart';
const _obsoleteReplayHelpers = [
  '_resetPlayerTurns',
  '_prepareCycleState',
  '_activePlayerIds',
  '_syntheticSavedAt',
];

void main() {
  test('benchmark snapshot guard covers the complete AST part closure', () {
    final units = _libraryUnitsAt(_benchmarkPath);
    final entry = units.singleWhere(
      (source) => source.path == File(_benchmarkPath).absolute.path,
    );
    final declaredPartCount = entry.unit.directives
        .whereType<PartDirective>()
        .length;

    expect(units, hasLength(declaredPartCount + 1));
    expect(_snapshotBoundaryViolations(units), isEmpty);
    expect(
      _canonicalTurnFinalizeCount(units),
      0,
      reason: 'Benchmark turn finalization must enter through GameEngine.',
    );
    expect(_propertyReadCountAcross(units, 'domain'), greaterThan(0));
    expect(_propertyReadCountAcross(units, 'session'), greaterThan(0));
    expect(_propertyReadCountAcross(units, 'metadata'), greaterThan(0));
  });

  test('benchmark snapshot guard rejects a hidden helper in a new part', () {
    const entryPath = 'tool/fixture_benchmark.dart';
    final closure = _libraryPartClosure(const {
      entryPath: "part 'fixture_benchmark/hidden_helper.dart';",
      'tool/fixture_benchmark/hidden_helper.dart': '''
part of '../fixture_benchmark.dart';

PersistentGameState rebuild(GameClientState state) =>
    PersistentGameState.snapshot(runtimeState: state.runtimeState);

void finalize(PersistentGameState state, MapReadView mapView) {
  PersistentTurnMovementProcessor.resetForPlayers(
    state: state,
    playerIds: const [],
    mapData: mapView,
  );
}
''',
    }, entryPath: entryPath);

    expect(closure.missingPaths, isEmpty);
    expect(closure.units.map((source) => source.path), {
      entryPath,
      'tool/fixture_benchmark/hidden_helper.dart',
    });
    final violations = _snapshotBoundaryViolations(closure.units);
    expect(
      violations,
      contains(
        'tool/fixture_benchmark/hidden_helper.dart:'
        ' PersistentGameState is forbidden',
      ),
    );
    expect(
      violations,
      contains(
        'tool/fixture_benchmark/hidden_helper.dart:'
        ' PersistentTurnMovementProcessor is forbidden',
      ),
    );
    expect(
      violations,
      contains(
        'tool/fixture_benchmark/hidden_helper.dart:'
        ' runtimeState property read is forbidden',
      ),
    );
  });

  test('save AI benchmark preparation uses canonical snapshot state', () {
    final unit = parseString(
      content: File(_benchmarkPath).readAsStringSync(),
      path: _benchmarkPath,
    ).unit;

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'lifecycle'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
  });

  test('benchmark report models use canonical snapshot state', () {
    final unit = _unitAt(_reportModelsPath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'lifecycle'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
    expect(_propertyReadCount(unit, 'persistedPlayers'), greaterThan(0));
  });

  test('runtime smoke uses canonical and lossless snapshot state only', () {
    final unit = _unitAt(_runtimeSmokePath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'lifecycle'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
  });

  test('multi-turn replay uses canonical and lossless snapshot state only', () {
    final unit = _unitAt(_multiTurnReplayPath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'lifecycle'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
    expect(_propertyReadCount(unit, 'persistedPlayers'), greaterThan(0));
  });

  test('benchmark helpers contain no parallel GameSave replay helpers', () {
    final unit = _unitAt(_targetHelpersPath);

    for (final helperName in _obsoleteReplayHelpers) {
      expect(_identifierCount(unit, helperName), 0, reason: helperName);
    }
  });

  for (final path in const [
    _syntheticHelpersPath,
    _cliHelpersPath,
    _targetHelpersPath,
  ]) {
    test('$path uses canonical or explicit lossless snapshot state only', () {
      final unit = _unitAt(path);

      expect(_propertyReadCount(unit, 'save'), 0);
      expect(_propertyReadCount(unit, 'persistentState'), 0);
      expect(_propertyReadCount(unit, 'lifecycle'), 0);
    });
  }
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

List<({String path, CompilationUnit unit})> _libraryUnitsAt(String entryPath) {
  final pending = <File>[File(entryPath).absolute];
  final visited = <String>{};
  final units = <({String path, CompilationUnit unit})>[];
  while (pending.isNotEmpty) {
    final file = pending.removeLast();
    if (!visited.add(file.path)) continue;
    final unit = _unitAt(file.path);
    units.add((path: file.path, unit: unit));
    for (final directive in unit.directives.whereType<PartDirective>()) {
      final partUri = directive.uri.stringValue;
      if (partUri == null) {
        throw StateError('Non-literal part URI in ${file.path}');
      }
      pending.add(File.fromUri(file.uri.resolve(partUri)));
    }
  }
  return units;
}

({List<({String path, CompilationUnit unit})> units, Set<String> missingPaths})
_libraryPartClosure(Map<String, String> sources, {required String entryPath}) {
  final pending = <String>[entryPath];
  final visited = <String>{};
  final units = <({String path, CompilationUnit unit})>[];
  final missingPaths = <String>{};
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (!visited.add(path)) continue;
    final source = sources[path];
    if (source == null) {
      missingPaths.add(path);
      continue;
    }
    final unit = parseString(content: source, path: path).unit;
    units.add((path: path, unit: unit));
    for (final directive in unit.directives.whereType<PartDirective>()) {
      final partUri = directive.uri.stringValue;
      if (partUri == null) {
        missingPaths.add('$path::<non-static-part-uri>');
        continue;
      }
      pending.add(Uri.parse(path).resolve(partUri).path);
    }
  }
  return (units: units, missingPaths: missingPaths);
}

Set<String> _snapshotBoundaryViolations(
  Iterable<({String path, CompilationUnit unit})> units,
) {
  final violations = <String>{};
  for (final source in units) {
    source.unit.accept(_SnapshotBoundaryVisitor(source.path, violations));
  }
  return violations;
}

int _canonicalTurnFinalizeCount(
  Iterable<({String path, CompilationUnit unit})> units,
) {
  var count = 0;
  for (final source in units) {
    final visitor = _CanonicalTurnFinalizeCollector();
    source.unit.accept(visitor);
    count += visitor.count;
  }
  return count;
}

int _propertyReadCountAcross(
  Iterable<({String path, CompilationUnit unit})> units,
  String propertyName,
) {
  return units.fold(
    0,
    (count, source) => count + _propertyReadCount(source.unit, propertyName),
  );
}

int _propertyReadCount(AstNode node, String propertyName) {
  final collector = _PropertyReadCollector(propertyName);
  node.accept(collector);
  return collector.count;
}

int _identifierCount(AstNode node, String identifier) {
  final collector = _IdentifierCollector(identifier);
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

final class _SnapshotBoundaryVisitor extends RecursiveAstVisitor<void> {
  _SnapshotBoundaryVisitor(this.path, this.violations);

  final String path;
  final Set<String> violations;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;
    if (name == 'PersistentGameState' || name.startsWith('PersistentTurn')) {
      violations.add('$path: $name is forbidden');
    }
    if (name == 'save' || name == 'persistentState' || name == 'lifecycle') {
      final parent = node.parent;
      if (parent is PrefixedIdentifier && identical(parent.identifier, node) ||
          parent is PropertyAccess && identical(parent.propertyName, node)) {
        violations.add('$path: $name property read is forbidden');
      }
    }
    super.visitSimpleIdentifier(node);
  }
}

final class _CanonicalTurnFinalizeCollector extends RecursiveAstVisitor<void> {
  var count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'simultaneousFinalize' &&
        node.target?.toSource() == 'CanonicalTurnPipeline') {
      count += 1;
    }
    super.visitMethodInvocation(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.identifier);

  final String identifier;
  var count = 0;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == identifier) count += 1;
    super.visitSimpleIdentifier(node);
  }
}
