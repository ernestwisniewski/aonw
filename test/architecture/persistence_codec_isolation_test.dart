import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _codecPath =
    'lib/game/infrastructure/persistence/isolated_save_snapshot_codec.dart';
const _storePaths = {
  'lib/game/infrastructure/persistence/json_snapshot_store.dart',
  'lib/game/infrastructure/persistence/json_replay_store.dart',
};

void main() {
  test('large filesystem codecs stay outside the caller isolate', () {
    final codecSource = File(_codecPath).readAsStringSync();
    final codecUnit = parseString(
      content: codecSource,
      path: _codecPath,
      throwIfDiagnostics: false,
    ).unit;
    final calls = _InvocationCollector()..visitCompilationUnit(codecUnit);

    expect(codecSource, contains("import 'dart:isolate';"));
    expect(calls.names.where((name) => name == 'Isolate.run'), hasLength(4));

    for (final path in _storePaths) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('jsonEncode(')), reason: path);
      expect(source, isNot(contains('jsonDecode(')), reason: path);
      expect(source, contains('IsolatedSaveSnapshotCodec.'), reason: path);
    }
  });
}

final class _InvocationCollector extends RecursiveAstVisitor<void> {
  final names = <String>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    names.add(
      target == null
          ? node.methodName.name
          : '${target.toSource()}.${node.methodName.name}',
    );
    super.visitMethodInvocation(node);
  }
}
