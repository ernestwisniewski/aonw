import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

part 'support/player_view_state_boundary_guard.dart';

const _projectorPath =
    'server/lib/src/multiplayer/player_match_view_projector.dart';
const _stateProjectorPath =
    'server/lib/src/multiplayer/player_view_state_projector.dart';
const _viewStatePath =
    'packages/aonw_core/lib/game/view/player_view_state.dart';

void main() {
  test('player projection decodes canonical state once before fanout', () {
    final matchUnit = _unitAt(_projectorPath);
    final matchProjector = _classNamed(matchUnit, 'PlayerMatchViewProjector');
    final stateProjector = _classNamed(
      _unitAt(_stateProjectorPath),
      'PlayerViewStateProjector',
    );

    _expectCanonicalProjectionInputs(
      matchUnit: matchUnit,
      matchProjector: matchProjector,
      stateProjector: stateProjector,
    );
    _expectSnapshotPreparationOrder(matchProjector);
    _expectFanoutPreparationBoundary(matchProjector);
    _expectLosslessDecoderBoundary(matchUnit);
  });

  test('fanout guard rejects decoder use hidden in a helper', () {
    final unit = parseString(
      content: '''
final class PlayerMatchViewProjector {
  void projectSnapshot(Object prepared) {
    _hiddenProjectionHelper(prepared);
  }

  void _hiddenProjectionHelper(Object prepared) {
    _decodeSnapshot(prepared);
  }
}
''',
      path: 'fixture.dart',
    ).unit;
    final projector = _classNamed(unit, 'PlayerMatchViewProjector');

    expect(_fanoutCapabilityViolations(projector), {
      '_hiddenProjectionHelper': {'_decodeSnapshot'},
    });
  });

  test('preparation wrapper guard rejects duplicate snapshot preparation', () {
    final unit = parseString(
      content: '''
final class PlayerMatchViewProjector {
  Object snapshotFor(Object canonical, Object recipient) {
    prepareSnapshot(canonical);
    return projectSnapshot(prepareSnapshot(canonical), recipient);
  }
}
''',
      path: 'fixture.dart',
    ).unit;
    final projector = _classNamed(unit, 'PlayerMatchViewProjector');

    expect(_preparationWrapperViolations(projector), {
      'snapshotFor': 'projectSnapshot(prepareSnapshot(canonical), recipient)',
    });
  });

  test('player projection returns and constructs only nominal view state', () {
    final sources = productionDartSources();
    final matchProjector = _classNamed(
      _unitAt(_projectorPath),
      'PlayerMatchViewProjector',
    );
    final stateFor = matchProjector.body.members
        .whereType<MethodDeclaration>()
        .singleWhere((member) => member.name.lexeme == '_stateFor');
    final stateProjector = _classNamed(
      _unitAt(_stateProjectorPath),
      'PlayerViewStateProjector',
    );
    final project = stateProjector.body.members
        .whereType<MethodDeclaration>()
        .singleWhere((member) => member.name.lexeme == 'project');

    expect(stateFor.returnType?.toSource(), 'PlayerViewState');
    expect(project.returnType?.toSource(), 'PlayerViewState');

    final outsideStateProjector = Map<String, String>.from(sources)
      ..remove(_stateProjectorPath);
    expect(
      constructedTypeViolations(outsideStateProjector, type: 'PlayerViewState'),
      isEmpty,
    );
  });

  test('canonical reducers, stores, AI, and replay reject player views', () {
    final violations = <String>[];
    for (final entry in productionDartSources().entries) {
      if (!_isCanonicalStateSubsystem(entry.key)) continue;
      violations.addAll(
        sourceSymbolReferenceViolations(
          entry.value,
          entry.key,
          symbol: 'PlayerViewState',
        ),
      );
    }

    expect(violations, isEmpty);
  });

  test(
    'player view exposes identity and wire encoding, not canonical state',
    () {
      final viewState = _classNamed(_unitAt(_viewStatePath), 'PlayerViewState');
      final violations = <String>[];
      for (final member in viewState.body.members) {
        switch (member) {
          case FieldDeclaration(:final fields):
            final exposesCanonicalState = _namedTypes(
              fields.type,
            ).any(const {'PersistentGameState', 'DomainState'}.contains);
            for (final variable in fields.variables) {
              if (!variable.name.lexeme.startsWith('_') &&
                  exposesCanonicalState) {
                violations.add(variable.name.lexeme);
              }
            }
          case MethodDeclaration(:final name, :final returnType):
            if (!name.lexeme.startsWith('_') &&
                _namedTypes(
                  returnType,
                ).any(const {'PersistentGameState', 'DomainState'}.contains)) {
              violations.add(name.lexeme);
            }
          default:
            break;
        }
      }

      expect(violations, isEmpty);
    },
  );
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

ClassDeclaration _classNamed(CompilationUnit unit, String name) {
  return unit.declarations.whereType<ClassDeclaration>().singleWhere(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
}

MethodDeclaration _methodNamed(ClassDeclaration declaration, String name) {
  return declaration.body.members.whereType<MethodDeclaration>().singleWhere(
    (member) => member.name.lexeme == name,
  );
}

FunctionDeclaration _functionNamed(CompilationUnit unit, String name) {
  return unit.declarations.whereType<FunctionDeclaration>().singleWhere(
    (declaration) => declaration.name.lexeme == name,
  );
}

Map<String, String> _fieldTypes(ClassDeclaration declaration) {
  return {
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      for (final variable in field.fields.variables)
        variable.name.lexeme: field.fields.type?.toSource() ?? '',
  };
}

Map<String, String> _parameterTypes(MethodDeclaration method) {
  return {
    for (final parameter
        in method.parameters?.parameters ?? const <FormalParameter>[])
      if (_normalizedParameter(parameter)
          case final SimpleFormalParameter parameter)
        parameter.name?.lexeme ?? '': parameter.type?.toSource() ?? '',
  };
}

Set<String> _fieldAndParameterTypes(ClassDeclaration declaration) {
  final types = <String>{};
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    field.fields.type?.accept(_NamedTypeCollector(types));
  }
  for (final method
      in declaration.body.members.whereType<MethodDeclaration>()) {
    for (final parameter
        in method.parameters?.parameters ?? const <FormalParameter>[]) {
      _normalizedParameter(parameter).accept(_NamedTypeCollector(types));
    }
  }
  return types;
}

FormalParameter _normalizedParameter(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

int _identifierCount(AstNode node, String name) {
  final collector = _IdentifierCollector(name);
  node.accept(collector);
  return collector.count;
}

MethodInvocation _singleCall(AstNode node, String name) {
  final collector = _MethodCallCollector(name);
  node.accept(collector);
  return collector.calls.single;
}

Expression? _singleReturnedExpression(FunctionBody body) {
  if (body is! BlockFunctionBody || body.block.statements.length != 1) {
    return null;
  }
  final statement = body.block.statements.single;
  return statement is ReturnStatement ? statement.expression : null;
}

const _projectionCapabilities = {
  '_decodeSnapshot',
  '_decodePlayerMatchSnapshot',
  '_playerMatchSnapshotDecoder',
  'LosslessMatchSnapshotDecoder',
  'LosslessMatchSnapshotCodec',
  'DecodedRunningMatchSnapshot',
  'RunningMatchSnapshotCodec',
  'decode',
  'toCanonical',
  'toLegacy',
  'LegacyGameSnapshotAdapter',
  'prepareSnapshot',
  'prepareMessage',
  'snapshotFor',
  'messageFor',
  'ackFor',
};

Set<String> _projectionCapabilityReferences(AstNode node) {
  return {
    for (final capability in _projectionCapabilities)
      if (_identifierCount(node, capability) > 0) capability,
  };
}

Map<String, Set<String>> _fanoutCapabilityViolations(
  ClassDeclaration projector,
) {
  const preparationEntryPoints = {
    'prepareSnapshot',
    'prepareMessage',
    'snapshotFor',
    'messageFor',
    'ackFor',
  };
  return {
    for (final method in projector.body.members.whereType<MethodDeclaration>())
      if (!preparationEntryPoints.contains(method.name.lexeme) &&
          _projectionCapabilityReferences(method.body).isNotEmpty)
        method.name.lexeme: _projectionCapabilityReferences(method.body),
  };
}

bool _isCanonicalStateSubsystem(String path) {
  return path.startsWith('packages/aonw_core/lib/ai/') ||
      path.startsWith('lib/game/domain/ai/') ||
      path.startsWith('lib/game/domain/reducer/') ||
      path.startsWith('server/lib/src/multiplayer/multiplayer_match_store') ||
      path.startsWith('server/lib/src/multiplayer/server_command_reducer') ||
      path.contains('/replay/');
}

Set<String> _namedTypes(AstNode? node) {
  if (node == null) return const {};
  final types = <String>{};
  node.accept(_NamedTypeCollector(types));
  return types;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  _NamedTypeCollector(this.types);

  final Set<String> types;

  @override
  void visitNamedType(NamedType node) {
    types.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.name);

  final String name;
  int count = 0;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) count += 1;
    super.visitSimpleIdentifier(node);
  }
}

final class _MethodCallCollector extends RecursiveAstVisitor<void> {
  _MethodCallCollector(this.name);

  final String name;
  final List<MethodInvocation> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) calls.add(node);
    super.visitMethodInvocation(node);
  }
}
