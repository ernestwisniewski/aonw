import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _selectorPath =
    'packages/aonw_core/lib/game/application/turn/timeout_actor_selector.dart';
const _timeoutServicePath =
    'server/lib/src/multiplayer/match_command_service_timeout.dart';

const _requiredParameters = {
  'orderedParticipantPlayerIds': 'Iterable<String>',
  'submittedPlayerIds': 'Set<String>',
  'kickedPlayerIds': 'Set<String>',
};

const _forbiddenTypes = {
  'GameSave',
  'PersistentGameState',
  'GameRuntimeState',
  'DomainState',
  'MatchSessionState',
  'CanonicalGameSnapshot',
  'WireMatch',
  'WirePlayer',
  'WireSnapshot',
  'ServerCommandReducer',
};

void main() {
  group('timeout actor selector boundary', () {
    test('selector is an exact persistence-neutral collection kernel', () {
      expect(_selectorViolations(_unitAt(_selectorPath)), isEmpty);
    });

    test('selector has exactly one production call site', () {
      expect(
        staticMemberReferenceCountsByPath(
          productionDartSources(),
          'TimeoutActorSelector',
          'select',
        ),
        {_timeoutServicePath: 1},
      );
    });

    test('rejects optional, positional, and typed API drift', () {
      final optional = _parse('''
abstract final class TimeoutActorSelector {
  static String? select({
    Iterable<String> orderedParticipantPlayerIds = const [],
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) => null;
}
''');
      final positional = _parse('''
abstract final class TimeoutActorSelector {
  static String? select(
    Iterable<String> orderedParticipantPlayerIds,
    Set<String> submittedPlayerIds,
    Set<String> kickedPlayerIds,
  ) => null;
}
''');
      final wrongType = _parse('''
abstract final class TimeoutActorSelector {
  static String? select({
    required List<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) => null;
}
''');

      expect(
        _selectorViolations(optional),
        contains('select must expose exactly three required named parameters'),
      );
      expect(
        _selectorViolations(positional),
        contains('select must expose exactly three required named parameters'),
      );
      expect(
        _selectorViolations(wrongType),
        contains('select must expose exactly three required named parameters'),
      );
    });

    test('rejects state, wire, server, and imported dependencies', () {
      final unit = _parse('''
import 'state.dart';

abstract final class TimeoutActorSelector {
  static String? select({
    required Iterable<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) {
    MatchSessionState? leakedState;
    return leakedState == null ? null : '';
  }
}
''');

      expect(
        _selectorViolations(unit),
        contains('selector must not import dependencies'),
      );
      expect(
        _selectorViolations(unit),
        contains('selector must not reference MatchSessionState'),
      );
    });

    test('rejects generic and inherited public shape', () {
      final unit = _parse('''
abstract final class TimeoutActorSelector<T> implements Function {
  static String? select<U>({
    required Iterable<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) => null;
}
''');

      expect(
        _selectorViolations(unit),
        contains('TimeoutActorSelector must not be generic or inherit types'),
      );
      expect(
        _selectorViolations(unit),
        contains('select must not declare type parameters'),
      );
    });

    test('rejects every sorting reference form', () {
      const fixtures = {
        'direct': '''
abstract final class TimeoutActorSelector {
  static String? select({
    required Iterable<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) {
    final sorted = orderedParticipantPlayerIds.toList();
    sorted.sort();
    return sorted.first;
  }
}
''',
        'cascade': '''
abstract final class TimeoutActorSelector {
  static String? select({
    required Iterable<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) {
    final sorted = orderedParticipantPlayerIds.toList()..sort();
    return sorted.first;
  }
}
''',
        'tear-off': '''
abstract final class TimeoutActorSelector {
  static String? select({
    required Iterable<String> orderedParticipantPlayerIds,
    required Set<String> submittedPlayerIds,
    required Set<String> kickedPlayerIds,
  }) {
    final values = orderedParticipantPlayerIds.toList();
    final sorter = values.sort;
    sorter();
    return values.first;
  }
}
''',
      };

      for (final entry in fixtures.entries) {
        expect(
          _selectorViolations(_parse(entry.value)),
          contains('selector must preserve participant order without sort()'),
          reason: entry.key,
        );
      }
    });
  });
}

List<String> _selectorViolations(CompilationUnit unit) => [
  ..._selectorLibraryViolations(unit),
  ..._selectorClassViolations(unit),
  ..._selectorMethodViolations(unit),
  ..._selectorDependencyViolations(unit),
  ..._selectorOrderViolations(unit),
];

List<String> _selectorLibraryViolations(CompilationUnit unit) => [
  if (unit.directives.isNotEmpty) 'selector must not import dependencies',
  if (_selectorClass(unit) == null)
    'selector library must declare only TimeoutActorSelector',
];

ClassDeclaration? _selectorClass(CompilationUnit unit) {
  if (unit.declarations.length != 1) return null;
  final declaration = unit.declarations.single;
  if (declaration is! ClassDeclaration ||
      declaration.namePart.typeName.lexeme != 'TimeoutActorSelector') {
    return null;
  }
  return declaration;
}

List<String> _selectorClassViolations(CompilationUnit unit) {
  final selector = _selectorClass(unit);
  if (selector == null) return const [];
  final disallowedModifiers = [
    selector.augmentKeyword,
    selector.baseKeyword,
    selector.interfaceKeyword,
    selector.mixinKeyword,
    selector.sealedKeyword,
  ].whereType<Object>();
  final inheritsTypes =
      selector.namePart.typeParameters != null ||
      selector.extendsClause != null ||
      selector.withClause != null ||
      selector.implementsClause != null ||
      selector.nativeClause != null;
  return [
    if (selector.abstractKeyword == null || selector.finalKeyword == null)
      'TimeoutActorSelector must be abstract final',
    if (disallowedModifiers.isNotEmpty)
      'TimeoutActorSelector must use no other class modifier',
    if (inheritsTypes)
      'TimeoutActorSelector must not be generic or inherit types',
  ];
}

MethodDeclaration? _selectMethod(ClassDeclaration selector) {
  if (selector.body.members.length != 1) return null;
  final member = selector.body.members.single;
  if (member is! MethodDeclaration || member.name.lexeme != 'select') {
    return null;
  }
  return member;
}

List<String> _selectorMethodViolations(CompilationUnit unit) {
  final selector = _selectorClass(unit);
  if (selector == null) return const [];
  final select = _selectMethod(selector);
  if (select == null) {
    return const ['TimeoutActorSelector must declare only select'];
  }
  final hasWrongShape =
      !select.isStatic ||
      select.isAbstract ||
      select.isGetter ||
      select.isOperator ||
      select.isSetter ||
      select.augmentKeyword != null ||
      select.externalKeyword != null ||
      select.returnType?.toSource() != 'String?';
  return [
    if (hasWrongShape) 'select must be static and return String?',
    if (select.typeParameters != null)
      'select must not declare type parameters',
    if (_methodContract(select) !=
        const _ParameterContract(requiredNamed: _requiredParameters))
      'select must expose exactly three required named parameters',
  ];
}

List<String> _selectorDependencyViolations(CompilationUnit unit) {
  final namedTypes = _NamedTypeCollector()..collect(unit);
  return [
    for (final type in namedTypes.names.intersection(_forbiddenTypes))
      'selector must not reference $type',
  ];
}

List<String> _selectorOrderViolations(CompilationUnit unit) {
  final sortReferences = _IdentifierReferenceCollector('sort')..collect(unit);
  return [
    if (sortReferences.references.isNotEmpty)
      'selector must preserve participant order without sort()',
  ];
}

_ParameterContract _methodContract(MethodDeclaration method) {
  final requiredNamed = <String, String?>{};
  final optionalNamed = <String, String?>{};
  final positional = <String, String?>{};
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    final normalized = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;
    final name = normalized.name?.lexeme ?? '<unnamed>';
    final type = switch (normalized) {
      SimpleFormalParameter(:final type) => type?.toSource(),
      FieldFormalParameter(:final type) => type?.toSource(),
      _ => null,
    };
    if (parameter is DefaultFormalParameter &&
        parameter.isNamed &&
        normalized.requiredKeyword != null) {
      requiredNamed[name] = type;
    } else if (parameter is DefaultFormalParameter && parameter.isNamed) {
      optionalNamed[name] = type;
    } else {
      positional[name] = type;
    }
  }
  return _ParameterContract(
    requiredNamed: requiredNamed,
    optionalNamed: optionalNamed,
    positional: positional,
  );
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

CompilationUnit _parse(String source) => parseString(content: source).unit;

final class _ParameterContract {
  const _ParameterContract({
    required this.requiredNamed,
    this.optionalNamed = const {},
    this.positional = const {},
  });

  final Map<String, String?> requiredNamed;
  final Map<String, String?> optionalNamed;
  final Map<String, String?> positional;

  @override
  bool operator ==(Object other) =>
      other is _ParameterContract &&
      _sameMap(requiredNamed, other.requiredNamed) &&
      _sameMap(optionalNamed, other.optionalNamed) &&
      _sameMap(positional, other.positional);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(requiredNamed.entries),
    Object.hashAllUnordered(optionalNamed.entries),
    Object.hashAllUnordered(positional.entries),
  );
}

bool _sameMap(Map<String, String?> left, Map<String, String?> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  void collect(AstNode node) => node.accept(this);

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

final class _IdentifierReferenceCollector extends RecursiveAstVisitor<void> {
  _IdentifierReferenceCollector(this.name);

  final String name;
  final List<SimpleIdentifier> references = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name && node.parent is! Label) references.add(node);
    super.visitSimpleIdentifier(node);
  }
}
