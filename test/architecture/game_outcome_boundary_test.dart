import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _resolverPath =
    'packages/aonw_core/lib/game/domain/outcome/game_outcome_resolver.dart';
const _detectorPath =
    'packages/aonw_core/lib/game/domain/outcome/game_outcome_detector.dart';
const _forbiddenResolverStateTypes = {
  'PersistentGameState',
  'GameRuntimeState',
  'GameSave',
  'DomainState',
  'MatchSessionState',
  'CanonicalGameSnapshot',
};
const _resolveRequiredParameters = {
  'playerIds': 'Iterable<String>',
  'units': 'Iterable<GameUnit>',
  'cities': 'Iterable<GameCity>',
  'artifacts': 'Iterable<WorldArtifact>',
  'fieldImprovements': 'Iterable<FieldImprovement>',
  'research': 'ResearchState',
  'playerGold': 'Map<String, int>',
  'dominationHoldTurnsByPlayerId': 'Map<String, int>',
  'culturalVictoryHoldTurnsByPlayerId': 'Map<String, int>',
  'mapObjectiveHoldStatesByObjectiveId': 'Map<String, MapObjectiveHoldState>',
  'matchRules': 'MatchRules',
};
const _resolveOptionalParameters = {'mapData': 'MapReadView?', 'turn': 'int?'};
const _alivePlayerRequiredParameters = {
  'playerIds': 'Iterable<String>',
  'units': 'Iterable<GameUnit>',
  'cities': 'Iterable<GameCity>',
};

void main() {
  group('game outcome boundary', () {
    test('outcome resolver remains a persistence-neutral kernel', () {
      final resolver = _unitAt(_resolverPath);
      final namedTypes = _NamedTypeCollector()..collect(resolver);
      final forbiddenTypes = typeNamesBackedBy(
        productionDartSources(),
        _forbiddenResolverStateTypes,
      );
      expect(namedTypes.names.intersection(forbiddenTypes), isEmpty);
      expect(
        _methodContract(resolver, 'GameOutcomeResolver', 'resolve'),
        const _MethodContract(
          requiredNamed: _resolveRequiredParameters,
          optionalNamed: _resolveOptionalParameters,
        ),
      );
      expect(
        _methodContract(resolver, 'GameOutcomeResolver', 'alivePlayerIds'),
        const _MethodContract(
          requiredNamed: _alivePlayerRequiredParameters,
          optionalNamed: {},
        ),
      );
    });

    test('canonical detector entry requires only domain state', () {
      expect(
        _methodContract(
          _unitAt(_detectorPath),
          'GameOutcomeDetector',
          'evaluateCanonical',
        ),
        const _MethodContract(
          requiredNamed: {'state': 'DomainState'},
          optionalNamed: {'mapData': 'MapReadView?'},
        ),
      );
    });
  });
}

_MethodContract? _methodContract(
  CompilationUnit unit,
  String ownerName,
  String methodName,
) {
  final owner = _singleClass(unit, ownerName);
  final method = owner == null ? null : _singleMethod(owner, methodName);
  if (method == null) return null;
  final required = <String, String>{};
  final optional = <String, String>{};
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) continue;
    final normalized = parameter.parameter;
    if (normalized is! SimpleFormalParameter || normalized.name == null) {
      continue;
    }
    final target = normalized.requiredKeyword == null ? optional : required;
    target[normalized.name!.lexeme] = normalized.type?.toSource() ?? '';
  }
  return _MethodContract(requiredNamed: required, optionalNamed: optional);
}

ClassDeclaration? _singleClass(CompilationUnit unit, String name) {
  final matches = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
  return matches.length == 1 ? matches.single : null;
}

MethodDeclaration? _singleMethod(AstNode owner, String name) {
  final collector = _MethodCollector(name)..collect(owner);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

bool _sameMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      right.entries.every((entry) => left[entry.key] == entry.value);
}

final class _MethodContract {
  const _MethodContract({
    required this.requiredNamed,
    required this.optionalNamed,
  });

  final Map<String, String> requiredNamed;
  final Map<String, String> optionalNamed;

  @override
  bool operator ==(Object other) =>
      other is _MethodContract &&
      _sameMap(requiredNamed, other.requiredNamed) &&
      _sameMap(optionalNamed, other.optionalNamed);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(requiredNamed.entries),
    Object.hashAllUnordered(optionalNamed.entries),
  );
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

final class _MethodCollector extends RecursiveAstVisitor<void> {
  _MethodCollector(this.name);

  final String name;
  final List<MethodDeclaration> methods = [];

  void collect(AstNode node) => node.accept(this);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }
}
