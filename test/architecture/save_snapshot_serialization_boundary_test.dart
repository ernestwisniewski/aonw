import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/save_snapshot_serialization_guard.dart';

void main() {
  group('SaveSnapshot serialization boundary', () {
    test('production semantic snapshot reads are eliminated', () {
      expect(_productionPersistentStateReads(), isEmpty);
    });

    test('semantic read scanner ignores text and finds property access', () {
      final unit = parseString(
        content: '''
const decoy = 'snapshot.persistentState';
// snapshot.persistentState;
Object read(SaveSnapshot snapshot) => snapshot.persistentState;
Object indirect() => source().persistentState;
''',
      ).unit;

      expect(_persistentStateReadCount(unit), 2);
    });

    test('AST guard catches semantic serialization helper bridges', () {
      final violations = _violations(
        persistenceSource: '''
abstract final class SaveSnapshotCodec {
  static Object toJson(SaveSnapshot snapshot) => _state(snapshot);
}
Object _state(SaveSnapshot snapshot) => snapshot.canonical;
''',
        protocolSource: '''
final class SnapshotCodec {
  Object _stateToJson(SaveSnapshot snapshot) => _state(snapshot);
}
Object _state(SaveSnapshot snapshot) => snapshot.effectivePlayerCountries;
''',
      );

      expect(
        violations,
        containsAll(const {'canonical', 'effectivePlayerCountries'}),
      );
    });

    test('AST guard rejects semantic access even beside a raw access', () {
      final violations = _violations(
        persistenceSource: '''
abstract final class SaveSnapshotCodec {
  static Object toJson(SaveSnapshot snapshot) {
    final raw = snapshot.rawPersistentState;
    return _semantic(snapshot, raw);
  }
}
Object _semantic(SaveSnapshot snapshot, Object raw) =>
    snapshot.persistentState;
''',
        protocolSource: '''
final class SnapshotCodec {
  Object _stateToJson(SaveSnapshot snapshot) => snapshot.playerCountries;
}
''',
      );

      expect(violations, contains('persistentState'));
    });

    test('AST guard rejects passing the whole snapshot to opaque helpers', () {
      final violations = _violations(
        persistenceSource: '''
abstract final class SaveSnapshotCodec {
  static Object toJson(SaveSnapshot snapshot) {
    final raw = snapshot.rawPersistentState;
    return opaqueBridge(snapshot, raw);
  }
}
''',
        protocolSource: '''
final class SnapshotCodec {
  Object _stateToJson(SaveSnapshot snapshot) => snapshot.playerCountries;
}
''',
      );

      expect(violations, contains('snapshot'));
    });

    test('AST guard binds accesses to the actual snapshot parameter', () {
      final violations = _violations(
        persistenceSource: '''
dynamic snapshot;
abstract final class SaveSnapshotCodec {
  static Object toJson(SaveSnapshot value) {
    final decoy = snapshot.rawPersistentState;
    return opaqueBridge(value, decoy);
  }
}
''',
        protocolSource: '''
final class SnapshotCodec {
  Object _stateToJson(SaveSnapshot snapshot) => snapshot.playerCountries;
}
''',
      );

      expect(violations, containsAll(const {'rawPersistentState', 'snapshot'}));
    });

    test('AST guard rejects opaque helpers fed with all raw state', () {
      final violations = _violations(
        persistenceSource: '''
abstract final class SaveSnapshotCodec {
  static Object toJson(SaveSnapshot snapshot) {
    return opaqueBridge(snapshot.save, snapshot.rawPersistentState);
  }
}
''',
        protocolSource: '''
final class SnapshotCodec {
  Object _stateToJson(SaveSnapshot snapshot) => snapshot.playerCountries;
}
''',
      );

      expect(violations, contains('opaqueBridge'));
    });

    test('AST guard rejects toJson on a composite raw receiver', () {
      final violations = _violations(
        persistenceSource: '''
abstract final class SaveSnapshotCodec {
  static Object toJson(SaveSnapshot snapshot) =>
      (snapshot.save, snapshot.rawPersistentState).toJson();
}
''',
        protocolSource: '''
final class SnapshotCodec {
  Object _stateToJson(SaveSnapshot snapshot) => snapshot.playerCountries;
}
''',
      );

      expect(violations, contains('toJson'));
    });
  });
}

List<String> _violations({
  required String persistenceSource,
  required String protocolSource,
}) {
  return saveSnapshotSerializationBoundaryViolations(
    persistenceSource: persistenceSource,
    protocolSource: protocolSource,
  );
}

int _persistentStateReadCount(AstNode node) {
  final collector = _PersistentStateReadCollector();
  node.accept(collector);
  return collector.count;
}

Map<String, int> _productionPersistentStateReads() {
  final reads = <String, int>{};
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/');
    final unit = parseString(content: file.readAsStringSync(), path: path).unit;
    final count = _persistentStateReadCount(unit);
    if (count != 0) reads[path] = count;
  }
  return reads;
}

final class _PersistentStateReadCollector extends RecursiveAstVisitor<void> {
  int count = 0;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'persistentState') count += 1;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'persistentState') count += 1;
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'persistentState') count += 1;
    super.visitMethodInvocation(node);
  }
}
