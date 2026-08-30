import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _descriptorPath =
    'packages/aonw_core/lib/game/domain/event/'
    'game_event_domain_descriptor.dart';
const _indexPath =
    'packages/aonw_core/lib/game/domain/event/'
    'game_event_ownership_index.dart';
const _ownershipBoundaryPaths = [_descriptorPath, _indexPath];

void main() {
  group('event audience ownership boundary', () {
    test('ownership descriptors stay persistent-state neutral', () {
      final persistentStateTypes = typeNamesBackedBy(
        productionDartSources(),
        const {'PersistentGameState'},
      );
      for (final path in _ownershipBoundaryPaths) {
        final references = namedTypeReferencesInSource(
          File(path).readAsStringSync(),
          path: path,
        );
        expect(
          references.intersection(persistentStateTypes),
          isEmpty,
          reason: path,
        );
      }
    });

    test('ownership boundary imports stay narrow and state-free', () {
      for (final path in _ownershipBoundaryPaths) {
        final unit = parseString(
          content: File(path).readAsStringSync(),
          path: path,
        ).unit;
        final forbidden = unit.directives
            .whereType<UriBasedDirective>()
            .map((directive) => directive.uri.stringValue)
            .whereType<String>()
            .where((uri) {
              final normalized = uri.toLowerCase();
              return normalized == 'package:aonw_core/domain.dart' ||
                  normalized.contains('/state/') ||
                  normalized.endsWith('/state.dart');
            })
            .toList();

        expect(forbidden, isEmpty, reason: path);
      }
    });

    test('descriptor visibility requires exact previous and next indexes', () {
      final source = File(_descriptorPath).readAsStringSync();
      for (final methodName in const ['isVisibleToPlayer', 'belongsToPlayer']) {
        expect(
          _requiredNamedParameterTypes(
            source,
            path: _descriptorPath,
            className: 'GameEventDomainDescriptor',
            methodName: methodName,
          ),
          const {
            'playerId': 'String',
            'previous': 'GameEventOwnershipIndex',
            'next': 'GameEventOwnershipIndex',
          },
        );
      }
    });

    test('exact-parameter guard rejects optional and positional indexes', () {
      for (final source in const [
        '''
final class Boundary {
  void apply(
    String playerId,
    GameEventOwnershipIndex previous,
    GameEventOwnershipIndex next,
  ) {}
}
''',
        '''
final class Boundary {
  void apply({
    required String playerId,
    GameEventOwnershipIndex previous = fallback,
    GameEventOwnershipIndex next = fallback,
  }) {}
}
''',
      ]) {
        expect(
          _requiredNamedParameterTypes(
            source,
            path: 'fixture.dart',
            className: 'Boundary',
            methodName: 'apply',
          ),
          isEmpty,
        );
      }
    });
  });
}

Map<String, String?> _requiredNamedParameterTypes(
  String source, {
  required String path,
  required String className,
  required String methodName,
}) {
  return _namedParameterTypes(
    source,
    path: path,
    className: className,
    methodName: methodName,
    requireEveryParameter: true,
  );
}

Map<String, String?> _namedParameterTypes(
  String source, {
  required String path,
  required String className,
  required String methodName,
  bool requireEveryParameter = false,
}) {
  final unit = parseString(content: source, path: path).unit;
  final declarations = unit.declarations
      .whereType<ClassDeclaration>()
      .where((declaration) => declaration.namePart.typeName.lexeme == className)
      .toList();
  if (declarations.length != 1) return const {};
  final methods = declarations.single.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == methodName)
      .toList();
  if (methods.length != 1) return const {};

  final result = <String, String?>{};
  for (final parameter
      in methods.single.parameters?.parameters ?? const <FormalParameter>[]) {
    if (parameter is! DefaultFormalParameter ||
        !parameter.isNamed ||
        (requireEveryParameter &&
            (!parameter.isRequiredNamed || parameter.defaultValue != null))) {
      return const {};
    }
    final normalized = parameter.parameter;
    final name = normalized.name?.lexeme;
    if (name == null) return const {};
    result[name] = switch (normalized) {
      SimpleFormalParameter(:final type) => type?.toSource(),
      FieldFormalParameter(:final type) => type?.toSource(),
      _ => null,
    };
  }
  return result;
}
