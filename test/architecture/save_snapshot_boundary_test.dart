import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/save_snapshot_serialization_guard.dart';

const _snapshotPath = 'lib/game/application/ports/save_snapshot.dart';
const _persistenceCodecPath =
    'lib/game/infrastructure/persistence/save_snapshot_codec.dart';
const _protocolCodecPath = 'lib/api/protocol/codecs.dart';
const _localResolverPath =
    'lib/game/application/services/local_command_resolver.dart';

void main() {
  group('SaveSnapshot boundary', () {
    test('snapshot is final with one lazy canonical compatibility seam', () {
      final unit = _unitAt(_snapshotPath);
      final snapshot = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) =>
                declaration.namePart.typeName.lexeme == 'SaveSnapshot',
          );
      final canonicalFields = snapshot.body.members
          .whereType<FieldDeclaration>()
          .where(
            (field) => field.fields.variables.any(
              (variable) => variable.name.lexeme == 'canonical',
            ),
          );
      final rawGetters = snapshot.body.members
          .whereType<MethodDeclaration>()
          .where(
            (method) =>
                method.isGetter && method.name.lexeme == 'rawPersistentState',
          );
      final fromCanonical = snapshot.body.members
          .whereType<ConstructorDeclaration>()
          .where(
            (constructor) =>
                constructor.factoryKeyword != null &&
                constructor.name?.lexeme == 'fromCanonical',
          );

      expect(snapshot.finalKeyword, isNotNull);
      expect(canonicalFields, hasLength(1));
      expect(canonicalFields.single.fields.isLate, isTrue);
      expect(rawGetters, hasLength(1));
      expect(fromCanonical, hasLength(1));
    });

    test('persistence and protocol codecs serialize only raw views', () {
      final violations = _serializationBoundaryViolations(
        persistenceSource: File(_persistenceCodecPath).readAsStringSync(),
        protocolSource: File(_protocolCodecPath).readAsStringSync(),
      );

      expect(violations, isEmpty);
    });

    test('local resolver depends on snapshot boundary, not compatibility', () {
      final unit = _unitAt(_localResolverPath);
      final names = _namesIn(unit);
      final imports = unit.directives
          .whereType<UriBasedDirective>()
          .map((directive) => directive.uri.stringValue)
          .whereType<String>();

      expect(
        imports.where(
          (uri) =>
              uri.contains('/compatibility/') ||
              uri.endsWith('/compatibility.dart'),
        ),
        isEmpty,
      );
      expect(
        names.intersection(const {
          'LegacyGameSnapshotAdapter',
          'toCanonical',
          'toLegacy',
        }),
        isEmpty,
      );
      expect(names, containsAll(const {'SaveSnapshot', 'canonical'}));
    });

    test('AST guard catches semantic serialization helper bridges', () {
      final violations = _serializationBoundaryViolations(
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
      final violations = _serializationBoundaryViolations(
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
      final violations = _serializationBoundaryViolations(
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
      final violations = _serializationBoundaryViolations(
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
      final violations = _serializationBoundaryViolations(
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
      final violations = _serializationBoundaryViolations(
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

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

List<String> _serializationBoundaryViolations({
  required String persistenceSource,
  required String protocolSource,
}) {
  return saveSnapshotSerializationBoundaryViolations(
    persistenceSource: persistenceSource,
    protocolSource: protocolSource,
  );
}

Set<String> _namesIn(AstNode node) {
  final collector = _NameCollector();
  node.accept(collector);
  return collector.names;
}

final class _NameCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
