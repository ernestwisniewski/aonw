import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _transitionPath =
    'packages/aonw_core/lib/game/application/lifecycle/'
    'participant_resignation_transition.dart';
const _applicationPath = 'packages/aonw_core/lib/application.dart';
const _transitionExport =
    'game/application/lifecycle/participant_resignation_transition.dart';

const _requiredApplyParameters = {
  'domain': 'DomainState',
  'session': 'MatchSessionState',
  'actorPlayerId': 'String',
  'orderedHumanPlayerIds': 'Iterable<String>',
};

const _requiredResultFields = {
  'session': 'MatchSessionState',
  'disposition': 'ParticipantResignationDisposition',
  'outcome': 'GameOutcome?',
  'abandonmentReason': 'ParticipantResignationAbandonmentReason?',
};

const _forbiddenTypes = {
  'CanonicalGameSnapshot',
  'GameRuntimeState',
  'GameSave',
  'LegacyGameSnapshotAdapter',
  'PersistentGameState',
  'StoredMatchState',
  'WireMatch',
  'WirePlayer',
  'WireSnapshot',
};

void main() {
  group('participant resignation transition boundary', () {
    test('is a persistence-neutral canonical application kernel', () {
      expect(_transitionViolations(_unitAt(_transitionPath)), isEmpty);
    });

    test('is exported through application but not domain facade', () {
      final application = _unitAt(_applicationPath);
      final exports = application.directives
          .whereType<ExportDirective>()
          .map((directive) => directive.uri.stringValue)
          .whereType<String>()
          .where((uri) => uri == _transitionExport)
          .toList();

      expect(exports, [_transitionExport]);
      expect(
        File('packages/aonw_core/lib/domain.dart').readAsStringSync(),
        isNot(contains(_transitionExport)),
      );
    });

    test('rejects persistence types and a widened public contract', () {
      final violations = _transitionViolations(
        _parse('''
import 'package:aonw_core/game/domain/save.dart';

final class ParticipantResignationResult {
  final PersistentGameState state;
  final MatchSessionState session;
  final ParticipantResignationDisposition disposition;
  final GameOutcome? outcome;
  final ParticipantResignationAbandonmentReason? abandonmentReason;
}

class ParticipantResignationTransition {
  ParticipantResignationResult apply(
    DomainState domain,
    MatchSessionState session,
  ) => throw UnimplementedError();
}
'''),
      );

      expect(
        violations,
        contains('transition must be abstract final with a static apply'),
      );
      expect(
        violations,
        contains('apply must expose exactly four required named parameters'),
      );
      expect(
        violations,
        contains('result must expose only the canonical session decision'),
      );
      expect(
        violations,
        contains('transition must not reference persistence or wire types'),
      );
    });

    test('rejects outcome resolution outside canonical domain entities', () {
      final violations = _transitionViolations(
        _parse('''
abstract final class ParticipantResignationTransition {
  static ParticipantResignationResult apply({
    required DomainState domain,
    required MatchSessionState session,
    required String actorPlayerId,
    required Iterable<String> orderedHumanPlayerIds,
  }) {
    const GameOutcomeResolver().alivePlayerIds(
      playerIds: orderedHumanPlayerIds,
      units: other.units,
      cities: other.cities,
    );
    throw UnimplementedError();
  }
}

final class ParticipantResignationResult {
  final MatchSessionState session;
  final ParticipantResignationDisposition disposition;
  final GameOutcome? outcome;
  final ParticipantResignationAbandonmentReason? abandonmentReason;
}
'''),
      );

      expect(
        violations,
        contains(
          'alive-player resolution must use the supplied canonical domain',
        ),
      );
    });
  });
}

List<String> _transitionViolations(CompilationUnit unit) => [
  ..._publicShapeViolations(unit),
  ..._dependencyViolations(unit),
  ..._alivePlayerResolutionViolations(unit),
];

List<String> _publicShapeViolations(CompilationUnit unit) {
  final transition = _class(unit, 'ParticipantResignationTransition');
  final apply = _method(transition, 'apply');
  final result = _class(unit, 'ParticipantResignationResult');
  return [
    if (transition == null ||
        transition.abstractKeyword == null ||
        transition.finalKeyword == null ||
        apply == null ||
        !apply.isStatic ||
        apply.returnType?.toSource() != 'ParticipantResignationResult')
      'transition must be abstract final with a static apply',
    if (apply == null ||
        !_hasExactRequiredNamedParameters(apply, _requiredApplyParameters))
      'apply must expose exactly four required named parameters',
    if (result == null ||
        result.finalKeyword == null ||
        !_sameStringMap(_instanceFields(result), _requiredResultFields))
      'result must expose only the canonical session decision',
  ];
}

List<String> _dependencyViolations(CompilationUnit unit) {
  final namedTypes = namedTypeReferencesInSource(unit.toSource());
  final uris = unit.directives
      .whereType<UriBasedDirective>()
      .map((directive) => directive.uri.stringValue ?? '')
      .toList();
  final forbiddenUri = uris.any(
    (uri) =>
        !uri.startsWith('package:aonw_core/game/domain/') ||
        uri.contains('/compatibility/') ||
        uri.contains('/protocol') ||
        uri.contains('/save.dart') ||
        uri.contains('persistent_game_state') ||
        uri.contains('aonw_server'),
  );
  return [
    if (namedTypes.intersection(_forbiddenTypes).isNotEmpty || forbiddenUri)
      'transition must not reference persistence or wire types',
  ];
}

List<String> _alivePlayerResolutionViolations(CompilationUnit unit) {
  final transition = _class(unit, 'ParticipantResignationTransition');
  if (transition == null) return const [];
  final collector = _InvocationCollector('alivePlayerIds')..collect(transition);
  if (collector.invocations.length != 1) {
    return const ['transition must resolve alive players exactly once'];
  }
  final arguments = collector.invocations.single.argumentList.arguments
      .whereType<NamedExpression>()
      .fold(<String, String>{}, (values, argument) {
        values[argument.name.label.name] = argument.expression.toSource();
        return values;
      });
  return [
    if (arguments['playerIds'] != 'remainingHumanPlayerIds' ||
        arguments['units'] != 'domain.units' ||
        arguments['cities'] != 'domain.cities')
      'alive-player resolution must use the supplied canonical domain',
  ];
}

ClassDeclaration? _class(CompilationUnit unit, String name) {
  final matches = unit.declarations
      .whereType<ClassDeclaration>()
      .where((declaration) => declaration.namePart.typeName.lexeme == name)
      .toList();
  return matches.length == 1 ? matches.single : null;
}

MethodDeclaration? _method(ClassDeclaration? owner, String name) {
  final matches =
      owner?.body.members
          .whereType<MethodDeclaration>()
          .where((method) => method.name.lexeme == name)
          .toList() ??
      const <MethodDeclaration>[];
  return matches.length == 1 ? matches.single : null;
}

Map<String, String> _instanceFields(ClassDeclaration owner) {
  final fields = <String, String>{};
  for (final declaration in owner.body.members.whereType<FieldDeclaration>()) {
    if (declaration.isStatic) continue;
    final type = declaration.fields.type?.toSource();
    if (type == null) continue;
    for (final variable in declaration.fields.variables) {
      fields[variable.name.lexeme] = type;
    }
  }
  return fields;
}

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      right.entries.every((entry) => left[entry.key] == entry.value);
}

bool _hasExactRequiredNamedParameters(
  MethodDeclaration method,
  Map<String, String> expected,
) {
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != expected.length) return false;
  final actual = <String, String>{};
  for (final parameter in parameters) {
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) {
      return false;
    }
    final normalized = parameter.parameter;
    if (normalized is! SimpleFormalParameter ||
        normalized.requiredKeyword == null ||
        normalized.type == null ||
        normalized.name == null) {
      return false;
    }
    actual[normalized.name!.lexeme] = normalized.type!.toSource();
  }
  return actual.length == expected.length &&
      expected.entries.every((entry) => actual[entry.key] == entry.value);
}

final class _InvocationCollector extends RecursiveAstVisitor<void> {
  _InvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> invocations = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

CompilationUnit _parse(String source) => parseString(content: source).unit;
