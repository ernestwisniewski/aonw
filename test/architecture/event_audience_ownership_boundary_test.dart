import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _descriptorPath =
    'packages/aonw_core/lib/game/domain/event/'
    'game_event_domain_descriptor.dart';
const _indexPath =
    'packages/aonw_core/lib/game/domain/event/'
    'game_event_ownership_index.dart';
const _audiencePath =
    'server/lib/src/multiplayer/player_match_event_audience.dart';
const _servicePath = 'server/lib/src/multiplayer/match_command_service.dart';
const _ownershipBoundaryPaths = [_descriptorPath, _indexPath, _audiencePath];

void main() {
  group('event audience ownership boundary', () {
    test('descriptor and server audience stay persistent-state neutral', () {
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

    test(
      'server annotation accepts only reviewed canonical audience inputs',
      () {
        const path = _audiencePath;
        final source = File(path).readAsStringSync();

        expect(
          _namedParameterTypes(
            source,
            path: path,
            className: 'PlayerMatchEventAudience',
            methodName: 'annotateForStorage',
          ),
          const {
            'events': 'Iterable<GameEvent>',
            'participantPlayerIds': 'Iterable<String>',
            'previous': 'GameEventOwnershipIndex',
            'next': 'GameEventOwnershipIndex',
            'combatAnimations': 'Iterable<CombatAnimationFact>',
            'previousFog': 'FogOfWarState',
            'nextFog': 'FogOfWarState',
            'exactMovementAudienceByUnit': 'Map<String, Set<String>>',
          },
        );
      },
    );

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

    test('server skips ownership indexing when a reduction has no events', () {
      final unit = parseString(
        content: File(_servicePath).readAsStringSync(),
        path: _servicePath,
      ).unit;
      final helpers = unit.declarations
          .whereType<FunctionDeclaration>()
          .where(
            (declaration) =>
                declaration.name.lexeme == '_eventAudienceForStorage',
          )
          .toList();
      expect(helpers, hasLength(1));

      final body = helpers.single.functionExpression.body;
      expect(body, isA<BlockFunctionBody>());
      final statements = (body as BlockFunctionBody).block.statements;
      expect(statements, isNotEmpty);
      final first = statements.first;
      expect(first, isA<IfStatement>());
      final guard = first as IfStatement;
      expect(guard.expression.toSource(), 'events.isEmpty');
      expect(guard.thenStatement, isA<ReturnStatement>());
      final returned = (guard.thenStatement as ReturnStatement).expression;
      expect(returned, isA<ListLiteral>());
      final emptyList = returned! as ListLiteral;
      expect(emptyList.constKeyword, isNotNull);
      expect(emptyList.elements, isEmpty);

      final factories = _OwnershipFactoryVisitor()..collect(body);
      expect(factories.invocations, hasLength(2));
      expect(
        factories.invocations.every(
          (invocation) => invocation.offset > guard.end,
        ),
        isTrue,
      );
    });
  });
}

final class _OwnershipFactoryVisitor extends RecursiveAstVisitor<void> {
  final invocations = <MethodInvocation>[];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target?.toSource() == 'GameEventOwnershipIndex' &&
        node.methodName.name == 'from') {
      invocations.add(node);
    }
    super.visitMethodInvocation(node);
  }
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
