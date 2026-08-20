import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/presentation_parity_actions.dart';

const _commandDirectory = 'packages/aonw_core/lib/game/domain/command';

void main() {
  test('presentation parity owns every concrete player action', () {
    final declarations = _commandDeclarations();
    final domainCommands = _concreteSubtypesOf('DomainCommand', declarations);
    final intents = _concreteSubtypesOf('GameIntent', declarations);

    expect(
      presentationDomainCommands
          .map((command) => '${command.runtimeType}')
          .toSet(),
      domainCommands,
    );
    expect(
      presentationGameIntents.map((intent) => '${intent.runtimeType}').toSet(),
      intents,
    );
    expect(domainCommands, hasLength(39));
    expect(intents, hasLength(28));
  });

  test('client interaction parity cannot branch on local or network mode', () {
    final source = File(
      'lib/game/application/services/game_intent_resolver.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('GameMode')));
    expect(source, isNot(contains('multiplayer')));
    expect(source, isNot(contains('singlePlayer')));
  });
}

Map<String, String?> _commandDeclarations() {
  final declarations = <String, String?>{};
  for (final entity in Directory(_commandDirectory).listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final unit = parseString(
      content: entity.readAsStringSync(),
      path: entity.path,
      throwIfDiagnostics: false,
    ).unit;
    for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
      declarations[declaration.namePart.typeName.lexeme] = declaration
          .extendsClause
          ?.superclass
          .toSource();
    }
  }
  return declarations;
}

Set<String> _concreteSubtypesOf(
  String base,
  Map<String, String?> declarations,
) {
  return {
    for (final name in declarations.keys)
      if (name != base &&
          _inheritsFrom(name, base, declarations) &&
          !_isAbstractCommandBase(name))
        name,
  };
}

bool _inheritsFrom(
  String name,
  String base,
  Map<String, String?> declarations,
) {
  var parent = declarations[name];
  while (parent != null) {
    if (parent == base) return true;
    parent = declarations[parent];
  }
  return false;
}

bool _isAbstractCommandBase(String name) {
  return const {
    'CityTargetGameIntent',
    'CityTargetDomainCommand',
    'DiplomaticCommand',
    'UnitDomainCommand',
    'UnitIdDomainCommand',
    'AutomatedUnitCommand',
  }.contains(name);
}
