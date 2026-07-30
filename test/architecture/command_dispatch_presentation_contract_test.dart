import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

const _presentationsPath =
    'lib/game/presentation/providers/game/'
    'game_actions_provider_presentations.dart';

void main() {
  test('command dispatch presentation always owns a non-null command', () {
    final unit = parseString(
      content: File(_presentationsPath).readAsStringSync(),
      path: _presentationsPath,
      throwIfDiagnostics: false,
    ).unit;
    final record = unit.declarations.whereType<ClassDeclaration>().singleWhere(
      (declaration) =>
          declaration.namePart.typeName.lexeme == '_CommandDispatchRecord',
    );
    final commandField = record.body.members
        .whereType<FieldDeclaration>()
        .singleWhere(
          (field) => field.fields.variables.any(
            (variable) => variable.name.lexeme == 'command',
          ),
        );

    expect(commandField.fields.type?.toSource(), 'GameCommand');
    expect(commandField.fields.isFinal, isTrue);
  });
}
