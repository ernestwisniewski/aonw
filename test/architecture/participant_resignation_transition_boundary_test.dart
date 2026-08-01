import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

const _transitionPath =
    'packages/aonw_core/lib/game/application/lifecycle/'
    'participant_resignation_transition.dart';
const _applicationPath = 'packages/aonw_core/lib/application.dart';
const _transitionExport =
    'game/application/lifecycle/participant_resignation_transition.dart';

void main() {
  group('participant resignation decision boundary', () {
    test('reads canonical domain state without mutating it', () {
      final unit = _unitAt(_transitionPath);
      final transition = _class(unit, 'ParticipantResignationTransition');
      final resolve = _method(transition, 'resolve');
      final result = _class(unit, 'ParticipantResignationResult');

      expect(transition.abstractKeyword, isNotNull);
      expect(transition.finalKeyword, isNotNull);
      expect(resolve.isStatic, isTrue);
      expect(resolve.returnType?.toSource(), 'ParticipantResignationResult');
      expect(_requiredNamedParameters(resolve), {
        'domain': 'DomainState',
        'orderedHumanPlayerIds': 'Iterable<String>',
      });
      expect(_instanceFields(result), {
        'disposition': 'ParticipantResignationDisposition',
        'outcome': 'GameOutcome?',
        'abandonmentReason': 'ParticipantResignationAbandonmentReason?',
      });
      expect(resolve.body.toSource(), isNot(contains('copyWith')));
      expect(resolve.body.toSource(), isNot(contains('GameEngine')));
    });

    test('uses domain entities for the single alive-player decision', () {
      final source = File(_transitionPath).readAsStringSync();

      expect(
        RegExp(r'GameOutcomeResolver\(\)\.alivePlayerIds\(').allMatches(source),
        hasLength(1),
      );
      expect(source, contains('units: domain.units'));
      expect(source, contains('cities: domain.cities'));
      expect(source, contains('if (!domain.isKicked(playerId)) playerId'));
    });

    test('is exported only through the application facade', () {
      final application = _unitAt(_applicationPath);
      final exports = application.directives
          .whereType<ExportDirective>()
          .map((directive) => directive.uri.stringValue)
          .whereType<String>()
          .where((uri) => uri == _transitionExport);

      expect(exports, [_transitionExport]);
      expect(
        File('packages/aonw_core/lib/domain.dart').readAsStringSync(),
        isNot(contains(_transitionExport)),
      );
    });
  });
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

ClassDeclaration _class(CompilationUnit unit, String name) => unit.declarations
    .whereType<ClassDeclaration>()
    .singleWhere((declaration) => declaration.namePart.typeName.lexeme == name);

MethodDeclaration _method(ClassDeclaration owner, String name) => owner
    .body
    .members
    .whereType<MethodDeclaration>()
    .singleWhere((method) => method.name.lexeme == name);

Map<String, String> _requiredNamedParameters(MethodDeclaration method) => {
  for (final parameter in method.parameters?.parameters ?? const [])
    if (parameter is DefaultFormalParameter && parameter.isRequiredNamed)
      parameter.name!.lexeme:
          (parameter.parameter as SimpleFormalParameter).type?.toSource() ?? '',
};

Map<String, String> _instanceFields(ClassDeclaration owner) => {
  for (final field in owner.body.members.whereType<FieldDeclaration>())
    if (!field.isStatic)
      for (final variable in field.fields.variables)
        variable.name.lexeme: field.fields.type?.toSource() ?? '',
};
