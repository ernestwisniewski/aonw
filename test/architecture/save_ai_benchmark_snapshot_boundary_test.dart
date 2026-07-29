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
  test('save AI benchmark preparation uses canonical snapshot state', () {
    final unit = parseString(
      content: File(_benchmarkPath).readAsStringSync(),
      path: _benchmarkPath,
    ).unit;

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'runtimeState'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
  });

  test('benchmark report models use canonical snapshot state', () {
    final unit = _unitAt(_reportModelsPath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'runtimeState'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'session'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
    expect(_propertyReadCount(unit, 'persistedPlayers'), greaterThan(0));
  });

  test('runtime smoke uses canonical and lossless snapshot state only', () {
    final unit = _unitAt(_runtimeSmokePath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'runtimeState'), 0);
    expect(_propertyReadCount(unit, 'domain'), greaterThan(0));
    expect(_propertyReadCount(unit, 'metadata'), greaterThan(0));
  });

  test('multi-turn replay uses canonical and lossless snapshot state only', () {
    final unit = _unitAt(_multiTurnReplayPath);

    expect(_propertyReadCount(unit, 'save'), 0);
    expect(_propertyReadCount(unit, 'persistentState'), 0);
    expect(_propertyReadCount(unit, 'runtimeState'), 0);
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
      expect(_propertyReadCount(unit, 'runtimeState'), 0);
    });
  }
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

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
