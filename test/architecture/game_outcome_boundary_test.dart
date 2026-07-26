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
const _serverReducerPath =
    'server/lib/src/multiplayer/server_command_reducer.dart';
const _serverOutcomePath =
    'server/lib/src/multiplayer/server_command_reducer_outcome.dart';

const _forbiddenResolverStateTypes = {
  'PersistentGameState',
  'GameRuntimeState',
  'GameSave',
  'DomainState',
  'MatchSessionState',
  'CanonicalGameSnapshot',
};
const _forbiddenReducerBoundaryTypes = {
  'PersistentGameState',
  'GameRuntimeState',
  'GameSave',
  'WireSnapshot',
  'DecodedMatchSnapshot',
  'DecodedRunningMatchSnapshot',
  'LegacyGameSnapshotAdapter',
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
  group('game outcome and canonical reducer boundary', () {
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

    test('canonical detector entry requires domain and session state', () {
      expect(
        _methodContract(
          _unitAt(_detectorPath),
          'GameOutcomeDetector',
          'evaluateCanonical',
        ),
        const _MethodContract(
          requiredNamed: {
            'state': 'DomainState',
            'session': 'MatchSessionState',
          },
          optionalNamed: {'mapData': 'MapReadView?'},
        ),
      );
    });

    test('server reducer owns one canonical input and output only', () {
      final sources = _serverReducerSources();
      expect(_canonicalReducerBoundaryViolations(sources), isEmpty);

      final reducer = sources[_serverReducerPath]!;
      expect(
        _methodContract(reducer, 'ServerCommandReducer', 'reduce'),
        const _MethodContract(
          requiredNamed: {
            'match': 'WireMatch',
            'snapshot': 'CanonicalGameSnapshot',
            'wireCommand': 'WireCommand',
            'actorPlayerId': 'String',
            'now': 'DateTime',
          },
          optionalNamed: {},
        ),
      );
      expect(
        _methodContract(reducer, 'ServerCommandReducer', 'reduceTimedOutTurn'),
        const _MethodContract(
          requiredNamed: {
            'match': 'WireMatch',
            'snapshot': 'CanonicalGameSnapshot',
            'actorPlayerId': 'String',
            'now': 'DateTime',
          },
          optionalNamed: {},
        ),
      );
    });

    test('accepted reduction evaluates outcome from its canonical result', () {
      final outcome = _unitAt(_serverOutcomePath);
      final method = _singleMethod(outcome, '_acceptedReduction')!;
      final body = method.body.toSource();
      expect(_namedParameterTypes(method), {
        'match': 'WireMatch',
        'result': '_CommandApplication',
        'mapView': 'MapReadView',
      });
      expect(body, contains('final nextSnapshot = result.snapshot;'));
      expect(body, contains('nextSnapshot: nextSnapshot'));
      expect(body, contains('domain: nextSnapshot.domain'));
      expect(body, contains('session: nextSnapshot.session'));
      expect(body, isNot(contains('encode(')));
      expect(body, isNot(contains('toCanonical')));
      expect(body, isNot(contains('toLegacy')));
    });

    test('guard fails closed around aliases, fields, and conversions', () {
      const fixturePath =
          'server/lib/src/multiplayer/server_command_reducer_bad.dart';
      final sources = <String, CompilationUnit>{
        fixturePath: parseString(
          path: fixturePath,
          content: '''
typedef HiddenState = PersistentGameState;
final WireSnapshot snapshot = throw UnimplementedError();
void convert(LegacyGameSnapshotAdapter adapter) {
  final conversion = adapter.toLegacy;
}
''',
        ).unit,
      };

      expect(
        _canonicalReducerBoundaryViolations(sources),
        containsAll([
          '$fixturePath references forbidden type PersistentGameState',
          '$fixturePath references forbidden type WireSnapshot',
          '$fixturePath references forbidden type LegacyGameSnapshotAdapter',
          '$fixturePath must not reference toLegacy',
        ]),
      );
    });
  });
}

List<String> _canonicalReducerBoundaryViolations(
  Map<String, CompilationUnit> sources,
) {
  final backedTypes = typeNamesBackedBy(
    productionDartSources(),
    _forbiddenReducerBoundaryTypes,
  );
  final violations = <String>[];
  for (final entry in sources.entries) {
    final types = _NamedTypeCollector()..collect(entry.value);
    for (final type in types.names.intersection(backedTypes)) {
      violations.add('${entry.key} references forbidden type $type');
    }
    final references = _IdentifierCollector()..collect(entry.value);
    for (final name in const ['toCanonical', 'toLegacy']) {
      if (references.names.contains(name)) {
        violations.add('${entry.key} must not reference $name');
      }
    }
    if (references.names.contains('DecodedMatchSnapshot')) {
      violations.add(
        '${entry.key} must not declare or reference its old alias',
      );
    }
  }

  final outcome = sources[_serverOutcomePath];
  if (outcome == null) {
    violations.add('server reducer outcome source must exist');
    return violations;
  }
  final reduction = _singleClass(outcome, 'ServerCommandReduction');
  if (reduction == null || reduction.finalKeyword == null) {
    violations.add('ServerCommandReduction must be one final class');
    return violations;
  }
  final fields = _fieldTypes(reduction);
  const expectedFields = {
    'accepted': 'bool',
    'nextSnapshot': 'CanonicalGameSnapshot?',
    'events': 'List<GameEvent>',
    'movementExecutions': 'List<MovementCommandExecution>',
    'outcome': 'GameOutcome?',
    'reason': 'String?',
  };
  if (!_sameMap(fields, expectedFields)) {
    violations.add('ServerCommandReduction fields must be canonical and exact');
  }

  final reducer = sources[_serverReducerPath];
  final application = reducer == null
      ? null
      : _singleClass(reducer, '_CommandApplication');
  if (application == null ||
      _fieldTypes(application)['snapshot'] != 'CanonicalGameSnapshot') {
    violations.add('_CommandApplication must own one canonical snapshot');
  }
  return violations;
}

Map<String, CompilationUnit> _serverReducerSources() {
  return {
    for (final entry in productionDartSources().entries)
      if (entry.key == _serverReducerPath ||
          entry.key.startsWith(
            'server/lib/src/multiplayer/server_command_reducer_',
          ))
        entry.key: parseString(content: entry.value, path: entry.key).unit,
  };
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

Map<String, String> _namedParameterTypes(MethodDeclaration method) {
  return {
    for (final parameter
        in method.parameters?.parameters ?? const <FormalParameter>[])
      if (parameter case DefaultFormalParameter(
        isNamed: true,
        parameter: final SimpleFormalParameter normalized,
      ))
        normalized.name!.lexeme: normalized.type!.toSource(),
  };
}

Map<String, String> _fieldTypes(ClassDeclaration declaration) {
  return {
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      for (final variable in field.fields.variables)
        variable.name.lexeme: field.fields.type?.toSource() ?? '',
  };
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

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  void collect(AstNode node) => node.accept(this);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
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
